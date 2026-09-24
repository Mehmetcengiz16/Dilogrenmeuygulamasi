import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/token_storage.dart';
import 'api_config.dart';
import 'api_exception.dart';

/// 401 geldiğinde oturumu kapatmak için auth katmanı bu sinyali dinler.
final unauthorizedSignalProvider = NotifierProvider<UnauthorizedSignal, int>(UnauthorizedSignal.new);

class UnauthorizedSignal extends Notifier<int> {
  @override
  int build() => 0;
  void fire() => state++;
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 60),
    headers: {'Accept': 'application/json', 'Accept-Language': 'tr'},
  ));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.read();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    },
    onError: (e, handler) async {
      if (e.response?.statusCode == 401 && !e.requestOptions.path.startsWith('/auth/')) {
        await storage.clear();
        ref.read(unauthorizedSignalProvider.notifier).fire();
      }
      handler.next(e);
    },
  ));
  return ApiClient(dio);
});

/// Standart yanıt formatını ({success, message, data, meta}) açar ve hataları ApiException'a çevirir.
class ApiClient {
  ApiClient(this._dio);
  final Dio _dio;

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: query));

  Future<T> post<T>(String path, {Object? data}) => _send(() => _dio.post(path, data: data));

  Future<T> put<T>(String path, {Object? data}) => _send(() => _dio.put(path, data: data));

  Future<T> delete<T>(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.delete(path, queryParameters: query));

  Future<T> _send<T>(Future<Response> Function() request) async {
    try {
      final res = await request();
      return (res.data as Map<String, dynamic>)['data'] as T;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
