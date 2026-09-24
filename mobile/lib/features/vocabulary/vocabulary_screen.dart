import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/speech_service.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/common.dart';

class VocabWord {
  VocabWord({
    required this.id,
    required this.word,
    required this.translation,
    this.example,
    this.exampleTranslation,
    this.audioUrl,
    required this.strength,
    required this.isFavorite,
  });

  final int id;
  final String word;
  final String translation;
  final String? example;
  final String? exampleTranslation;
  final String? audioUrl;
  final int strength;
  final bool isFavorite;

  factory VocabWord.fromJson(Map<String, dynamic> j) => VocabWord(
        id: j['id'] as int,
        word: j['word'] as String,
        translation: j['translation'] as String,
        example: j['example_sentence'] as String?,
        exampleTranslation: j['example_translation'] as String?,
        audioUrl: j['audio_url'] as String?,
        strength: j['strength'] as int,
        isFavorite: j['is_favorite'] as bool,
      );
}

final vocabularyProvider = FutureProvider.autoDispose.family<List<VocabWord>, String>((ref, filter) async {
  final d = await ref.watch(apiClientProvider).get<List<dynamic>>('/words', query: {'filter': filter});
  return d.map((w) => VocabWord.fromJson(w as Map<String, dynamic>)).toList();
});

/// Kelime defteri: öğrenilenler, favoriler ve tekrar zamanı gelenler; tekrar kartı modu.
class VocabularyScreen extends ConsumerStatefulWidget {
  const VocabularyScreen({super.key});

  @override
  ConsumerState<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends ConsumerState<VocabularyScreen> {
  String _filter = 'learned';

  static const _filters = {'learned': 'Öğrendiklerim', 'review': 'Tekrar Zamanı', 'favorite': 'Favoriler'};

  Future<void> _favorite(VocabWord w) async {
    try {
      await ref.read(apiClientProvider).post('/words/${w.id}/favorite');
      ref.invalidate(vocabularyProvider);
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = ref.watch(vocabularyProvider(_filter));
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const StackHeader(title: 'Kelime Defteri'),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.margin,
          MediaQuery.paddingOf(context).top + 64 + AppSpacing.md,
          AppSpacing.margin,
          MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
        ),
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final e in _filters.entries)
                ChoiceChip(
                  label: Text(e.value),
                  selected: _filter == e.key,
                  onSelected: (_) => setState(() => _filter = e.key),
                  showCheckmark: false,
                  labelStyle: AppTextStyles.labelMd.withColor(_filter == e.key ? Colors.white : AppColors.onSurface),
                  selectedColor: AppColors.primaryContainer,
                  backgroundColor: AppColors.surfaceContainerLowest,
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          words.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator(color: AppColors.primaryContainer)),
            ),
            error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(vocabularyProvider)),
            data: (list) => list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(48),
                    child: Text(
                      _filter == 'review' ? 'Şu an tekrar edilecek kelime yok. Harika!' : 'Ders tamamladıkça kelimeler burada birikir.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd.variant,
                    ),
                  )
                : Column(
                    spacing: AppSpacing.sm,
                    children: [
                      if (_filter == 'review')
                        PrimaryButton(
                          label: 'Tekrara Başla (${list.length})',
                          icon: Symbols.style,
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => _ReviewSession(words: list),
                          )),
                        ),
                      for (final w in list) _WordTile(word: w, onFavorite: () => _favorite(w)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _WordTile extends ConsumerWidget {
  const _WordTile({required this.word, required this.onFavorite});
  final VocabWord word;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      radius: AppRadius.card,
      child: Row(
        children: [
          RoundIconButton(
            icon: Symbols.volume_up,
            background: AppColors.primaryFixed,
            foreground: AppColors.primary,
            shadow: null,
            size: 40,
            onPressed: () => ref.read(speechServiceProvider).speak(word.word, audioUrl: word.audioUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(word.word, style: AppTextStyles.headlineSm),
                Text(word.translation, style: AppTextStyles.bodyMd.withColor(AppColors.primary)),
                if (word.example != null) Text(word.example!, style: AppTextStyles.bodySm.variant),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (var i = 0; i < 5; i++)
                      Container(
                        width: 18,
                        height: 4,
                        margin: const EdgeInsets.only(right: 3),
                        decoration: BoxDecoration(
                          color: i < word.strength ? AppColors.tertiaryFixedDim : AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onFavorite,
            icon: Icon(Symbols.favorite, fill: word.isFavorite ? 1 : 0, color: word.isFavorite ? AppColors.primary : AppColors.outline),
          ),
        ],
      ),
    );
  }
}

/// Kart çevirmeli tekrar: kelimeyi gör, anlamı çevir, bildin/bilmedin.
class _ReviewSession extends ConsumerStatefulWidget {
  const _ReviewSession({required this.words});
  final List<VocabWord> words;

  @override
  ConsumerState<_ReviewSession> createState() => _ReviewSessionState();
}

class _ReviewSessionState extends ConsumerState<_ReviewSession> {
  int _i = 0;
  bool _flipped = false;
  int _known = 0;

  Future<void> _answer(bool correct) async {
    final w = widget.words[_i];
    if (correct) _known++;
    ref.read(apiClientProvider).post('/words/${w.id}/review', data: {'correct': correct});
    if (_i == widget.words.length - 1) {
      ref.invalidate(vocabularyProvider);
      if (mounted) {
        showMessage(context, '${widget.words.length} kelimeden $_known tanesini bildin!');
        Navigator.pop(context);
      }
      return;
    }
    setState(() {
      _i++;
      _flipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.words[_i];
    return Scaffold(
      appBar: StackHeader(title: 'Tekrar ${_i + 1}/${widget.words.length}', onBack: () => Navigator.pop(context)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.margin),
          child: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _flipped = !_flipped);
                    if (!_flipped) return;
                    ref.read(speechServiceProvider).speak(w.word, audioUrl: w.audioUrl);
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                    child: Container(
                      key: ValueKey('$_i-$_flipped'),
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: _flipped ? AppColors.primaryContainer : AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: AppShadows.strong(0.14),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _flipped ? w.translation : w.word,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.displayLg.withColor(_flipped ? Colors.white : AppColors.onSurface),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            _flipped ? (w.exampleTranslation ?? '') : (w.example ?? 'Anlamını görmek için dokun'),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyLg.withColor(_flipped ? Colors.white70 : AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                spacing: AppSpacing.sm,
                children: [
                  Expanded(
                    child: PrimaryButton(label: 'Bilmedim', color: AppColors.error, onPressed: () => _answer(false)),
                  ),
                  Expanded(
                    child: PrimaryButton(label: 'Bildim', color: AppColors.tertiaryContainer, onPressed: () => _answer(true)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
