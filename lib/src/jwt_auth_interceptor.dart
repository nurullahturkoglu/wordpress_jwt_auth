import 'package:dio/dio.dart';

import 'token_storage.dart';

/// Adds `Authorization: Bearer <token>` to every request when a token is
/// stored. Requests that already carry an `Authorization` header are left
/// alone.
///
/// ```dart
/// final dio = Dio(BaseOptions(baseUrl: 'https://example.com/wp-json/'))
///   ..interceptors.add(JwtAuthInterceptor(storage));
/// ```
class JwtAuthInterceptor extends Interceptor {
  /// Creates an interceptor that reads tokens from [storage].
  JwtAuthInterceptor(this.storage);

  /// Where the token is read from.
  final TokenStorage storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!options.headers.containsKey('Authorization')) {
      final token = await storage.read();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
}
