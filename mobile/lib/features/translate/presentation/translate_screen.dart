import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/speech_input.dart';
import '../../../core/utils/speech_service.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/shell_scaffold.dart';
import '../data/translate_data.dart';

/// ekrantasarimları/anl_k_eviri_kelime_haznesi
class TranslateScreen extends ConsumerStatefulWidget {
  const TranslateScreen({super.key});

  @override
  ConsumerState<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends ConsumerState<TranslateScreen> {
  final _source = TextEditingController();
  final _sourceFocus = FocusNode();
  String _from = 'en';
  String _to = 'tr';
  bool _swapTurn = false;
  bool _loading = false;
  bool _copied = false;
  bool _detected = false;
  Translation? _result;
  String? _error;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _source.dispose();
    _sourceFocus.dispose();
    super.dispose();
  }

  Future<void> _translate() async {
    final text = _source.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await ref.read(translateRepositoryProvider).translate(text, _from, _to);
      if (mounted) setState(() => _result = r);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onChanged(String v) {
    // Türkçe karakter varsa kaynak dili Türkçe olarak algıla.
    final looksTurkish = guessLanguage(v) == 'tr-TR';
    if (looksTurkish && _from != 'tr') {
      setState(() {
        _from = 'tr';
        _to = 'en';
        _detected = true;
      });
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), _translate);
  }

  void _swap() {
    setState(() {
      _swapTurn = !_swapTurn;
      final previousFrom = _from;
      _from = _to;
      _to = previousFrom;
      _detected = false;
      if (_result != null) {
        _source.text = _result!.translatedText;
        _result = null;
      }
    });
    _translate();
  }

  void _usePhrase(Phrase p) {
    setState(() {
      _from = 'en';
      _to = 'tr';
      _source.text = p.text;
    });
    _translate();
  }

  void _clear() {
    setState(() {
      _source.clear();
      _result = null;
      _error = null;
    });
  }

