import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/speech_service.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/common.dart';
import '../data/lesson_controller.dart';
import '../data/lesson_models.dart';
import 'lesson_result_screen.dart';
import 'widgets/exercise_widgets.dart';

/// ekrantasarimları/i_nteraktif_pratik_soru_ekran
class LessonScreen extends ConsumerWidget {
  const LessonScreen({super.key, required this.lessonId});
  final int lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lesson = ref.watch(lessonProvider(lessonId));
    return lesson.when(
      data: (l) => l.exercises.isEmpty
          ? Scaffold(
              appBar: StackHeader(title: l.title),
              body: ErrorState(message: 'Bu derste henüz alıştırma yok.', onRetry: () => context.pop()),
            )
          : _LessonSessionView(lesson: l),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primaryContainer))),
      error: (e, _) => Scaffold(
        appBar: const StackHeader(title: 'Ders'),
        body: ErrorState(message: e.toString(), onRetry: () => ref.invalidate(lessonProvider(lessonId))),
      ),
    );
  }
}

class _LessonSessionView extends ConsumerWidget {
  const _LessonSessionView({required this.lesson});
  final Lesson lesson;

  Future<void> _confirmExit(BuildContext context) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.cardLg)),
        title: Text('Dersten çıkılsın mı?', style: AppTextStyles.headlineSm),
        content: Text('İlerlemen kaydedilmeyecek.', style: AppTextStyles.bodyMd.variant),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Devam et')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Çık', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (leave == true && context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(lessonSessionProvider(lesson));
    final ctrl = ref.read(lessonSessionProvider(lesson).notifier);

    if (session.result != null) {
      return LessonResultScreen(lesson: lesson, result: session.result!);
    }

    final exercise = lesson.exercises[session.index];
    final total = lesson.exercises.length;
    final checked = session.phase == AnswerPhase.checked;
    final isLast = session.index == total - 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit(context);
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: StackHeader(
          title: lesson.title,
          onBack: () => _confirmExit(context),
          onMore: () => _confirmExit(context),
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.margin,
            MediaQuery.paddingOf(context).top + 64 + AppSpacing.sm,
            AppSpacing.margin,
            MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
          ),
          children: [
            _ProgressHeader(index: session.index, total: total, remaining: session.remainingSeconds),
            const SizedBox(height: AppSpacing.md),
            _Instruction(exercise: exercise),
            const SizedBox(height: AppSpacing.sm),
            _HeroCard(exercise: exercise),
            const SizedBox(height: AppSpacing.md),
            _QuestionBox(exercise: exercise, number: session.index + 1),
            const SizedBox(height: AppSpacing.lg),
            ExerciseRenderer(
              exercise: exercise,
              revealed: checked,
              onAnswer: ctrl.setAnswer,
              onAutoCheck: ctrl.autoCheck,
            ),
            const SizedBox(height: AppSpacing.xl),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, a) => SizeTransition(sizeFactor: a, child: FadeTransition(opacity: a, child: child)),
              child: checked
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _FeedbackPanel(exercise: exercise, correct: session.lastCorrect ?? false),
                    )
                  : const SizedBox.shrink(),
            ),
            if (session.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text('Sonuç gönderilemedi: ${session.error}', style: AppTextStyles.bodySm.withColor(AppColors.error)),
              ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: PrimaryButton(
                label: !checked ? 'Kontrol Et' : (isLast ? 'Dersi Bitir' : 'Sonraki Soru'),
                icon: checked ? Symbols.arrow_forward : Symbols.check,
                loading: session.submitting,
                onPressed: !checked
                    ? (session.canCheck ? ctrl.check : null)
                    : (session.error != null ? ctrl.finish : ctrl.next),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.index, required this.total, required this.remaining});
  final int index;
  final int total;
  final int? remaining;

  @override
  Widget build(BuildContext context) {
    String fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
    return Column(
      spacing: AppSpacing.xs + 2,
      children: [
        Row(
          children: [
            if (remaining != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Symbols.timer, size: 16, color: remaining! < 60 ? AppColors.error : AppColors.secondary),
                    const SizedBox(width: 6),
                    Text(
                      'Kalan Süre: ${fmt(remaining!)}',
                      style: AppTextStyles.labelMd.bold
                          .withColor(remaining! < 60 ? AppColors.error : AppColors.secondary)
                          .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            Text.rich(TextSpan(children: [
              TextSpan(text: '${index + 1}', style: AppTextStyles.labelLg.bold.withColor(AppColors.primary)),
              TextSpan(text: '  /  ', style: AppTextStyles.labelLg.withColor(AppColors.outlineVariant).copyWith(fontWeight: FontWeight.w400)),
              TextSpan(text: '$total', style: AppTextStyles.labelLg.variant.copyWith(fontWeight: FontWeight.w400)),
            ])),
          ],
        ),
        Container(
          height: 10,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(999)),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: (index + 1) / total),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              builder: (_, v, _) => FractionallySizedBox(
                widthFactor: v,
                child: Container(
                  decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(999)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Instruction extends StatelessWidget {
  const _Instruction({required this.exercise});
  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (exercise.category != null)
          Pill(
            text: exercise.category!.toUpperCase(),
            icon: Symbols.lightbulb,
            iconFill: 1,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            style: AppTextStyles.labelSm.copyWith(letterSpacing: 1.2),
          ),
        const SizedBox(height: 4),
        Text(
          exercise.instruction ?? 'Doğru cevabı seçin',
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineMd,
        ),
      ],
    );
  }
}

/// Maskot / görsel kartı ve "Sesli Dinle" butonu.
class _HeroCard extends ConsumerWidget {
  const _HeroCard({required this.exercise});
  final Exercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listen = exercise.type == ExerciseType.listenWrite;
    // Dinle-yaz'da yazılacak cümle okunur; diğerlerinde soru metni.
    final speakText = exercise.prompt.replaceAll('___', '...').replaceAll(RegExp('[“”"]'), '');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surfaceContainerLowest, AppColors.surfaceContainerLow],
        ),
        boxShadow: [BoxShadow(color: AppColors.violetShadow(0.08), blurRadius: 32, offset: const Offset(0, 16))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          const Positioned(top: -56, child: GlowBlob(size: 176, color: Color(0x88E3DFFF))),
          Column(
            children: [
              SizedBox(
                width: 144,
                height: 144,
                child: exercise.imageUrl != null
                    ? Image.network(
                        exercise.imageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => _Mascot(listen: listen),
                      )
                    : _Mascot(listen: listen),
              ),
              const SizedBox(height: 8),
              Material(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(999),
                elevation: 0,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => ref.read(speechServiceProvider).speak(
                        speakText,
                        language: listen ? 'en-US' : guessLanguage(speakText),
                        audioUrl: exercise.audioUrl,
                      ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), boxShadow: AppShadows.sm),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Symbols.volume_up, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text('Sesli Dinle', style: AppTextStyles.labelMd.withColor(AppColors.primary)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Görsel yoksa gösterilen mor tonlu maskot (kulaklıklı yuvarlak karakter).
class _Mascot extends StatelessWidget {
  const _Mascot({required this.listen});
  final bool listen;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(-0.3, -0.4),
            colors: [Color(0xFFC6BFFF), AppColors.secondaryContainer, AppColors.primaryContainer],
          ),
          boxShadow: [BoxShadow(color: AppColors.deepShadow(0.18), blurRadius: 16, offset: const Offset(0, 12))],
        ),
        child: Icon(listen ? Symbols.headphones : Symbols.sentiment_very_satisfied, size: 64, color: Colors.white, fill: 1),
      ),
    );
  }
}

