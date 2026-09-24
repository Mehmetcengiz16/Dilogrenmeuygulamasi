import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import 'app_user.dart';

final onboardingSeenProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_seen') ?? false;
});

Future<void> markOnboardingSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding_seen', true);
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AppUser?>(AuthController.new);

/// Oturum durumu: null = giriş yapılmamış. Uygulama açılışında token varsa /me ile doğrulanır.
class AuthController extends AsyncNotifier<AppUser?> {
  ApiClient get _api => ref.read(apiClientProvider);
  TokenStorage get _tokens => ref.read(tokenStorageProvider);

  @override
  Future<AppUser?> build() async {
    ref.listen(unauthorizedSignalProvider, (_, _) => state = const AsyncData(null));

    final token = await _tokens.read();
    if (token == null) return null;
    try {
      return await _fetchMe();
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await _tokens.clear();
        return null;
      }
      rethrow;
    }
  }

  Future<AppUser> _fetchMe() async {
    final data = await _api.get<Map<String, dynamic>>('/me');
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> login(String email, String password) async {
    final data = await _api.post<Map<String, dynamic>>('/auth/login', data: {'email': email, 'password': password});
    await _onToken(data);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required int dailyGoalMinutes,
  }) async {
    final data = await _api.post<Map<String, dynamic>>('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': password,
      'daily_goal_minutes': dailyGoalMinutes,
    });
    await _onToken(data);
  }

  Future<void> _onToken(Map<String, dynamic> data) async {
    await _tokens.write(data['token'] as String);
    state = AsyncData(AppUser.fromJson(data['user'] as Map<String, dynamic>));
  }

  /// Ders bitince / profil değişince üst bilgideki XP ve seriyi tazeler.
  Future<void> refresh() async {
    try {
      state = AsyncData(await _fetchMe());
    } on ApiException {
      // Sessizce yoksay; mevcut durum korunur.
    }
  }

  Future<void> updateProfile({String? name, int? dailyGoalMinutes}) async {
    final data = await _api.put<Map<String, dynamic>>('/me', data: {
      'name': ?name,
      'daily_goal_minutes': ?dailyGoalMinutes,
    });
    state = AsyncData(AppUser.fromJson(data));
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } on ApiException {
      // Token zaten geçersizse sorun değil.
    }
    await _tokens.clear();
    state = const AsyncData(null);
  }

  Future<void> deleteAccount() async {
    await _api.delete('/me');
    await _tokens.clear();
    state = const AsyncData(null);
  }
}
