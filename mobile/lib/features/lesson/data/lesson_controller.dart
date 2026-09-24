import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'lesson_models.dart';

final lessonProvider = FutureProvider.autoDispose.family<Lesson, int>((ref, id) async {
  final data = await ref.watch(apiClientProvider).get<Map<String, dynamic>>('/lessons/$id');
  return Lesson.fromJson(data);
});

enum AnswerPhase { answering, checked }

class LessonSession {
  const LessonSession({
    required this.index,
    required this.phase,
    required this.canCheck,
    required this.lastCorrect,
    required this.results,
    required this.remainingSeconds,
    required this.submitting,
    this.result,
    this.error,
  });

  final int index;
  final AnswerPhase phase;
  final bool canCheck;
  final bool? lastCorrect;
  final Map<int, bool> results;
  final int? remainingSeconds;
  final bool submitting;
  final LessonResult? result;
  final String? error;

  LessonSession copyWith({
    int? index,
    AnswerPhase? phase,
    bool? canCheck,
    bool? lastCorrect,
    bool clearLast = false,
    Map<int, bool>? results,
    int? remainingSeconds,
    bool? submitting,
    LessonResult? result,
    String? error,
  }) =>
      LessonSession(
        index: index ?? this.index,
        phase: phase ?? this.phase,
        canCheck: canCheck ?? this.canCheck,
        lastCorrect: clearLast ? null : (lastCorrect ?? this.lastCorrect),
        results: results ?? this.results,
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
        submitting: submitting ?? this.submitting,
        result: result ?? this.result,
        error: error,
      );
}

final lessonSessionProvider =
    NotifierProvider.autoDispose.family<LessonSessionController, LessonSession, Lesson>(LessonSessionController.new);

/// Bir ders oturumu: soru sırası, cevap kontrolü, süre sayacı ve sonucun sunucuya gönderilmesi.
class LessonSessionController extends Notifier<LessonSession> {
  LessonSessionController(this.lesson);
  final Lesson lesson;

  Timer? _timer;
  final _stopwatch = Stopwatch();

  /// Aktif alıştırma widget'ının cevabı değerlendiren fonksiyonu.
  bool Function()? _evaluator;

  @override
  LessonSession build() {
    _stopwatch.start();
    if (lesson.timeLimitSeconds != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
    ref.onDispose(() => _timer?.cancel());
    return LessonSession(
      index: 0,
      phase: AnswerPhase.answering,
      canCheck: false,
      lastCorrect: null,
      results: const {},
      remainingSeconds: lesson.timeLimitSeconds,
      submitting: false,
    );
  }

  Exercise get current => lesson.exercises[state.index];
  bool get isLast => state.index == lesson.exercises.length - 1;

  void _tick() {
    final left = (state.remainingSeconds ?? 0) - 1;
    if (left <= 0) {
      _timer?.cancel();
      state = state.copyWith(remainingSeconds: 0);
      finish();
    } else {
      state = state.copyWith(remainingSeconds: left);
    }
  }

  /// Alıştırma widget'ı cevap hazır olduğunda değerlendiriciyi kaydeder.
  void setAnswer(bool Function()? evaluator) {
    _evaluator = evaluator;
    if (state.phase == AnswerPhase.answering) {
      state = state.copyWith(canCheck: evaluator != null);
    }
  }

  /// Eşleştirme gibi kendi kendini tamamlayan alıştırmalar doğrudan sonuç bildirir.
  void autoCheck(bool correct) {
    _evaluator = () => correct;
    check();
  }

  void check() {
    if (_evaluator == null || state.phase == AnswerPhase.checked) return;
    final correct = _evaluator!();
    state = state.copyWith(
      phase: AnswerPhase.checked,
      lastCorrect: correct,
      results: {...state.results, current.id: correct},
    );
  }

  void next() {
    if (isLast) {
      finish();
      return;
    }
    _evaluator = null;
    state = state.copyWith(index: state.index + 1, phase: AnswerPhase.answering, canCheck: false, clearLast: true);
  }

  Future<void> finish() async {
    if (state.submitting || state.result != null) return;
    _timer?.cancel();
    _stopwatch.stop();
    state = state.copyWith(submitting: true);
    try {
      final data = await ref.read(apiClientProvider).post<Map<String, dynamic>>(
        '/lessons/${lesson.id}/complete',
        data: {
          'answers': [
            for (final e in lesson.exercises) {'exercise_id': e.id, 'is_correct': state.results[e.id] ?? false},
          ],
          'duration_seconds': _stopwatch.elapsed.inSeconds,
        },
      );
      state = state.copyWith(submitting: false, result: LessonResult.fromJson(data));
    } catch (e) {
      state = state.copyWith(submitting: false, error: e.toString());
    }
  }
}