  Future<void> _toggleFavorite() async {
    if (_result == null) return;
    try {
      final r = await ref.read(translateRepositoryProvider).toggleFavorite(_result!.id);
      setState(() => _result = Translation(
            id: r.id,
            sourceLang: r.sourceLang,
            targetLang: r.targetLang,
            sourceText: r.sourceText,
            translatedText: r.translatedText,
            pronunciation: r.pronunciation,
            isFavorite: r.isFavorite,
            confidence: _result!.confidence,
          ));
      ref.invalidate(translationHistoryProvider);
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message);
    }
  }

  Future<void> _dictate() async {
    final text = await ref.read(speechInputProvider).listenOnce(context, localeId: _from == 'tr' ? 'tr_TR' : 'en_US');
    if (text != null && text.isNotEmpty) {
      _source.text = text;
      _translate();
    }
  }

  String _tts(String code) => code == 'tr' ? 'tr-TR' : code == 'de' ? 'de-DE' : 'en-US';

  @override
  Widget build(BuildContext context) {
    final home = ref.watch(translateHomeProvider);
    return AsyncBody(
      value: home,
      onRetry: () => ref.invalidate(translateHomeProvider),
      data: (h) => ListView(
        padding: ShellScaffold.contentPadding(context, vertical: AppSpacing.xs),
        children: [
          _Heading(aiOnline: h.aiOnline, onHistory: () => _showHistory(context, favorites: false)),
          const SizedBox(height: AppSpacing.md),
          _LanguageBar(
            from: h.languages[_from],
            to: h.languages[_to],
            detected: _detected,
            turned: _swapTurn,
            onSwap: _swap,
          ),
          const SizedBox(height: AppSpacing.md),
          _ShortcutGrid(
            onVoice: _dictate,
            onCamera: () => showMessage(context, 'Görsel çevirmen yakında! Şimdilik metni yazabilirsin.'),
            onText: () => _sourceFocus.requestFocus(),
            onFavorites: () => _showHistory(context, favorites: true),
          ),
          const SizedBox(height: AppSpacing.md),
          _TranslationCard(
            source: _source,
            focus: _sourceFocus,
            targetName: h.languages[_to]?.name ?? '',
            result: _result,
            loading: _loading,
            error: _error,
            copied: _copied,
            onChanged: _onChanged,
            onClear: _clear,
            onSpeakSource: () => ref.read(speechServiceProvider).speak(_source.text, language: _tts(_from)),
            onCopySource: () async {
              await Clipboard.setData(ClipboardData(text: _source.text));
              setState(() => _copied = true);
              Future.delayed(const Duration(milliseconds: 1500), () => mounted ? setState(() => _copied = false) : null);
            },
            onFavorite: _toggleFavorite,
            onShare: () async {
              if (_result == null) return;
              await Clipboard.setData(ClipboardData(text: '${_result!.sourceText}\n${_result!.translatedText}'));
              if (context.mounted) showMessage(context, 'Çeviri panoya kopyalandı');
            },
            onSpeakTarget: () =>
                _result == null ? null : ref.read(speechServiceProvider).speak(_result!.translatedText, language: _tts(_to)),
          ),
          const SizedBox(height: AppSpacing.md),
          SectionHeader(
            title: 'Hızlı Kalıplar',
            action: 'Tümü',
            onAction: () => _showPhrases(context, h.phrases),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: h.phrases.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
              itemBuilder: (_, i) => _PhraseChip(phrase: h.phrases[i], onTap: () => _usePhrase(h.phrases[i])),
            ),
          ),
          if (h.idiom != null) ...[
            const SizedBox(height: AppSpacing.md),
            _IdiomCard(idiom: h.idiom!, onTap: () => _usePhrase(h.idiom!)),
          ],
        ],
      ),
    );
  }

  void _showPhrases(BuildContext context, List<Phrase> phrases) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.cardLg))),
      builder: (c) => ListView(
        padding: const EdgeInsets.all(AppSpacing.margin),
        children: [
          Text('Hızlı Kalıplar', style: AppTextStyles.headlineMd),
          const SizedBox(height: AppSpacing.sm),
          for (final p in phrases)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(p.emoji ?? '💬', style: const TextStyle(fontSize: 24)),
              title: Text(p.text, style: AppTextStyles.labelLg),
              subtitle: Text(p.translation, style: AppTextStyles.bodySm.variant),
              onTap: () {
                Navigator.pop(c);
                _usePhrase(p);
              },
            ),
        ],
      ),
    );
  }

  void _showHistory(BuildContext context, {required bool favorites}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.cardLg))),
      builder: (c) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Consumer(builder: (context, ref, _) {
          final list = ref.watch(translationHistoryProvider(favorites));
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.margin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(favorites ? 'Favori Kalıplar' : 'Çeviri Geçmişi', style: AppTextStyles.headlineMd),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: AsyncBody(
                    value: list,
                    onRetry: () => ref.invalidate(translationHistoryProvider(favorites)),
                    data: (items) => items.isEmpty
                        ? Center(
                            child: Text(
                              favorites ? 'Henüz favori kalıbın yok.\nÇeviride yer imine dokun.' : 'Henüz çeviri yapmadın.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMd.variant,
                            ),
                          )
                        : ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (_, i) {
                              final t = items[i];
                              return AppCard(
                                radius: AppRadius.md,
                                onTap: () {
                                  Navigator.pop(c);
                                  setState(() {
                                    _from = t.sourceLang;
                                    _to = t.targetLang;
                                    _source.text = t.sourceText;
                                    _result = t;
                                  });
                                },
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(t.sourceText, style: AppTextStyles.labelLg),
                                          Text(t.translatedText, style: AppTextStyles.bodyMd.withColor(AppColors.primary)),
                                        ],
                                      ),
                                    ),
                                    if (t.isFavorite) const Icon(Symbols.bookmark, fill: 1, color: AppColors.primary, size: 20),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.aiOnline, required this.onHistory});
  final bool aiOnline;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.xs,
      children: [
        Row(
          children: [
            const Pill(text: 'Akıllı Çeviri', padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
            const SizedBox(width: AppSpacing.xs),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: aiOnline ? AppColors.tertiary : AppColors.outline, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(aiOnline ? 'AI Çevrimiçi' : 'Sözlük Modu', style: AppTextStyles.labelSm.variant),
            const Spacer(),
            InkWell(
              onTap: onHistory,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  const Icon(Symbols.history, size: 20, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('Geçmiş', style: AppTextStyles.labelMd.variant),
                ],
              ),
            ),
          ],
        ),
        Text('Neyi çevirmek istersiniz?', style: AppTextStyles.headlineLg),
      ],
    );
  }
}

