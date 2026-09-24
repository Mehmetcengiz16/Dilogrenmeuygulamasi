import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.errors = const {}});

  final String message;
  final int? statusCode;
  final Map<String, List<String>> errors;

  bool get isUnauthorized => statusCode == 401;

  /// Form alanı hatasını döner (422).
  String? fieldError(String field) => errors[field]?.first;

  factory ApiException.fromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      final raw = data['errors'];
      final errors = <String, List<String>>{};
      if (raw is Map) {
        raw.forEach((k, v) => errors[k.toString()] = (v as List).map((x) => x.toString()).toList());
      }
      return ApiException(data['message'] as String, statusCode: e.response?.statusCode, errors: errors);
    }
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError =>
        ApiException('Sunucuya ulaşılamıyor. İnternet bağlantını kontrol et.'),
      _ => ApiException('Beklenmeyen bir hata oluştu.', statusCode: e.response?.statusCode),
    };
  }

  @override
  String toString() => message;
}
