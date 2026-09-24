import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/icon_map.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/shell_scaffold.dart';
import '../../home/data/home_data.dart';
import '../data/practice_data.dart';

/// Pratik sekmesi: aktif kursun ünite/ders yolu. Aktif kurs yoksa kurs seçimi.
class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = ref.watch(coursePathProvider);
    return AsyncBody(
      value: path,
      onRetry: () => ref.invalidate(coursePathProvider),
      data: (p) => p == null
          ? const CoursePicker()
          : RefreshIndicator(
              color: AppColors.primaryContainer,
              edgeOffset: ShellScaffold.topInset(context),
              onRefresh: () => ref.refresh(coursePathProvider.future),
              child: ListView(
                padding: ShellScaffold.contentPadding(context, vertical: AppSpacing.md),
                children: [
                  Row(
                    children: [
                      Pill(text: 'Öğrenme Yolu', padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _showCourses(context),
                        icon: const Icon(Symbols.swap_horiz, size: 18, color: AppColors.primary),
                        label: Text('Kurs değiştir', style: AppTextStyles.labelMd.withColor(AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(p.title, style: AppTextStyles.headlineLg),
                  const SizedBox(height: AppSpacing.md),
                  _VocabularyEntry(onTap: () => context.push('/vocabulary')),
                  for (final (i, unit) in p.units.indexed) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _UnitHeader(unit: unit, index: i + 1),
                    const SizedBox(height: AppSpacing.sm),
                    for (final lesson in unit.lessons) _LessonTile(lesson: lesson),
                  ],
                ],
              ),
            ),
    );
  }

  void _showCourses(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.cardLg))),
      builder: (_) => const SizedBox(height: 520, child: CoursePicker(inSheet: true)),
    );
  }
}

class _VocabularyEntry extends StatelessWidget {
  const _VocabularyEntry({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.secondaryFixed,
      radius: AppRadius.card,
      shadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8))],
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.onSecondaryFixed.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Symbols.style, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('KELİME DEFTERİ', style: AppTextStyles.labelSm.withColor(AppColors.onSecondaryFixed.withValues(alpha: 0.8)).copyWith(letterSpacing: 1.2)),
                Text('Tekrar kartları', style: AppTextStyles.headlineSm.withColor(AppColors.onSecondaryFixed)),
              ],
            ),
          ),
          const Icon(Symbols.north_east, size: 18, color: AppColors.onSecondaryFixed),
        ],
      ),
    );
  }
}

class _UnitHeader extends StatelessWidget {
  const _UnitHeader({required this.unit, required this.index});
  final PathUnit unit;
  final int index;

  @override
  Widget build(BuildContext context) {
    final done = unit.lessons.where((l) => l.completed).length;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.primaryFixed, shape: BoxShape.circle),
          child: Text('$index', style: AppTextStyles.labelLg.bold.withColor(AppColors.primary)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(unit.title, style: AppTextStyles.headlineSm),
              if (unit.description != null) Text(unit.description!, style: AppTextStyles.bodySm.variant),
            ],
          ),
        ),
        Pill(
          text: '$done/${unit.lessons.length}',
          background: done == unit.lessons.length ? AppColors.tertiaryFixed : AppColors.surfaceContainer,
          foreground: done == unit.lessons.length ? AppColors.onTertiaryFixed : AppColors.onSurfaceVariant,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        ),
      ],
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson});
  final PathLesson lesson;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = lesson.completed
        ? (AppColors.primary, AppColors.onPrimary, Symbols.check)
        : lesson.locked
            ? (AppColors.surfaceContainer, AppColors.outline, Symbols.lock)
            : (AppColors.primaryContainer, AppColors.onPrimary, skillIcon(lesson.skill));

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Opacity(
        opacity: lesson.locked ? 0.6 : 1,
        child: AppCard(
          radius: AppRadius.card,
          padding: const EdgeInsets.all(12),
          shadow: lesson.locked ? AppShadows.sm : AppShadows.soft(),
          onTap: lesson.locked
              ? () => showMessage(context, 'Önce önceki dersi tamamla.')
              : () => context.push('/lesson/${lesson.id}'),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                  boxShadow: lesson.locked ? null : [BoxShadow(color: AppColors.deepShadow(0.25), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Icon(icon, size: 22, color: fg, fill: lesson.completed ? 1 : 0),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ders #${lesson.number} · ${skillLabel(lesson.skill)}', style: AppTextStyles.labelSm.variant),
                    Text(lesson.title, style: AppTextStyles.labelLg),
                    Text('${lesson.exerciseCount} soru · ${lesson.minutes} dk', style: AppTextStyles.bodySm.variant),
                  ],
                ),
              ),
              if (lesson.completed)
                Pill(text: '%${lesson.score}', background: AppColors.tertiaryFixed, foreground: AppColors.onTertiaryFixed)
              else if (!lesson.locked)
                Pill(text: '+${lesson.xp} XP'),
            ],
          ),
        ),
      ),
    );
  }
}

class CoursePicker extends ConsumerWidget {
  const CoursePicker({super.key, this.inSheet = false});
  final bool inSheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courses = ref.watch(coursesProvider);
    return AsyncBody(
      value: courses,
      onRetry: () => ref.invalidate(coursesProvider),
      data: (list) => ListView(
        padding: inSheet ? const EdgeInsets.all(AppSpacing.margin) : ShellScaffold.contentPadding(context, vertical: AppSpacing.md),
        children: [
          Text('Bir kurs seç', style: AppTextStyles.headlineLg),
          Text('Seviyene uygun kursla öğrenme yolunu başlat.', style: AppTextStyles.bodyMd.variant),
          const SizedBox(height: AppSpacing.md),
          for (final c in list)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                radius: AppRadius.card,
                onTap: () async {
                  try {
                    await enrollCourse(ref, c.id);
                    ref.invalidate(homeProvider);
                    if (inSheet && context.mounted) Navigator.pop(context);
                  } on ApiException catch (e) {
                    if (context.mounted) showMessage(context, e.message);
                  }
                },
                child: Row(
                  children: [
                    Text(c.flag ?? '🌍', style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.title, style: AppTextStyles.headlineSm),
                          Text('${c.lessonCount} ders', style: AppTextStyles.bodySm.variant),
                        ],
                      ),
                    ),
                    Pill(text: c.level),
                    if (c.isActive) ...[
                      const SizedBox(width: 6),
                      const Icon(Symbols.check_circle, color: AppColors.tertiary, fill: 1),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
