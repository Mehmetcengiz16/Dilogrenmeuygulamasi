import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/data/auth_controller.dart';

class PathLesson {
  PathLesson({
    required this.id,
    required this.number,
    required this.title,
    this.description,
    required this.skill,
    required this.xp,
    required this.minutes,
    required this.exerciseCount,
    required this.status,
    required this.score,
  });

  final int id;
  final int number;
  final String title;
  final String? description;
  final String skill;
  final int xp;
  final int minutes;
  final int exerciseCount;
  final String status;
  final int score;

  bool get locked => status == 'locked';
  bool get completed => status == 'completed';

  factory PathLesson.fromJson(Map<String, dynamic> j) => PathLesson(
        id: j['id'] as int,
        number: j['number'] as int,
        title: j['title'] as String,
        description: j['description'] as String?,
        skill: j['skill'] as String,
        xp: j['xp_reward'] as int,
        minutes: j['estimated_minutes'] as int,
        exerciseCount: j['exercise_count'] as int,
        status: j['status'] as String,
        score: j['score'] as int,
      );
}

class PathUnit {
  PathUnit({required this.id, required this.title, this.description, required this.lessons});
  final int id;
  final String title;
  final String? description;
  final List<PathLesson> lessons;

  factory PathUnit.fromJson(Map<String, dynamic> j) => PathUnit(
        id: j['id'] as int,
        title: j['title'] as String,
        description: j['description'] as String?,
        lessons: (j['lessons'] as List).map((l) => PathLesson.fromJson(l as Map<String, dynamic>)).toList(),
      );
}

class CourseSummary {
  CourseSummary({required this.id, required this.title, this.description, required this.level, required this.lessonCount, required this.isActive, this.flag});
  final int id;
  final String title;
  final String? description;
  final String level;
  final int lessonCount;
  final bool isActive;
  final String? flag;

  factory CourseSummary.fromJson(Map<String, dynamic> j) => CourseSummary(
        id: j['id'] as int,
        title: j['title'] as String,
        description: j['description'] as String?,
        level: j['level'] as String,
        lessonCount: j['lesson_count'] as int,
        isActive: j['is_active'] as bool,
        flag: (j['target_language'] as Map?)?['flag'] as String?,
      );
}

/// Aktif kursun öğrenme yolu; aktif kurs yoksa null.
final coursePathProvider = FutureProvider.autoDispose<({String title, String level, List<PathUnit> units})?>((ref) async {
  final user = await ref.watch(authControllerProvider.future);
  final courseId = user?.activeCourseId;
  if (courseId == null) return null;
  final data = await ref.watch(apiClientProvider).get<Map<String, dynamic>>('/courses/$courseId/path');
  final course = data['course'] as Map<String, dynamic>;
  return (
    title: course['title'] as String,
    level: course['level'] as String,
    units: (data['units'] as List).map((u) => PathUnit.fromJson(u as Map<String, dynamic>)).toList(),
  );
});

final coursesProvider = FutureProvider.autoDispose<List<CourseSummary>>((ref) async {
  final data = await ref.watch(apiClientProvider).get<List<dynamic>>('/courses');
  return data.map((c) => CourseSummary.fromJson(c as Map<String, dynamic>)).toList();
});

Future<void> enrollCourse(WidgetRef ref, int courseId) async {
  await ref.read(apiClientProvider).post('/courses/$courseId/enroll');
  await ref.read(authControllerProvider.notifier).refresh();
  ref.invalidate(coursesProvider);
}
