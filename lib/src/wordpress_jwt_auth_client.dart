import 'package:dio/dio.dart';

import 'exceptions.dart';
import 'models/jwt_claims.dart';
import 'models/registration_result.dart';
import 'models/token_response.dart';
import 'models/wordpress_user.dart';
import 'token_storage.dart';

/// Client for the JWT Authentication for WP REST API plugin.
///
/// ```dart
/// final auth = WordPressJwtAuth(baseUrl: 'https://example.com');
/// final response = await auth.login(username: 'alice', password: 'secret');
/// final user = await auth.currentUser();
/// ```
///
/// Every method throws a subclass of [JwtAuthException] on failure.
class WordPressJwtAuth {
  /// Creates a client for the site at [baseUrl], for example
  /// `https://example.com`. A trailing slash is ignored.
  ///
  /// Pass [dio] to reuse an existing instance; its base URL is not used.
  /// [storage] defaults to [InMemoryTokenStorage]. [registerPath] is the path
  /// under the plugin namespace of a register endpoint; the plugin itself has
  /// none, see `wordpress/jwt-auth-register.php`.
  WordPressJwtAuth({
    required String baseUrl,
    Dio? dio,
    TokenStorage? storage,
    this.registerPath,
  }) : baseUrl = baseUrl.endsWith('/')
           ? baseUrl.substring(0, baseUrl.length - 1)
           : baseUrl,
       storage = storage ?? InMemoryTokenStorage(),
       _dio = dio ?? Dio();

  /// REST namespace registered by the plugin.
  static const namespace = 'jwt-auth/v1';

  /// Site URL without a trailing slash.
  final String baseUrl;

  /// Where the token is kept between calls.
  final TokenStorage storage;

  /// Path of the register endpoint relative to [namespace], or `null` when
  /// the site has no such endpoint.
  final String? registerPath;

  final Dio _dio;

  /// Exchanges [username] and [password] for a token and stores it.
  ///
  /// Throws [InvalidCredentialsException] when WordPress rejects the login.
  Future<TokenResponse> login({
    required String username,
    required String password,
  }) async {
    final body = await _send(
      'POST',
      '$namespace/token',
      data: {'username': username, 'password': password},
    );
    final response = _parse(body, TokenResponse.fromJson);
    await storage.write(response.token);
    return response;
  }

  /// Asks the site whether the stored token is still valid.
  ///
  /// Returns `false` and clears the storage when there is no token or the site
  /// rejects it. Throws [NetworkException] when the site cannot be reached, so
  /// an offline app can decide to keep its session.
  Future<bool> validateToken() async {
    final token = await storage.read();
    if (token == null) return false;
    try {
      await _send('POST', '$namespace/token/validate', token: token);
      return true;
    } on InvalidTokenException {
      await storage.delete();
      return false;
    }
  }

  /// Decoded claims of the stored token, or `null` when there is no token or
  /// it cannot be decoded. Does not contact the site.
  Future<JwtClaims?> claims() async {
    final token = await storage.read();
    return token == null ? null : JwtClaims.tryDecode(token);
  }

  /// Fetches the user that owns the stored token from
  /// `GET /wp-json/wp/v2/users/me?context=edit`.
  ///
  /// Throws [InvalidTokenException] when there is no token or the site rejects
  /// it.
  Future<WordPressUser> currentUser() async {
    final token = await storage.read();
    if (token == null) {
      throw const InvalidTokenException(
        code: 'jwt_auth_no_auth_header',
        message: 'No token stored.',
      );
    }
    final body = await _send(
      'GET',
      'wp/v2/users/me',
      query: {'context': 'edit'},
      token: token,
    );
    return _parse(body, WordPressUser.fromJson);
  }

  /// Creates a user through the endpoint at [registerPath].
  ///
  /// Throws [StateError] when [registerPath] is `null` and
  /// [RegistrationException] when the endpoint rejects the request.
  Future<RegistrationResult> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final path = registerPath;
    if (path == null) {
      throw StateError(
        'No register endpoint configured. The plugin has none; install '
        'wordpress/jwt-auth-register.php and pass registerPath to the client.',
      );
    }
    final body = await _send(
      'POST',
      '$namespace/$path',
      data: {'username': username, 'email': email, 'password': password},
      mapError: _registrationError,
    );
    return _parse(body, RegistrationResult.fromJson);
  }

  /// Forgets the stored token. The plugin cannot revoke tokens, so the token
  /// stays valid on the site until it expires.
  Future<void> logout() => storage.delete();

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    String? token,
    JwtAuthException Function(String code, String message, int? status)?
    mapError,
  }) async {
    final Response<dynamic> response;
    try {
      response = await _dio.request<dynamic>(
        '$baseUrl/wp-json/$path',
        data: data,
        queryParameters: query,
        options: Options(
          method: method,
          responseType: ResponseType.json,
          validateStatus: (_) => true,
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (e) {
      throw NetworkException(message: e.message ?? e.type.name, cause: e);
    }

    final status = response.statusCode;
    final body = response.data;
    if (body is Map<String, dynamic>) {
      final code = body['code'];
      if (code is String && body.containsKey('message')) {
        final message = stripHtml(body['message']?.toString() ?? '');
        throw (mapError ?? _defaultError)(code, message, status);
      }
      if (status != null && status >= 200 && status < 300) {
        return body;
      }
    }
    throw UnexpectedResponseException(
      code: 'unexpected_response',
      message: 'Unexpected response with status $status',
      statusCode: status,
      body: body,
    );
  }

  T _parse<T>(
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      return fromJson(body);
    } on FormatException catch (e) {
      throw UnexpectedResponseException(
        code: 'unexpected_response',
        message: e.message,
        body: body,
      );
    }
  }

  static JwtAuthException _defaultError(
    String code,
    String message,
    int? status,
  ) {
    if (code.startsWith('[jwt_auth] ') || code == 'jwt_auth_failed') {
      return InvalidCredentialsException(
        code: code,
        message: message,
        statusCode: status,
      );
    }
    return switch (code) {
      'jwt_auth_invalid_token' ||
      'jwt_auth_bad_iss' ||
      'jwt_auth_bad_request' ||
      'jwt_auth_no_auth_header' ||
      'jwt_auth_bad_auth_header' ||
      'rest_not_logged_in' ||
      'rest_forbidden' => InvalidTokenException(
        code: code,
        message: message,
        statusCode: status,
      ),
      'jwt_auth_bad_config' ||
      'jwt_auth_unsupported_algorithm' ||
      'rest_no_route' => ServerConfigurationException(
        code: code,
        message: message,
        statusCode: status,
      ),
      _ => UnexpectedResponseException(
        code: code,
        message: message,
        statusCode: status,
      ),
    };
  }

  static JwtAuthException _registrationError(
    String code,
    String message,
    int? status,
  ) {
    final mapped = _defaultError(code, message, status);
    if (mapped is ServerConfigurationException) return mapped;
    return RegistrationException(
      code: code,
      message: message,
      statusCode: status,
    );
  }

  /// Removes HTML tags and decodes common entities from a WordPress message.
  ///
  /// Login errors come straight from WordPress and contain markup such as
  /// `<strong>Error:</strong>` and a "Lost your password?" link.
  static String stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&#8217;', '’')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