class _LanguageBar extends StatelessWidget {
  const _LanguageBar({required this.from, required this.to, required this.detected, required this.turned, required this.onSwap});
  final ({String name, String flag})? from;
  final ({String name, String flag})? to;
  final bool detected;
  final bool turned;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    Widget side(({String name, String flag})? lang, String sub, Color subColor, {required bool end}) {
      final flag = Text(lang?.flag ?? '🌐', style: const TextStyle(fontSize: 16));
      final texts = Flexible(
        child: Column(
          crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(lang?.name ?? '', style: AppTextStyles.labelMd, overflow: TextOverflow.ellipsis),
            Text(sub, style: AppTextStyles.labelSm.withColor(subColor)),
          ],
        ),
      );
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: end ? MainAxisAlignment.end : MainAxisAlignment.start,
            spacing: AppSpacing.xs,
            children: end ? [texts, flag] : [flag, texts],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [BoxShadow(color: AppColors.violetShadow(0.06), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          side(from, detected ? 'Algılandı' : 'Kaynak Dil', detected ? AppColors.primary : AppColors.onSurfaceVariant, end: false),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: AnimatedRotation(
              turns: turned ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: RoundIconButton(
                icon: Symbols.sync_alt,
                onPressed: onSwap,
                size: 40,
                iconSize: 20,
                background: AppColors.primaryFixed,
                foreground: AppColors.onPrimaryFixed,
                tooltip: 'Dilleri değiştir',
              ),
            ),
          ),
          side(to, 'Hedef Dil', AppColors.onSurfaceVariant, end: true),
        ],
      ),
    );
  }
}

