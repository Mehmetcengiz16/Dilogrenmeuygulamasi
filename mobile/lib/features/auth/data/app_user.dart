class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.dailyGoalMinutes,
    required this.totalXp,
    required this.currentStreak,
    required this.longestStreak,
    this.avatarUrl,
    this.activeCourseId,
    this.activeCourseTitle,
    this.activeCourseLevel,
  });

  final int id;
  final String name;
  final String email;
  final String? avatarUrl;
  final int dailyGoalMinutes;
  final int totalXp;
  final int currentStreak;
  final int longestStreak;
  final int? activeCourseId;
  final String? activeCourseTitle;
  final String? activeCourseLevel;

  factory AppUser.fromJson(Map<String, dynamic> j) {
    final course = j['active_course'] as Map<String, dynamic>?;
    return AppUser(
      id: j['id'] as int,
      name: j['name'] as String,
      email: j['email'] as String,
      avatarUrl: j['avatar_url'] as String?,
      dailyGoalMinutes: j['daily_goal_minutes'] as int? ?? 15,
      totalXp: j['total_xp'] as int? ?? 0,
      currentStreak: j['current_streak'] as int? ?? 0,
      longestStreak: j['longest_streak'] as int? ?? 0,
      activeCourseId: course?['id'] as int?,
      activeCourseTitle: course?['title'] as String?,
      activeCourseLevel: course?['level'] as String?,
    );
  }
}
