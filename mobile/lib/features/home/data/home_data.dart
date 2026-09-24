import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

final homeProvider = FutureProvider.autoDispose<HomeData>((ref) async {
  final data = await ref.watch(apiClientProvider).get<Map<String, dynamic>>('/home');
  return HomeData.fromJson(data);
});

class HomeData {
  HomeData({
    required this.streak,
    required this.courseId,
    required this.level,
    required this.targetLanguage,
    required this.goalPercent,
    required this.remainingMinutes,
    required this.totalHours,
    required this.hoursChangePercent,
    required this.courseCompleted,
    required this.courseTotal,
    required this.week,
    required this.currentLesson,
    required this.scenario,
    required this.wordOfDay,
    required this.tip,
  });

  final int streak;
  final int? courseId;
  final String? level;
  final String? targetLanguage;
  final int goalPercent;
  final int remainingMinutes;
  final double totalHours;
  final int? hoursChangePercent;
  final int courseCompleted;
  final int courseTotal;
  final List<WeekDay> week;
  final CurrentLesson? currentLesson;
  final FeaturedScenario? scenario;
  final ({int id, String word, String translation})? wordOfDay;
  final String? tip;

  factory HomeData.fromJson(Map<String, dynamic> j) {
    final course = j['course'] as Map<String, dynamic>?;
    final goal = j['daily_goal'] as Map<String, dynamic>;
    final m = j['metrics'] as Map<String, dynamic>;
    final lesson = j['current_lesson'] as Map<String, dynamic>?;
    final sc = j['featured_scenario'] as Map<String, dynamic>?;
    final w = j['word_of_day'] as Map<String, dynamic>?;
    return HomeData(
      streak: (j['user'] as Map)['streak'] as int? ?? 0,
      courseId: course?['id'] as int?,
      level: course?['level'] as String?,
      targetLanguage: course?['target_language'] as String?,
      goalPercent: goal['percent'] as int,
      remainingMinutes: goal['remaining_minutes'] as int,
      totalHours: (m['total_hours'] as num).toDouble(),
      hoursChangePercent: m['hours_change_percent'] as int?,
      courseCompleted: m['course_completed'] as int,
      courseTotal: m['course_total'] as int,
      week: (j['week'] as List).map((d) => WeekDay.fromJson(d as Map<String, dynamic>)).toList(),
      currentLesson: lesson == null ? null : CurrentLesson.fromJson(lesson),
      scenario: sc == null ? null : FeaturedScenario.fromJson(sc),
      wordOfDay: w == null ? null : (id: w['id'] as int, word: w['word'] as String, translation: w['translation'] as String),
      tip: j['tip'] as String?,
    );
  }
}

class WeekDay {
  WeekDay(this.label, this.done, this.isToday);
  final String label;
  final bool done;
  final bool isToday;

  factory WeekDay.fromJson(Map<String, dynamic> j) =>
      WeekDay(j['label'] as String, j['done'] as bool, j['is_today'] as bool);
}

class CurrentLesson {
  CurrentLesson({required this.id, required this.number, required this.title, this.description, required this.skill, required this.minutes});
  final int id;
  final int? number;
  final String title;
  final String? description;
  final String skill;
  final int minutes;

  factory CurrentLesson.fromJson(Map<String, dynamic> j) => CurrentLesson(
        id: j['id'] as int,
        number: j['number'] as int?,
        title: j['title'] as String,
        description: j['description'] as String?,
        skill: j['skill'] as String,
        minutes: j['estimated_minutes'] as int,
      );
}

class FeaturedScenario {
  FeaturedScenario({required this.id, required this.title, this.description, required this.minutes, required this.icon});
  final int id;
  final String title;
  final String? description;
  final int minutes;
  final String icon;

  factory FeaturedScenario.fromJson(Map<String, dynamic> j) => FeaturedScenario(
        id: j['id'] as int,
        title: j['title'] as String,
        description: j['description'] as String?,
        minutes: j['estimated_minutes'] as int,
        icon: j['icon'] as String? ?? 'forum',
      );
}
