import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/icon_map.dart';
import '../../../core/utils/speech_input.dart';
import '../../../core/utils/speech_service.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/shell_scaffold.dart';
import '../data/chat_controller.dart';

/// ekrantasarimları/ai_konu_ma_ses_asistan
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.scenarioId});
  final int? scenarioId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  late final SpeechInput _speechInput;
  bool _recording = false;
  bool _autoSpeak = true;
  bool _showTranslation = false;
  double _rate = 1.0;
  String _partial = '';

  @override
  void initState() {
    super.initState();
    _speechInput = ref.read(speechInputProvider);
    if (widget.scenarioId != null) {
      Future.microtask(() => ref.read(chatControllerProvider.notifier).load(scenarioId: widget.scenarioId));
    }
  }

  @override
  void didUpdateWidget(ChatScreen old) {
    super.didUpdateWidget(old);
    if (widget.scenarioId != null && widget.scenarioId != old.scenarioId) {
      ref.read(chatControllerProvider.notifier).load(scenarioId: widget.scenarioId);
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _speechInput.stop();
    super.dispose();
  }

  Future<void> _send(String text) async {
    _input.clear();
    final reply = await ref.read(chatControllerProvider.notifier).send(text);
    if (reply != null && _autoSpeak) {
      final speech = ref.read(speechServiceProvider)..rate = _rate;
      speech.speak(reply.content, language: 'en-US');
    }
  }

  Future<void> _toggleMic() async {
    final input = ref.read(speechInputProvider);
    if (_recording) {
      await input.stop();
      setState(() => _recording = false);
      if (_partial.isNotEmpty) _send(_partial);
      return;
    }
    await ref.read(speechServiceProvider).stop();
    setState(() {
      _recording = true;
      _partial = '';
    });
    final ok = await input.start(
      localeId: 'en_US',
      onResult: (text, isFinal) {
        if (!mounted) return;
        setState(() => _partial = text);
        if (isFinal) {
          setState(() => _recording = false);
          if (text.isNotEmpty) _send(text);
        }
      },
    );
    if (!ok && mounted) {
      setState(() => _recording = false);
      showMessage(context, 'Bu cihazda konuşma tanıma kullanılamıyor. Yazarak devam edebilirsin.');
    }
  }

  void _menu(ChatState s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.cardLg))),
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Symbols.forum, color: AppColors.primary),
              title: const Text('Sohbet geçmişi'),
              onTap: () {
                Navigator.pop(c);
                _history(s);
              },
            ),
            if (s.scenario != null)
              ListTile(
                leading: const Icon(Symbols.chat, color: AppColors.primary),
                title: const Text('Serbest sohbete geç'),
                onTap: () {
                  Navigator.pop(c);
                  ref.read(chatControllerProvider.notifier).selectScenario(null);
                },
              ),
            ListTile(
              leading: const Icon(Symbols.delete, color: AppColors.error),
              title: const Text('Sohbeti temizle'),
              onTap: () {
                Navigator.pop(c);
                ref.read(chatControllerProvider.notifier).clear();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _history(ChatState s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.cardLg))),
      builder: (_) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.margin),
          children: [
            Text(s.scenario?.title ?? 'Serbest Sohbet', style: AppTextStyles.headlineMd),
            const SizedBox(height: AppSpacing.md),
            for (final m in s.messages)
              Align(
                alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: const BoxConstraints(maxWidth: 300),
                  decoration: BoxDecoration(
                    color: m.isUser ? AppColors.primaryContainer : AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: AppShadows.sm,
                  ),
                  child: Text(m.content, style: AppTextStyles.bodyMd.withColor(m.isUser ? Colors.white : AppColors.onSurface)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(chatControllerProvider);
    ref.listen(chatControllerProvider.select((s) => s.error), (_, err) {
      if (err != null) showMessage(context, err);
    });

    return ListView(
      padding: ShellScaffold.contentPadding(context, vertical: 0),
      children: [
        _StatusBar(
          online: s.aiOnline,
          provider: s.aiProvider,
          autoSpeak: _autoSpeak,
          onSpeaker: () => setState(() => _autoSpeak = !_autoSpeak),
          onMore: () => _menu(s),
        ),
        const SizedBox(height: AppSpacing.md),
        _VoiceStage(
          state: s,
          recording: _recording,
          partial: _partial,
          showTranslation: _showTranslation,
          rate: _rate,
          onMic: _toggleMic,
          onReplay: () {
            final last = s.lastAssistant;
            if (last != null) (ref.read(speechServiceProvider)..rate = _rate).speak(last.content, language: 'en-US');
          },
          onCamera: () => context.go('/translate'),
          onRate: () => setState(() => _rate = _rate == 1.0 ? 1.25 : (_rate == 1.25 ? 0.75 : 1.0)),
          onTranslate: () => setState(() => _showTranslation = !_showTranslation),
        ),
        const SizedBox(height: AppSpacing.md),
        _AnalysisCard(accuracy: s.accuracy, fluency: s.fluency),
        const SizedBox(height: AppSpacing.md),
        _ScenarioChips(
          scenarios: s.scenarios,
          selected: s.scenario,
          onSelect: (sc) => ref.read(chatControllerProvider.notifier).selectScenario(sc),
          onAll: () => _allScenarios(s),
        ),
        const SizedBox(height: AppSpacing.md),
        _InputBar(controller: _input, sending: s.sending, onSend: () => _send(_input.text)),
      ],
    );
  }

  void _allScenarios(ChatState s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.cardLg))),
      builder: (c) => ListView(
        padding: const EdgeInsets.all(AppSpacing.margin),
        children: [
          Text('Konuşma Senaryoları', style: AppTextStyles.headlineMd),
          const SizedBox(height: AppSpacing.sm),
          for (final sc in s.scenarios)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.primaryFixed, shape: BoxShape.circle),
                child: Icon(iconFromName(sc.icon), color: AppColors.primary, size: 20),
              ),
              title: Text(sc.title, style: AppTextStyles.labelLg),
              subtitle: sc.description == null ? null : Text(sc.description!, style: AppTextStyles.bodySm.variant),
              onTap: () {
                Navigator.pop(c);
                ref.read(chatControllerProvider.notifier).selectScenario(sc);
              },
            ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.online, this.provider, required this.autoSpeak, required this.onSpeaker, required this.onMore});
  final bool online;
  final String? provider;
  final bool autoSpeak;
  final VoidCallback onSpeaker;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.soft(),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.primaryFixed, shape: BoxShape.circle),
                child: const Icon(Symbols.smart_toy, size: 20, color: AppColors.primary),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.tertiary,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.tertiaryContainer.withValues(alpha: 0.6), blurRadius: 8)],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text('AI Konuşma Asistanı', style: AppTextStyles.headlineSm, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.secondaryFixed, borderRadius: BorderRadius.circular(6)),
                      child: Text(online ? (provider ?? 'AI') : 'Demo', style: AppTextStyles.labelSm.withColor(AppColors.onSecondaryFixed)),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.tertiary, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text('Çevrim içi • Doğal Telaffuz', style: AppTextStyles.bodySm.variant),
                  ],
                ),
              ],
            ),
          ),
          RoundIconButton(
            icon: autoSpeak ? Symbols.volume_up : Symbols.volume_off,
            iconSize: 18,
            background: AppColors.surfaceContainerLow,
            foreground: AppColors.onSurface,
            shadow: null,
            onPressed: onSpeaker,
            tooltip: autoSpeak ? 'Sesli yanıtı kapat' : 'Sesli yanıtı aç',
          ),
          const SizedBox(width: 4),
          RoundIconButton(
            icon: Symbols.more_vert,
            iconSize: 18,
            background: AppColors.surfaceContainerLow,
            foreground: AppColors.onSurface,
            shadow: null,
            onPressed: onMore,
          ),
        ],
      ),
    );
  }
}

