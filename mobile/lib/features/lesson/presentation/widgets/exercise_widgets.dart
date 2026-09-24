import 'dart:math';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/lesson_models.dart';

/// Alıştırma widget'larının ortak sözleşmesi.
/// [onAnswer]: cevap kontrol edilebilir hale gelince değerlendirici verir, geri alınınca null.
/// [onAutoCheck]: kendi kendini tamamlayan tipler (eşleştirme) doğrudan sonucu bildirir.
/// [revealed]: kontrol edildi; doğru/yanlış renkleri gösterilir, etkileşim kapanır.
class ExerciseRenderer extends StatelessWidget {
  const ExerciseRenderer({
    super.key,
    required this.exercise,
    required this.revealed,
    required this.onAnswer,
    required this.onAutoCheck,
  });

  final Exercise exercise;
  final bool revealed;
  final ValueChanged<bool Function()?> onAnswer;
  final ValueChanged<bool> onAutoCheck;

  @override
  Widget build(BuildContext context) {
    final key = ValueKey(exercise.id);
    return switch (exercise.type) {
      ExerciseType.multipleChoice => ChoiceGrid(key: key, exercise: exercise, revealed: revealed, onAnswer: onAnswer),
      ExerciseType.imageSelect => ChoiceGrid(key: key, exercise: exercise, revealed: revealed, onAnswer: onAnswer, withImages: true),
      ExerciseType.fillBlank || ExerciseType.listenWrite =>
        TextAnswer(key: key, exercise: exercise, revealed: revealed, onAnswer: onAnswer),
      ExerciseType.sentenceOrder => SentenceBuilder(key: key, exercise: exercise, revealed: revealed, onAnswer: onAnswer),
      ExerciseType.matchPairs => MatchPairs(key: key, exercise: exercise, revealed: revealed, onDone: onAutoCheck),
    };
  }
}

// ─── Çoktan seçmeli / görselden seçim (2x2 kart ızgarası) ───────────────────

class ChoiceGrid extends StatefulWidget {
  const ChoiceGrid({super.key, required this.exercise, required this.revealed, required this.onAnswer, this.withImages = false});
  final Exercise exercise;
  final bool revealed;
  final ValueChanged<bool Function()?> onAnswer;
  final bool withImages;

  @override
  State<ChoiceGrid> createState() => _ChoiceGridState();
}

class _ChoiceGridState extends State<ChoiceGrid> {
  int? _selected;

  void _select(ExerciseOption o) {
    if (widget.revealed) return;
    setState(() => _selected = o.id);
    widget.onAnswer(() => o.isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.exercise.options;
    return LayoutBuilder(builder: (context, c) {
      final w = (c.maxWidth - AppSpacing.sm) / 2;
      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (var i = 0; i < options.length; i++)
            SizedBox(
              width: w,
              child: OptionCard(
                letter: String.fromCharCode(65 + i),
                option: options[i],
                selected: _selected == options[i].id,
                revealed: widget.revealed,
                withImage: widget.withImages,
                onTap: () => _select(options[i]),
              ),
            ),
        ],
      );
    });
  }
}