class _ShortcutGrid extends StatelessWidget {
  const _ShortcutGrid({required this.onVoice, required this.onCamera, required this.onText, required this.onFavorites});
  final VoidCallback onVoice;
  final VoidCallback onCamera;
  final VoidCallback onText;
  final VoidCallback onFavorites;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: AppSpacing.sm,
      children: [
        Row(
          spacing: AppSpacing.sm,
          children: [
            _Tile(
              icon: Symbols.mic,
              kicker: 'ANLIK KONUŞMA',
              title: 'Sesli Çevirmen',
              bg: AppColors.tertiaryContainer,
              fg: AppColors.onTertiaryContainer,
              iconBg: AppColors.onTertiaryContainer.withValues(alpha: 0.15),
              shadow: AppColors.tertiaryContainer.withValues(alpha: 0.12),
              radius: const BorderRadius.only(topLeft: Radius.circular(36), topRight: Radius.circular(24), bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
              onTap: onVoice,
            ),
            _Tile(
              icon: Symbols.photo_camera,
              kicker: 'KAMERA & OCR',
              title: 'Görsel Çevirmen',
              bg: AppColors.primaryContainer,
              fg: AppColors.onPrimaryContainer,
              iconBg: AppColors.onPrimaryContainer.withValues(alpha: 0.15),
              shadow: AppColors.violetShadow(0.18),
              radius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(36), bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
              onTap: onCamera,
            ),
          ],
        ),
        Row(
          spacing: AppSpacing.sm,
          children: [
            _Tile(
              icon: Symbols.menu_book,
              kicker: 'DETAYLI SÖZLÜK',
              title: 'Metin Çevirisi',
              bg: AppColors.surfaceContainerHigh,
              fg: AppColors.onSurface,
              kickerColor: AppColors.onSurfaceVariant,
              iconBg: AppColors.primaryFixed,
              iconColor: AppColors.primary,
              shadow: const Color(0x0A000000),
              radius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24), bottomLeft: Radius.circular(36), bottomRight: Radius.circular(24)),
              onTap: onText,
            ),
            _Tile(
              icon: Symbols.favorite,
              iconFill: 1,
              kicker: 'KAYDEDİLENLER',
              title: 'Favori Kalıplar',
              bg: AppColors.secondaryFixed,
              fg: AppColors.onSecondaryFixed,
              iconBg: AppColors.onSecondaryFixed.withValues(alpha: 0.1),
              iconColor: AppColors.primary,
              shadow: AppColors.secondary.withValues(alpha: 0.10),
              radius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24), bottomLeft: Radius.circular(24), bottomRight: Radius.circular(36)),
              onTap: onFavorites,
            ),
          ],
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.kicker,
    required this.title,
    required this.bg,
    required this.fg,
    required this.iconBg,
    required this.shadow,
    required this.radius,
    required this.onTap,
    this.iconColor,
    this.kickerColor,
    this.iconFill = 0,
  });

  final IconData icon;
  final String kicker;
  final String title;
  final Color bg;
  final Color fg;
  final Color iconBg;
  final Color? iconColor;
  final Color? kickerColor;
  final Color shadow;
  final BorderRadius radius;
  final VoidCallback onTap;
  final double iconFill;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 128,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [BoxShadow(color: shadow, blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Material(
          color: bg,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                        child: Icon(icon, size: 22, color: iconColor ?? fg, fill: iconFill),
                      ),
                      const Spacer(),
                      Icon(Symbols.north_east, size: 18, color: (kickerColor ?? fg).withValues(alpha: 0.7)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(kicker,
                          style: AppTextStyles.labelSm.withColor(kickerColor ?? fg.withValues(alpha: 0.8)).copyWith(letterSpacing: 1)),
                      Text(title, style: AppTextStyles.headlineSm.withColor(fg).copyWith(height: 1.2), maxLines: 2),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TranslationCard extends StatelessWidget {
  const _TranslationCard({
    required this.source,
    required this.focus,
    required this.targetName,
    required this.result,
    required this.loading,
    required this.error,
    required this.copied,
    required this.onChanged,
    required this.onClear,
    required this.onSpeakSource,
    required this.onCopySource,
    required this.onFavorite,
    required this.onShare,
    required this.onSpeakTarget,
  });

  final TextEditingController source;
  final FocusNode focus;
  final String targetName;
  final Translation? result;
  final bool loading;
  final String? error;
  final bool copied;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onSpeakSource;
  final VoidCallback onCopySource;
  final VoidCallback onFavorite;
  final VoidCallback onShare;
  final VoidCallback onSpeakTarget;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.cardLg),
        boxShadow: [BoxShadow(color: AppColors.violetShadow(0.08), blurRadius: 32, offset: const Offset(0, 12))],
      ),
      child: Column(
        children: [
          // Kaynak metin
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text('KAYNAK METİN', style: AppTextStyles.labelSm.variant.copyWith(letterSpacing: 1)),
                    const Spacer(),
                    GestureDetector(onTap: onClear, child: Text('Temizle', style: AppTextStyles.labelSm.withColor(AppColors.primary).copyWith(fontWeight: FontWeight.w500))),
                  ],
                ),
                TextField(
                  controller: source,
                  focusNode: focus,
                  onChanged: onChanged,
                  minLines: 1,
                  maxLines: 5,
                  style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    hintText: 'Metni buraya yaz...',
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 6),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: AppSpacing.xs,
                  children: [
                    RoundIconButton(icon: Symbols.volume_up, onPressed: onSpeakSource, tooltip: 'Metni Dinle'),
                    RoundIconButton(
                      icon: copied ? Symbols.done : Symbols.content_copy,
                      foreground: copied ? AppColors.tertiary : AppColors.onSurfaceVariant,
                      onPressed: onCopySource,
                      tooltip: 'Metni Kopyala',
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Ayraç rozeti
          Transform.translate(
            offset: const Offset(0, 0),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primaryFixed, borderRadius: BorderRadius.circular(999), boxShadow: AppShadows.sm),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Symbols.auto_awesome, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(result?.confidence != null && result!.confidence! >= 99 ? 'Sözlük Çevirisi' : 'Yapay Zekâ Çevirisi',
                        style: AppTextStyles.labelSm.withColor(AppColors.primary).copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
          // Hedef metin
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primaryFixed.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('${targetName.toUpperCase()} KARŞILIĞI',
                          style: AppTextStyles.labelSm.withColor(AppColors.primary).copyWith(letterSpacing: 1)),
                    ),
                    if (result?.confidence != null) ...[
                      const Icon(Symbols.check_circle, size: 14, color: AppColors.tertiary),
                      const SizedBox(width: 4),
                      Text('%${result!.confidence} Doğruluk', style: AppTextStyles.labelSm.withColor(AppColors.tertiary)),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: loading
                      ? const Padding(
                          key: ValueKey('l'),
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: LinearProgressIndicator(minHeight: 3, color: AppColors.primaryContainer, backgroundColor: AppColors.primaryFixed),
                        )
                      : Text(
                          key: ValueKey(result?.id ?? error),
                          error ?? result?.translatedText ?? 'Çeviri burada görünecek',
                          style: error != null
                              ? AppTextStyles.bodyMd.withColor(AppColors.error)
                              : result == null
                                  ? AppTextStyles.headlineSm.withColor(AppColors.onSurfaceVariant.withValues(alpha: 0.5))
                                  : AppTextStyles.headlineSm.copyWith(height: 1.3),
                        ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Text(result?.pronunciation ?? '',
                          style: AppTextStyles.bodySm.variant.copyWith(fontStyle: FontStyle.italic)),
                    ),
                    RoundIconButton(
                      icon: (result?.isFavorite ?? false) ? Symbols.bookmark : Symbols.bookmark,
                      fill: (result?.isFavorite ?? false) ? 1 : 0,
                      foreground: (result?.isFavorite ?? false) ? AppColors.primary : AppColors.onSurfaceVariant,
                      onPressed: result == null ? null : onFavorite,
                      tooltip: 'Favorilere Ekle',
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    RoundIconButton(icon: Symbols.share, onPressed: result == null ? null : onShare, tooltip: 'Paylaş'),
                    const SizedBox(width: AppSpacing.xs),
                    RoundIconButton(
                      icon: Symbols.volume_up,
                      background: AppColors.primary,
                      foreground: AppColors.onPrimary,
                      shadow: [BoxShadow(color: AppColors.deepShadow(0.25), blurRadius: 12, offset: const Offset(0, 4))],
                      onPressed: onSpeakTarget,
                      tooltip: 'Telaffuz Dinle',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhraseChip extends StatelessWidget {
  const _PhraseChip({required this.phrase, required this.onTap});
  final Phrase phrase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), boxShadow: AppShadows.sm),
      child: Material(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(phrase.emoji ?? '💬', style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(phrase.translation, style: AppTextStyles.labelMd),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IdiomCard extends StatelessWidget {
  const _IdiomCard({required this.idiom, required this.onTap});
  final Phrase idiom;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: AppColors.secondaryFixed, borderRadius: BorderRadius.circular(AppRadius.md)),
            clipBehavior: Clip.antiAlias,
            child: idiom.imageUrl != null
                ? Image.network(idiom.imageUrl!, fit: BoxFit.cover)
                : const Icon(Symbols.coffee, size: 32, color: AppColors.primary, fill: 1),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Symbols.lightbulb, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text('Günün Deyimi', style: AppTextStyles.labelSm.withColor(AppColors.primary)),
                  ],
                ),
                Text('"${idiom.text}"', style: AppTextStyles.labelLg.bold, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('Türkçe karşılığı: "${idiom.translation}"',
                    style: AppTextStyles.bodySm.variant, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          RoundIconButton(icon: Symbols.chevron_right, size: 32, iconSize: 18, onPressed: onTap),
        ],
      ),
    );
  }
}