class _QuestionBox extends StatelessWidget {
  const _QuestionBox({required this.exercise, required this.number});
  final Exercise exercise;
  final int number;

  @override
  Widget build(BuildContext context) {
    final listen = exercise.type == ExerciseType.listenWrite;
    return AppCard(
      radius: AppRadius.md,
      child: Column(
        children: [
          Text('Soru $number', style: AppTextStyles.labelMd.variant),
          const SizedBox(height: 4),
          Text(
            listen ? 'Dinle ve duyduğunu yaz' : exercise.prompt,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineSm.bold.copyWith(height: 1.3),
          ),
          if (!listen && exercise.promptTranslation != null && exercise.type != ExerciseType.sentenceOrder) ...[
            const SizedBox(height: 4),
            Text(exercise.promptTranslation!, textAlign: TextAlign.center, style: AppTextStyles.bodySm.variant),
          ],
        ],
      ),
    );
  }
}

class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({required this.exercise, required this.correct});
  final Exercise exercise;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    final answer = exercise.correctAnswerLabel;
    final detail = correct
        ? (exercise.explanation ?? 'Doğru cevap!')
        : (answer.isNotEmpty ? 'Doğru cevap: $answer' : (exercise.explanation ?? 'Bir dahakine!'));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: correct ? AppColors.tertiaryFixed : AppColors.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              correct ? Symbols.sentiment_very_satisfied : Symbols.sentiment_dissatisfied,
              size: 20,
              fill: 1,
              color: correct ? AppColors.onTertiaryFixed : AppColors.onErrorContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(correct ? 'Harika seçim!' : 'Neredeyse!', style: AppTextStyles.labelLg.copyWith(height: 1.2)),
                Text(detail, style: AppTextStyles.bodySm.variant),
              ],
            ),
          ),
          if (correct)
            Pill(
              text: '+${exercise.xp} XP',
              background: AppColors.tertiaryFixed,
              foreground: AppColors.onTertiaryFixed,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
        ],
      ),
    );
  }
}