class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.letter,
    required this.option,
    required this.selected,
    required this.revealed,
    required this.onTap,
    this.withImage = false,
  });

  final String letter;
  final ExerciseOption option;
  final bool selected;
  final bool revealed;
  final bool withImage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Kontrol sonrası: doğru seçenek yeşil, yanlış seçilen kırmızı.
    final showCorrect = revealed && option.isCorrect;
    final showWrong = revealed && selected && !option.isCorrect;
    final accent = showCorrect
        ? AppColors.tertiaryContainer
        : showWrong
            ? AppColors.error
            : AppColors.primaryContainer;
    final active = selected || showCorrect;

    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minHeight: 96),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          gradient: active
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.surfaceContainerLowest, AppColors.surfaceContainerLow],
                )
              : null,
          color: active ? null : AppColors.surfaceContainerLowest,
          border: Border.all(color: active || showWrong ? accent : Colors.transparent, width: 2),
          boxShadow: active
              ? [BoxShadow(color: accent.withValues(alpha: 0.18), blurRadius: 20, offset: const Offset(0, 8))]
              : const [BoxShadow(color: Color(0x0D000000), blurRadius: 3, offset: Offset(0, 1))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md - 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: active || showWrong ? accent : AppColors.surfaceContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          letter,
                          style: AppTextStyles.labelMd.withColor(active || showWrong ? Colors.white : AppColors.onSurfaceVariant),
                        ),
                      ),
                      const Spacer(),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: active || showWrong ? 1 : 0,
                        child: Icon(showWrong ? Symbols.cancel : Symbols.check_circle, size: 22, color: accent, fill: 1),
                      ),
                    ],
                  ),
                  if (withImage && option.imageUrl != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Image.network(option.imageUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(color: AppColors.surfaceContainerLow)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    option.text,
                    style: active ? AppTextStyles.headlineSm.bold : AppTextStyles.headlineSm,
                  ),
                  // Çeviri cevabı ele vermesin diye yalnızca kontrol sonrasında gösterilir.
                  if (revealed && option.translation != null)
                    Text(
                      option.translation!,
                      style: active
                          ? AppTextStyles.bodySm.withColor(accent).copyWith(fontWeight: FontWeight.w500)
                          : AppTextStyles.bodySm.withColor(AppColors.onSurfaceVariant.withValues(alpha: 0.75)),
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

// ─── Boşluk doldurma / dinle-yaz ─────────────────────────────────────────────

class TextAnswer extends StatefulWidget {
  const TextAnswer({super.key, required this.exercise, required this.revealed, required this.onAnswer});
  final Exercise exercise;
  final bool revealed;
  final ValueChanged<bool Function()?> onAnswer;

  @override
  State<TextAnswer> createState() => _TextAnswerState();
}

class _TextAnswerState extends State<TextAnswer> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _changed(String v) {
    widget.onAnswer(v.trim().isEmpty ? null : () => widget.exercise.matchesText(_c.text));
  }

  @override
  Widget build(BuildContext context) {
    final correct = widget.revealed ? widget.exercise.matchesText(_c.text) : null;
    final border = switch (correct) {
      true => AppColors.tertiaryContainer,
      false => AppColors.error,
      null => Colors.transparent,
    };
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: border, width: 2),
        boxShadow: [BoxShadow(color: AppColors.violetShadow(0.06), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      child: TextField(
        controller: _c,
        enabled: !widget.revealed,
        onChanged: _changed,
        autocorrect: false,
        textCapitalization: TextCapitalization.none,
        style: AppTextStyles.headlineSm,
        minLines: 1,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: widget.exercise.type == ExerciseType.listenWrite ? 'Duyduğunu yaz...' : 'Cevabını yaz...',
          fillColor: Colors.transparent,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          prefixIcon: const Icon(Symbols.edit, size: 20, color: AppColors.onSurfaceVariant),
        ),
      ),
    );
  }
}

// ─── Cümle kurma (kelime bankası) ───────────────────────────────────────────

class SentenceBuilder extends StatefulWidget {
  const SentenceBuilder({super.key, required this.exercise, required this.revealed, required this.onAnswer});
  final Exercise exercise;
  final bool revealed;
  final ValueChanged<bool Function()?> onAnswer;

  @override
  State<SentenceBuilder> createState() => _SentenceBuilderState();
}

class _SentenceBuilderState extends State<SentenceBuilder> {
  final List<ExerciseOption> _picked = [];

  String get _sentence => _picked.map((o) => o.text).join(' ');

  void _toggle(ExerciseOption o) {
    if (widget.revealed) return;
    setState(() => _picked.contains(o) ? _picked.remove(o) : _picked.add(o));
    widget.onAnswer(_picked.isEmpty ? null : () => widget.exercise.matchesText(_sentence));
  }

