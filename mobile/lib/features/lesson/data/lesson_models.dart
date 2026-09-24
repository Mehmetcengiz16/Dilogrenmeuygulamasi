enum ExerciseType {
  multipleChoice('multiple_choice'),
  matchPairs('match_pairs'),
  fillBlank('fill_blank'),
  sentenceOrder('sentence_order'),
  listenWrite('listen_write'),
  imageSelect('image_select');

  const ExerciseType(this.value);
  final String value;

  static ExerciseType from(String v) => values.firstWhere((t) => t.value == v, orElse: () => multipleChoice);
}

class ExerciseOption {
  ExerciseOption({required this.id, required this.text, this.translation, this.imageUrl, required this.isCorrect, this.pairKey});

  final int id;
  final String text;
  final String? translation;
  final String? imageUrl;
  final bool isCorrect;
  final String? pairKey;

  factory ExerciseOption.fromJson(Map<String, dynamic> j) => ExerciseOption(
        id: j['id'] as int,
        text: j['text'] as String,
        translation: j['translation'] as String?,
        imageUrl: j['image_url'] as String?,
        isCorrect: j['is_correct'] as bool? ?? false,
        pairKey: j['pair_key'] as String?,
      );
}

class Exercise {
  Exercise({
    required this.id,
    required this.type,
    this.category,
    this.instruction,
    required this.prompt,
    this.promptTranslation,
    this.answerText,
    this.explanation,
    this.audioUrl,
    this.imageUrl,
    required this.xp,
    required this.options,
  });

  final int id;
  final ExerciseType type;
  final String? category;
  final String? instruction;
  final String prompt;
  final String? promptTranslation;
  final String? answerText;
  final String? explanation;
  final String? audioUrl;
  final String? imageUrl;
  final int xp;
  final List<ExerciseOption> options;

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
        id: j['id'] as int,
        type: ExerciseType.from(j['type'] as String),
        category: j['category'] as String?,
        instruction: j['instruction'] as String?,
        prompt: j['prompt'] as String,
        promptTranslation: j['prompt_translation'] as String?,
        answerText: (j['correct_answer'] as Map?)?['text'] as String?,
        explanation: j['explanation'] as String?,
        audioUrl: j['audio_url'] as String?,
        imageUrl: j['image_url'] as String?,
        xp: j['xp'] as int? ?? 10,
        options: (j['options'] as List).map((o) => ExerciseOption.fromJson(o as Map<String, dynamic>)).toList(),
      );

  /// Metin cevaplarını büyük/küçük harf, noktalama ve fazla boşluktan bağımsız karşılaştırır.
  static String normalize(String s) => s
      .toLowerCase()
      .replaceAll('’', "'")
      .replaceAll(RegExp(r"[^\p{L}\p{N}' ]", unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  bool matchesText(String input) => answerText != null && normalize(input) == normalize(answerText!);

  /// Doğru cevabın okunabilir hali (yanlış cevap geri bildirimi için).
  String get correctAnswerLabel => switch (type) {
        ExerciseType.multipleChoice || ExerciseType.imageSelect =>
          options.where((o) => o.isCorrect).map((o) => o.text).join(', '),
        _ => answerText ?? '',
      };
}

class Lesson {
  Lesson({required this.id, required this.title, required this.xpReward, this.timeLimitSeconds, required this.exercises});

  final int id;
  final String title;
  final int xpReward;
  final int? timeLimitSeconds;
  final List<Exercise> exercises;

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        id: j['id'] as int,
        title: j['title'] as String,
        xpReward: j['xp_reward'] as int? ?? 0,
        timeLimitSeconds: j['time_limit_seconds'] as int?,
        exercises: (j['exercises'] as List).map((e) => Exercise.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class LessonResult {
  LessonResult({
    required this.score,
    required this.correct,
    required this.total,
    required this.xpEarned,
    required this.streak,
    this.nextLessonId,
    required this.newBadges,
  });

  final int score;
  final int correct;
  final int total;
  final int xpEarned;
  final int streak;
  final int? nextLessonId;
  final List<({String name, String icon})> newBadges;

  factory LessonResult.fromJson(Map<String, dynamic> j) => LessonResult(
        score: j['score'] as int,
        correct: j['correct'] as int,
        total: j['total'] as int,
        xpEarned: j['xp_earned'] as int,
        streak: j['streak'] as int,
        nextLessonId: j['next_lesson_id'] as int?,
        newBadges: (j['new_badges'] as List)
            .map((b) => (name: (b as Map)['name'] as String, icon: b['icon'] as String))
            .toList(),
      );
}
