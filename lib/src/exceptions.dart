/// Base class for every error raised by this package.
///
/// The hierarchy is sealed, so a `switch` over it can be exhaustive.
sealed class JwtAuthException implements Exception {
  const JwtAuthException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  /// WordPress error code, for example `jwt_auth_invalid_token`.
  final String code;

  /// Human readable message with HTML tags removed.
  final String message;

  /// HTTP status of the response, when there was one.
  final int? statusCode;

  @override
  String toString() => '$runtimeType($code, $statusCode): $message';
}

/// The username or password was rejected by WordPress.
///
/// The plugin prefixes the WordPress login error code with `[jwt_auth] `;
/// [reason] holds the part after the prefix, such as `incorrect_password`,
/// `invalid_username`, `empty_username` or `empty_password`.
final class InvalidCredentialsException extends JwtAuthException {
  /// Creates the exception from a WordPress error response.
  const InvalidCredentialsException({
    required super.code,
    required super.message,
    super.statusCode,
  });

  /// The WordPress login error code without the `[jwt_auth] ` prefix.
  String get reason =>
      code.startsWith(_prefix) ? code.substring(_prefix.length) : code;

  static const _prefix = '[jwt_auth] ';
}

/// The stored token was missing, malformed, expired or rejected by the site.
final class InvalidTokenException extends JwtAuthException {
  /// Creates the exception from a WordPress error response.
  const InvalidTokenException({
    required super.code,
    required super.message,
    super.statusCode,
  });

  /// Whether the site reported the token as expired.
  bool get isExpired => message.toLowerCase().contains('expired');
}

/// The site is not set up for JWT authentication.
///
/// Raised when `JWT_AUTH_SECRET_KEY` is missing, the signing algorithm is not
/// supported, or the endpoint does not exist (plugin inactive or permalinks
/// disabled).
final class ServerConfigurationException extends JwtAuthException {
  /// Creates the exception from a WordPress error response.
  const ServerConfigurationException({
    required super.code,
    required super.message,
    super.statusCode,
  });
}

/// The registration endpoint rejected the request.
///
/// [code] is the WordPress error code, for example `existing_user_login`,
/// `existing_user_email`, `invalid_username`, `jwt_auth_invalid_email` or
/// `jwt_auth_registration_disabled`.
final class RegistrationException extends JwtAuthException {
  /// Creates the exception from a WordPress error response.
  const RegistrationException({
    required super.code,
    required super.message,
    super.statusCode,
  });
}

/// The request never reached the site or no response came back.
final class NetworkException extends JwtAuthException {
  /// Wraps the underlying transport error.
  const NetworkException({required super.message, required this.cause})
    : super(code: 'network_error');

  /// The original error, usually a `DioException`.
  final Object cause;
}

/// The site answered with something this package does not understand.
final class UnexpectedResponseException extends JwtAuthException {
  /// Creates the exception with the raw response body.
  const UnexpectedResponseException({
    required super.code,
    required super.message,
    super.statusCode,
    this.body,
  });

  /// The decoded response body, if any.
  final Object? body;
}