  @override
  Widget build(BuildContext context) {
    final correct = widget.revealed ? widget.exercise.matchesText(_sentence) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 96),
          padding: const EdgeInsets.all(AppSpacing.md - 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              width: 2,
              color: switch (correct) {
                true => AppColors.tertiaryContainer,
                false => AppColors.error,
                null => AppColors.primaryFixed,
              },
            ),
          ),
          child: _picked.isEmpty
              ? Center(child: Text('Kelimelere dokunarak cümleyi kur', style: AppTextStyles.bodyMd.variant))
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final o in _picked) _WordChip(text: o.text, onTap: () => _toggle(o), active: true)],
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in widget.exercise.options)
              _WordChip(text: o.text, onTap: () => _toggle(o), used: _picked.contains(o)),
          ],
        ),
      ],
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({required this.text, required this.onTap, this.active = false, this.used = false});
  final String text;
  final VoidCallback onTap;
  final bool active;
  final bool used;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: used ? 0.3 : 1,
      child: Material(
        color: active ? AppColors.primaryFixed : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(999),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: used ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              boxShadow: active ? null : const [BoxShadow(color: Color(0x0D000000), blurRadius: 3, offset: Offset(0, 1))],
            ),
            child: Text(text, style: AppTextStyles.labelLg.withColor(active ? AppColors.onPrimaryFixed : AppColors.onSurface)),
          ),
        ),
      ),
    );
  }
}

// ─── Eşleştirme ─────────────────────────────────────────────────────────────

class MatchPairs extends StatefulWidget {
  const MatchPairs({super.key, required this.exercise, required this.revealed, required this.onDone});
  final Exercise exercise;
  final bool revealed;
  final ValueChanged<bool> onDone;

  @override
  State<MatchPairs> createState() => _MatchPairsState();
}

class _MatchPairsState extends State<MatchPairs> {
  late final List<ExerciseOption> _left;
  late final List<ExerciseOption> _right;
  ExerciseOption? _pickedLeft;
  final Set<String> _matched = {};
  int? _wrongId;
  int _mistakes = 0;

  @override
  void initState() {
    super.initState();
    // Her çiftin ilk öğesi solda, ikincisi karıştırılmış olarak sağda.
    final groups = <String, List<ExerciseOption>>{};
    for (final o in widget.exercise.options) {
      groups.putIfAbsent(o.pairKey ?? '${o.id}', () => []).add(o);
    }
    _left = [for (final g in groups.values) g.first];
    _right = [for (final g in groups.values) if (g.length > 1) g[1]]..shuffle(Random(widget.exercise.id));
  }

  void _tapLeft(ExerciseOption o) {
    if (_matched.contains(o.pairKey)) return;
    setState(() => _pickedLeft = o);
  }

  Future<void> _tapRight(ExerciseOption o) async {
    final left = _pickedLeft;
    if (left == null || _matched.contains(o.pairKey)) return;
    if (left.pairKey == o.pairKey) {
      setState(() {
        _matched.add(o.pairKey!);
        _pickedLeft = null;
      });
      if (_matched.length == _left.length) widget.onDone(_mistakes == 0);
    } else {
      setState(() {
        _mistakes++;
        _wrongId = o.id;
      });
      await Future.delayed(const Duration(milliseconds: 450));
      if (mounted) setState(() => _wrongId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget tile(ExerciseOption o, {required bool isLeft}) {
      final matched = _matched.contains(o.pairKey);
      final picked = isLeft && _pickedLeft?.id == o.id;
      final wrong = _wrongId == o.id;
      final color = matched
          ? AppColors.tertiaryContainer
          : wrong
              ? AppColors.error
              : picked
                  ? AppColors.primaryContainer
                  : Colors.transparent;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 56,
        decoration: BoxDecoration(
          color: matched ? AppColors.tertiaryFixed.withValues(alpha: 0.35) : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color, width: 2),
          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 3, offset: Offset(0, 1))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: widget.revealed || matched ? null : () => isLeft ? _tapLeft(o) : _tapRight(o),
            child: Center(
              child: Text(o.text,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelLg.withColor(matched ? AppColors.tertiary : AppColors.onSurface)),
            ),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        Expanded(child: Column(spacing: AppSpacing.sm, children: [for (final o in _left) tile(o, isLeft: true)])),
        Expanded(child: Column(spacing: AppSpacing.sm, children: [for (final o in _right) tile(o, isLeft: false)])),
      ],
    );
  }
}
