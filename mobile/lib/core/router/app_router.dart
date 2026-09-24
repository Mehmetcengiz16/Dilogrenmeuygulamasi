import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_controller.dart';
import '../../features/auth/presentation/auth_screens.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/lesson/presentation/lesson_screen.dart';
import '../../features/practice/presentation/practice_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/translate/presentation/translate_screen.dart';
import '../../features/vocabulary/vocabulary_screen.dart';
import '../widgets/app_logo.dart';
import '../widgets/shell_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // Oturum veya tanıtım durumu değişince yönlendirme yeniden değerlendirilir.
  final refresh = ValueNotifier(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.listen(onboardingSeenProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  const publicRoutes = {'/onboarding', '/login', '/register'};

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final seen = ref.read(onboardingSeenProvider);
      if (auth.isLoading || seen.isLoading) return '/splash';

      final loggedIn = auth.value != null;
      final loc = state.matchedLocation;
      if (!loggedIn) {
        if (publicRoutes.contains(loc)) return null;
        return seen.value == true ? '/login' : '/onboarding';
      }
      if (publicRoutes.contains(loc) || loc == '/splash') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const _Splash()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/lesson/:id',
        builder: (_, s) => LessonScreen(lessonId: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(path: '/vocabulary', builder: (_, _) => const VocabularyScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ShellScaffold(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/practice', builder: (_, _) => const PracticeScreen())]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/chat',
              builder: (_, s) => ChatScreen(scenarioId: int.tryParse(s.uri.queryParameters['scenario'] ?? '')),
            ),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/translate', builder: (_, _) => const TranslateScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen())]),
        ],
      ),
    ],
  );
});

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: AppLogo(size: 56, showName: false)));
  }
}
