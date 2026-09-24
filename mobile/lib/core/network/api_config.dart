import 'package:flutter/foundation.dart';

/// API adresi `--dart-define=API_URL=...` ile verilir.
/// Verilmezse: Android emülatörde 10.0.2.2, diğerlerinde 127.0.0.1.
abstract final class ApiConfig {
  static const _fromEnv = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_fromEnv.isNotEmpty) return _fromEnv;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://127.0.0.1:8000/api/v1';
  }
}
