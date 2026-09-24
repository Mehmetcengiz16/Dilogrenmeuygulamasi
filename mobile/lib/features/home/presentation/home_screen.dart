import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/icon_map.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/shell_scaffold.dart';
import '../data/home_data.dart';

/// ekrantasarimları/ana_sayfa_ke_fet
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeProvider);
    return AsyncBody(
      value: home,
      onRetry: () => ref.invalidate(homeProvider),
      data: (d) => RefreshIndicator(
        color: AppColors.primaryContainer,
        edgeOffset: ShellScaffold.topInset(context),
        onRefresh: () => ref.refresh(homeProvider.future),
        child: ListView(
          padding: ShellScaffold.contentPadding(context, vertical: AppSpacing.md),
          children: [
            _Welcome(data: d),
            const SizedBox(height: AppSpacing.lg),
            _Metrics(data: d),
            const SizedBox(height: AppSpacing.lg),
            _StreakCard(data: d),
            if (d.currentLesson != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _FeaturedLessonCard(lesson: d.currentLesson!),
            ],
            if (d.scenario != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _PracticeCard(scenario: d.scenario!),
            ],
            const SizedBox(height: AppSpacing.lg),
            _QuickModules(data: d),
            if (d.tip != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _TipBanner(tip: d.tip!),
            ],
          ],
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.data});
  final HomeData data;

  @override
  Widget build(BuildContext context) {
    final remaining = data.remainingMinutes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primaryFixed, borderRadius: BorderRadius.circular(999)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _PulsingDot(),
                  const SizedBox(width: 4),
                  Text(data.goalPercent >= 100 ? 'Hedef Tamam' : 'Devam Ediyor',
                      style: AppTextStyles.labelSm.withColor(AppColors.onPrimaryFixed)),
                ],
              ),
            ),
            const Spacer(),
            if (data.level != null) ...[
              const Icon(Symbols.verified, size: 16, color: AppColors.tertiary),
              const SizedBox(width: 4),
              Text('${data.level} Seviyesi', style: AppTextStyles.labelMd.variant),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xs + 4),
        Text('Yapay Zekâ ile ${data.targetLanguage ?? 'Dil'} Öğren', style: AppTextStyles.headlineLg),
        const SizedBox(height: AppSpacing.xs),
        Text(
          remaining > 0
              ? 'Bugünkü hedefine ulaşmak için $remaining dakikalık pratik kaldı.'
              : 'Bugünkü hedefini tamamladın, harikasın!',
          style: AppTextStyles.bodyMd.variant,
        ),
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(_c),
      child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.data});
  final HomeData data;

  @override
  Widget build(BuildContext context) {
    final change = data.hoursChangePercent;
    final hours = data.totalHours == data.totalHours.roundToDouble()
        ? data.totalHours.toStringAsFixed(0)
        : data.totalHours.toStringAsFixed(1);
    return Row(
      spacing: AppSpacing.md,
      children: [
        Expanded(
          child: _MetricCard(
            icon: Symbols.schedule,
            iconColor: AppColors.primary,
            badge: change == null ? null : '${change >= 0 ? '+' : ''}$change%',
            badgeBg: change != null && change < 0 ? AppColors.errorContainer : AppColors.tertiaryFixed,
            badgeFg: change != null && change < 0 ? AppColors.onErrorContainer : AppColors.onTertiaryFixed,
            value: '$hours Saat',
            label: 'Tamamlanan Ders',
            blob: AppColors.primaryFixed,
          ),
        ),
        Expanded(
          child: _MetricCard(
            icon: Symbols.checklist,
            iconColor: AppColors.secondary,
            badge: '${data.courseCompleted}/${data.courseTotal}',
            badgeBg: AppColors.secondaryFixed,
            badgeFg: AppColors.onSecondaryFixed,
            value: '${data.courseCompleted} Ders',
            label: 'Tamamlanan Görev',
            blob: AppColors.secondaryFixed,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.badge,
    required this.badgeBg,
    required this.badgeFg,
    required this.value,
    required this.label,
    required this.blob,
  });

  final IconData icon;
  final Color iconColor;
  final String? badge;
  final Color badgeBg;
  final Color badgeFg;
  final String value;
  final String label;
  final Color blob;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -16,
            bottom: -16,
            child: Container(width: 64, height: 64, decoration: BoxDecoration(color: blob.withValues(alpha: 0.2), shape: BoxShape.circle)),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(color: AppColors.surfaceContainerLow, shape: BoxShape.circle),
                      child: Icon(icon, size: 20, color: iconColor),
                    ),
                    const Spacer(),
                    if (badge != null)
                      Pill(text: badge!, background: badgeBg, foreground: badgeFg, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: AppTextStyles.headlineMd.bold.copyWith(letterSpacing: -0.3)),
                ),
                const SizedBox(height: 2),
                Text(label, style: AppTextStyles.bodySm.variant),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.data});
  final HomeData data;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      shadow: AppShadows.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.sm,
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 20)),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.streak > 0 ? '${data.streak} Günlük Seri!' : 'Seriyi Başlat!', style: AppTextStyles.headlineSm),
                    Text(
                      data.streak > 0 ? 'Harika gidiyorsun, zinciri kırma' : 'Bugün bir ders bitir, serin başlasın',
                      style: AppTextStyles.bodySm.variant,
                    ),
                  ],
                ),
              ),
              Text('${data.goalPercent}%', style: AppTextStyles.labelLg.bold.withColor(AppColors.primary)),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 12,
              child: Stack(
                children: [
                  Container(color: AppColors.surfaceContainerLow),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: data.goalPercent / 100),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOut,
                    builder: (_, v, _) => FractionallySizedBox(
                      widthFactor: v,
                      child: Container(
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(999)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [for (final day in data.week) _DayDot(day: day)],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({required this.day});
  final WeekDay day;

  @override
  Widget build(BuildContext context) {
    final Widget dot;
    if (day.isToday && !day.done) {
      dot = _circle(AppColors.primaryFixed, Text('●', style: AppTextStyles.labelSm.withColor(AppColors.primary)));
    } else if (day.done) {
      dot = _circle(AppColors.primary, const Icon(Symbols.check, size: 13, color: AppColors.onPrimary, weight: 700));
    } else {
      dot = _circle(AppColors.surfaceContainerLow, null);
    }
    return Column(
      spacing: 4,
      children: [
        Text(
          day.label,
          style: day.isToday ? AppTextStyles.labelSm.withColor(AppColors.primary) : AppTextStyles.labelSm.variant,
        ),
        dot,
      ],
    );
  }

  Widget _circle(Color bg, Widget? child) => Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: child,
      );
}

class _FeaturedLessonCard extends StatelessWidget {
  const _FeaturedLessonCard({required this.lesson});
  final CurrentLesson lesson;

  @override
  Widget build(BuildContext context) {
    final glass = Colors.white.withValues(alpha: 0.2);
    void open() => context.push('/lesson/${lesson.id}');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.strong(),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned(top: -40, right: -40, child: GlowBlob(size: 176, color: Color(0x55E4DFFF))),
          Positioned(
            right: 0,
            bottom: 0,
            child: Opacity(opacity: 0.1, child: Icon(Symbols.graphic_eq, size: 140, color: Colors.white)),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Pill(
                      text: lesson.number != null ? 'Ders #${lesson.number}' : skillLabel(lesson.skill),
                      icon: skillIcon(lesson.skill),
                      background: glass,
                      foreground: Colors.white,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Pill(
                      text: '${lesson.minutes} dakika',
                      background: glass,
                      foreground: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                    const Spacer(),
                    RoundIconButton(
                      icon: Symbols.north_east,
                      onPressed: open,
                      background: glass,
                      foreground: Colors.white,
                      iconSize: 20,
                      shadow: null,
                      tooltip: 'Ayrıntılar',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md + 4),
                Text(lesson.title, style: AppTextStyles.headlineMd.bold.withColor(Colors.white)),
                if (lesson.description != null) ...[
                  const SizedBox(height: 4),
                  Text(lesson.description!, style: AppTextStyles.bodyMd.withColor(AppColors.onPrimaryContainer.withValues(alpha: 0.9))),
                ],
                const SizedBox(height: AppSpacing.md + 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const _MiniWave(),
                    const Spacer(),
                    SoftButton(
                      label: 'Devam Et',
                      icon: Symbols.play_arrow,
                      onPressed: open,
                      background: Colors.white,
                      foreground: AppColors.primary,
                      style: AppTextStyles.labelLg,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      shadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 6))],
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

/// Karttaki mini ses dalgası (6 çubuk, bazıları nabız atar).
class _MiniWave extends StatefulWidget {
  const _MiniWave();

  @override
  State<_MiniWave> createState() => _MiniWaveState();
}

class _MiniWaveState extends State<_MiniWave> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  static const _bars = [(12.0, 0.7, true), (20.0, 0.9, false), (24.0, 1.0, true), (16.0, 0.8, false), (8.0, 0.6, false), (20.0, 0.9, false)];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: 4,
          children: [
            for (final (h, a, pulse) in _bars)
              Container(
                width: 4,
                height: h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: pulse ? a * (0.5 + _c.value * 0.5) : a),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  const _PracticeCard({required this.scenario});
  final FeaturedScenario scenario;

  @override
  Widget build(BuildContext context) {
    void open() => context.go('/chat?scenario=${scenario.id}');
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      shadow: AppShadows.card(0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Pill(
                          text: 'AI Mentor',
                          background: AppColors.secondaryFixed,
                          foreground: AppColors.onSecondaryFixed,
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Icon(Symbols.timer, size: 14, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Text('${scenario.minutes} dk', style: AppTextStyles.labelSm.variant),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Akıcı Konuşma Pratiği', style: AppTextStyles.headlineSm.bold),
                    const SizedBox(height: 4),
                    Text(
                      scenario.description ?? scenario.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySm.variant,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: [BoxShadow(color: AppColors.secondaryContainer.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
                    ),
                    child: Icon(iconFromName(scenario.icon == 'restaurant' ? 'forum' : scenario.icon), size: 32, color: AppColors.onSecondaryContainer),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.tertiary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              SizedBox(
                width: 72,
                height: 28,
                child: Stack(
                  children: [
                    for (final (i, label, bg, fg) in [
                      (0, 'A', AppColors.primaryFixed, AppColors.onPrimaryFixed),
                      (1, 'B', AppColors.secondaryFixed, AppColors.onSecondaryFixed),
                      (2, '+3', AppColors.tertiaryFixed, AppColors.onTertiaryFixed),
                    ])
                      Positioned(
                        left: i * 20.0,
                        child: Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                          child: Text(label, style: AppTextStyles.labelSm.withColor(fg)),
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              SoftButton(label: 'Pratiğe Başla', icon: Symbols.arrow_forward, onPressed: open),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickModules extends StatelessWidget {
  const _QuickModules({required this.data});
  final HomeData data;

  @override
  Widget build(BuildContext context) {
    final word = data.wordOfDay;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SectionHeader(title: 'Hızlı AI Modülleri', action: 'Tümü', onAction: () => context.go('/practice')),
        ),
        Row(
          spacing: AppSpacing.sm,
          children: [
            _ModuleButton(
              icon: Symbols.smart_toy,
              bg: AppColors.primaryFixed,
              fg: AppColors.primary,
              title: 'AI Sohbet',
              subtitle: 'Sesli & Yazılı',
              onTap: () => context.go('/chat'),
            ),
            _ModuleButton(
              icon: Symbols.lightbulb,
              bg: AppColors.secondaryFixed,
              fg: AppColors.secondary,
              title: 'Günün Sözü',
              subtitle: word != null ? '"${word.word[0].toUpperCase()}${word.word.substring(1)}"' : '—',
              onTap: word == null
                  ? null
                  : () => showMessage(context, '${word.word} = ${word.translation}'),
            ),
            _ModuleButton(
              icon: Symbols.record_voice_over,
              bg: AppColors.tertiaryFixed,
              fg: AppColors.tertiary,
              title: 'Telaffuz',
              subtitle: 'Anlık Skor',
              onTap: () => context.go('/chat'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ModuleButton extends StatelessWidget {
  const _ModuleButton({required this.icon, required this.bg, required this.fg, required this.title, required this.subtitle, this.onTap});
  final IconData icon;
  final Color bg;
  final Color fg;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        radius: AppRadius.md,
        padding: const EdgeInsets.all(AppSpacing.sm),
        shadow: [BoxShadow(color: AppColors.violetShadow(0.04), blurRadius: 16, offset: const Offset(0, 4))],
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, size: 24, color: fg),
            ),
            const SizedBox(height: 6),
            Text(title, style: AppTextStyles.labelMd, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(subtitle, style: AppTextStyles.labelSm.variant, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _TipBanner extends StatelessWidget {
  const _TipBanner({required this.tip});
  final String tip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 14, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          const Icon(Symbols.tips_and_updates, size: 24, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Günün İpucu:', style: AppTextStyles.labelMd.bold),
                Text(tip, style: AppTextStyles.bodySm.variant),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
