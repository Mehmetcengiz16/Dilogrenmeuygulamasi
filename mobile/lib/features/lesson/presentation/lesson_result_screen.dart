import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/icon_map.dart';
import '../../../core/widgets/common.dart';
import '../../auth/data/auth_controller.dart';
import '../../home/data/home_data.dart';
import '../../practice/data/practice_data.dart';
import '../data/lesson_models.dart';

class LessonResultScreen extends ConsumerStatefulWidget {
  const LessonResultScreen({super.key, required this.lesson, required this.result});
  final Lesson lesson;
  final LessonResult result;

  @override
  ConsumerState<LessonResultScreen> createState() => _LessonResultScreenState();
}

class _LessonResultScreenState extends ConsumerState<LessonResultScreen> {
  @override
  void initState() {
    super.initState();
    // Üst bilgi (XP, seri), ana sayfa ve öğrenme yolu güncellensin.
    Future.microtask(() {
      ref.read(authControllerProvider.notifier).refresh();
      ref.invalidate(homeProvider);
      ref.invalidate(coursePathProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final great = r.score >= 80;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned(top: -80, left: -60, child: GlowBlob(size: 300, color: Color(0x556C5CE7))),
          const Positioned(bottom: 40, right: -90, child: GlowBlob(size: 280, color: Color(0x4063FBCF))),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.margin),
              children: [
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.6, end: 1),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (_, v, child) => Transform.scale(scale: v, child: child),
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primaryContainer, AppColors.primary, AppColors.secondary],
                        ),
                        boxShadow: AppShadows.strong(0.35),
                      ),
                      child: Icon(great ? Symbols.emoji_events : Symbols.thumb_up, size: 72, color: Colors.white, fill: 1),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(great ? 'Muhteşem iş!' : 'Ders tamamlandı!', textAlign: TextAlign.center, style: AppTextStyles.headlineLg),
                const SizedBox(height: 4),
                Text(widget.lesson.title, textAlign: TextAlign.center, style: AppTextStyles.bodyMd.variant),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  spacing: AppSpacing.sm,
                  children: [
                    _Stat(icon: Symbols.bolt, value: '+${r.xpEarned}', label: 'XP', bg: AppColors.tertiaryFixed, fg: AppColors.tertiary),
                    _Stat(icon: Symbols.target, value: '%${r.score}', label: '${r.correct}/${r.total} doğru', bg: AppColors.primaryFixed, fg: AppColors.primary),
                    _Stat(icon: Symbols.local_fire_department, value: '${r.streak}', label: 'Gün seri', bg: AppColors.secondaryFixed, fg: AppColors.secondary),
                  ],
                ),
                if (r.newBadges.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: AppSpacing.sm,
                      children: [
                        Text('Yeni rozet kazandın!', style: AppTextStyles.headlineSm),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final b in r.newBadges)
                              Pill(text: b.name, icon: iconFromName(b.icon), iconFill: 1, style: AppTextStyles.labelMd,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                if (r.nextLessonId != null) ...[
                  PrimaryButton(
                    label: 'Sonraki Ders',
                    icon: Symbols.arrow_forward,
                    onPressed: () => context.pushReplacement('/lesson/${r.nextLessonId}'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/home'),
                    child: Text('Ana sayfaya dön', style: AppTextStyles.labelLg.withColor(AppColors.primary)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label, required this.bg, required this.fg});
  final IconData icon;
  final String value;
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        radius: AppRadius.card,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, size: 20, color: fg, fill: 1),
            ),
            const SizedBox(height: 8),
            Text(value, style: AppTextStyles.headlineMd.bold),
            Text(label, style: AppTextStyles.bodySm.variant, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