class _VoiceStage extends StatelessWidget {
  const _VoiceStage({
    required this.state,
    required this.recording,
    required this.partial,
    required this.showTranslation,
    required this.rate,
    required this.onMic,
    required this.onReplay,
    required this.onCamera,
    required this.onRate,
    required this.onTranslate,
  });

  final ChatState state;
  final bool recording;
  final String partial;
  final bool showTranslation;
  final double rate;
  final VoidCallback onMic;
  final VoidCallback onReplay;
  final VoidCallback onCamera;
  final VoidCallback onRate;
  final VoidCallback onTranslate;

  @override
  Widget build(BuildContext context) {
    final last = state.lastAssistant;
    final badge = state.sending ? 'DÜŞÜNÜYOR...' : (recording ? 'KONUŞUN' : 'DİNLİYOR...');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.cardLg),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, 0.5, 1],
          colors: [AppColors.primaryFixed.withValues(alpha: 0.4), AppColors.surfaceContainerLowest, AppColors.surfaceContainerLowest],
        ),
        boxShadow: [BoxShadow(color: AppColors.violetShadow(0.08), blurRadius: 36, offset: const Offset(0, 16))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned(top: -64, left: -48, child: GlowBlob(size: 176, color: Color(0x406C5CE7))),
          const Positioned(bottom: -40, right: -40, child: GlowBlob(size: 192, color: Color(0x40A19AFD))),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // Lina AI konuşma balonu
                GestureDetector(
                  onTap: onReplay,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: [BoxShadow(color: AppColors.deepShadow(0.08), blurRadius: 24, offset: const Offset(0, 8))],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Symbols.graphic_eq, size: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('LINA AI', style: AppTextStyles.labelSm.withColor(AppColors.primary).copyWith(letterSpacing: 1)),
                              const SizedBox(height: 2),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: Text(
                                  key: ValueKey(last?.content),
                                  last == null ? '...' : '"${last.content}"',
                                  style: AppTextStyles.bodyMd.copyWith(height: 1.35),
                                ),
                              ),
                              if (showTranslation && last?.translation != null) ...[
                                const SizedBox(height: 4),
                                Text(last!.translation!, style: AppTextStyles.bodySm.withColor(AppColors.primary)),
                              ],
                              if (state.lastUser != null) ...[
                                const SizedBox(height: 6),
                                Text('Sen: ${state.lastUser!.content}',
                                    maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodySm.variant),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg + 16),
                _VoiceOrb(active: recording || state.sending, badge: badge),
                const SizedBox(height: AppSpacing.lg + 8),
                // Bas-konuş butonu
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [BoxShadow(color: AppColors.deepShadow(0.32), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Material(
                    color: recording ? AppColors.tertiary : AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: state.sending ? null : onMic,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(recording ? Symbols.stop : Symbols.mic, size: 20, color: AppColors.tertiaryFixed),
                            const SizedBox(width: 10),
                            Text(recording ? 'Dinleniyor... (Durdur)' : 'Konuşmak için Dokun',
                                style: AppTextStyles.labelLg.withColor(Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  recording && partial.isNotEmpty ? partial : 'İngilizce veya Türkçe konuşabilirsiniz',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySm.variant,
                ),
                const SizedBox(height: 20),
                Divider(color: AppColors.surfaceContainerHigh.withValues(alpha: 0.4), height: 1),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _ToolChip(icon: Symbols.photo_camera, iconColor: AppColors.primary, label: 'Görsel\nÇevir', onTap: onCamera),
                    _ToolChip(icon: Symbols.instant_mix, iconColor: AppColors.secondary, label: 'Hız:\n${rate.toStringAsFixed(rate == 1.25 ? 2 : 1)}x', onTap: onRate),
                    _ToolChip(
                      icon: Symbols.translate,
                      iconColor: AppColors.tertiary,
                      label: 'Anında\nÇeviri',
                      onTap: onTranslate,
                      active: showTranslation,
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

/// Merkezdeki animasyonlu ses küresi: dışa yayılan halkalar + dalga çizgisi.
class _VoiceOrb extends StatefulWidget {
  const _VoiceOrb({required this.active, required this.badge});
  final bool active;
  final String badge;

  @override
  State<_VoiceOrb> createState() => _VoiceOrbState();
}

class _VoiceOrbState extends State<_VoiceOrb> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 224,
      height: 224,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final t = _c.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              // animate-ping halkası
              Opacity(
                opacity: 0.25 * (1 - t),
                child: Container(
                  width: 176 + 48 * t,
                  height: 176 + 48 * t,
                  decoration: BoxDecoration(color: AppColors.primaryFixed.withValues(alpha: 0.8), shape: BoxShape.circle),
                ),
              ),
              // animate-pulse halkası
              Container(
                width: 176,
                height: 176,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.10 + 0.08 * sin(t * pi)),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 128,
                height: 128,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [AppColors.primary, AppColors.primaryContainer, AppColors.secondaryContainer],
                  ),
                  boxShadow: [BoxShadow(color: AppColors.violetShadow(0.35), blurRadius: 32, offset: const Offset(0, 12))],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryContainer.withValues(alpha: 0.9), AppColors.primary, AppColors.secondary],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomPaint(size: const Size(96, 40), painter: _WavePainter(phase: t, active: widget.active)),
                      const SizedBox(height: 4),
                      Text(widget.badge,
                          style: AppTextStyles.labelSm.withColor(AppColors.onPrimaryContainer).copyWith(letterSpacing: 1.2)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.phase, required this.active});
  final double phase;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    void wave(double amp, double width, double alpha, double shift) {
      final p = Path();
      for (var x = 0.0; x <= size.width; x += 1) {
        final y = size.height / 2 + amp * sin((x / size.width) * 4 * pi + (phase * 2 * pi) + shift);
        x == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
      }
      canvas.drawPath(
        p,
        Paint()
          ..color = Colors.white.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    wave(active ? 14 : 8, active ? 4 : 2.5, 0.7, 0);
    wave(4, 1.5, 0.3, pi / 2);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.phase != phase || old.active != active;
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({required this.icon, required this.iconColor, required this.label, required this.onTap, this.active = false});
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.primaryFixed : AppColors.surfaceContainer,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Text(label, textAlign: TextAlign.center, style: AppTextStyles.labelSm.variant.copyWith(fontWeight: FontWeight.w600, height: 1.25)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({required this.accuracy, required this.fluency});
  final int? accuracy;
  final String? fluency;

  @override
  Widget build(BuildContext context) {
    final praise = accuracy == null
        ? 'Hazır'
        : accuracy! >= 85
            ? 'Harika Gidiyorsun'
            : accuracy! >= 60
                ? 'İyi Gidiyorsun'
                : 'Devam Et';
    return AppCard(
      radius: AppRadius.md,
      shadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 16, offset: Offset(0, 4))],
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Symbols.verified, size: 20, color: AppColors.tertiary),
              const SizedBox(width: 8),
              Text('Canlı Analiz', style: AppTextStyles.headlineSm),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(praise, style: AppTextStyles.labelMd.bold.withColor(AppColors.tertiary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            spacing: AppSpacing.sm,
            children: [
              _Metric(label: 'Doğruluk', value: accuracy == null ? '—' : '%$accuracy', icon: Symbols.target, iconColor: AppColors.tertiary),
              _Metric(
                label: 'Akıcılık',
                value: fluency ?? '—',
                icon: Symbols.speed,
                iconColor: AppColors.primary,
                valueColor: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon, required this.iconColor, this.valueColor});
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm + 4),
        decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(999)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.bodySm.variant),
                  Text(value, style: AppTextStyles.headlineMd.bold.withColor(valueColor ?? AppColors.onSurface)),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: AppColors.surfaceContainerLowest, shape: BoxShape.circle, boxShadow: AppShadows.sm),
              child: Icon(icon, size: 20, color: iconColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScenarioChips extends StatelessWidget {
  const _ScenarioChips({required this.scenarios, required this.selected, required this.onSelect, required this.onAll});
  final List<Scenario> scenarios;
  final Scenario? selected;
  final ValueChanged<Scenario> onSelect;
  final VoidCallback onAll;

  static const _colors = [AppColors.primary, AppColors.tertiary, AppColors.secondary, AppColors.onSurfaceVariant];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SectionHeader(
            title: 'Önerilen Konuşma Kalıpları',
            style: AppTextStyles.labelMd.variant,
            action: 'Tümünü Gör',
            onAction: onAll,
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: scenarios.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final sc = scenarios[i];
              final active = selected?.id == sc.id;
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
                ),
                child: Material(
                  color: active ? AppColors.primaryFixed : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => onSelect(sc),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        children: [
                          Icon(iconFromName(sc.icon), size: 16, color: _colors[i % _colors.length]),
                          const SizedBox(width: 6),
                          Text(sc.title, style: AppTextStyles.labelMd),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InputBar extends ConsumerWidget {
  const _InputBar({required this.controller, required this.sending, required this.onSend});
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [BoxShadow(color: AppColors.violetShadow(0.09), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 14, right: 8),
            child: Icon(Symbols.keyboard, size: 20, color: AppColors.onSurfaceVariant),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (_) => onSend(),
              textInputAction: TextInputAction.send,
              style: AppTextStyles.bodyMd,
              decoration: InputDecoration(
                hintText: 'Bana bir şey sor veya konuş...',
                fillColor: Colors.transparent,
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.deepShadow(0.25), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: sending ? null : onSend,
                child: sending
                    ? const Padding(padding: EdgeInsets.all(11), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Symbols.send, size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
