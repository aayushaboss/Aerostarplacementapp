import 'package:dio/dio.dart';

import 'data_config.dart';

/// Typed wrapper around whatever dio hands back on a failed request — every
/// Http*Repository should catch dio's own DioException and rethrow as this,
/// so screens/AppState only ever need to handle one exception shape
/// regardless of which repository (or eventually which real endpoint)
/// raised it.
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final String? code;

  const ApiException({required this.message, this.statusCode, this.code});

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}

/// Thin dio wrapper shared by every Http*Repository. Not exercised by
/// anything yet — DataConfig.mode defaults to mock, and every
/// Http*Repository method currently throws UnimplementedError rather than
/// actually calling through this — but the base URL/auth-header/error-
/// mapping plumbing is real and ready for whichever repository is filled in
/// first once a backend exists. See BACKEND_API_CONTRACT.md.
class ApiClient {
  final Dio _dio;
  String? _authToken;

  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: DataConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _authToken;
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (error, handler) {
        handler.reject(DioException(
          requestOptions: error.requestOptions,
          error: ApiException(
            message: error.message ?? 'Request failed',
            statusCode: error.response?.statusCode,
            code: error.response?.data is Map ? (error.response?.data as Map)['code'] as String? : null,
          ),
        ));
      },
    ));
  }

  void setAuthToken(String? token) => _authToken = token;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) => _dio.get<T>(path, queryParameters: query);
  Future<Response<T>> post<T>(String path, {Object? data}) => _dio.post<T>(path, data: data);
  Future<Response<T>> put<T>(String path, {Object? data}) => _dio.put<T>(path, data: data);
  Future<Response<T>> delete<T>(String path) => _dio.delete<T>(path);
}
