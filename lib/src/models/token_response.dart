import 'jwt_claims.dart';

/// Body of a successful `POST /wp-json/jwt-auth/v1/token` call.
class TokenResponse {
  /// Creates a response from already parsed values.
  const TokenResponse({
    required this.token,
    required this.userEmail,
    required this.userNicename,
    required this.userDisplayName,
    required this.raw,
  });

  /// Parses the plugin's JSON body. Throws [FormatException] when `token` is
  /// missing.
  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    final token = json['token'];
    if (token is! String || token.isEmpty) {
      throw const FormatException('Response has no token');
    }
    return TokenResponse(
      token: token,
      userEmail: json['user_email'] as String?,
      userNicename: json['user_nicename'] as String?,
      userDisplayName: json['user_display_name'] as String?,
      raw: json,
    );
  }

  /// The signed JWT.
  final String token;

  /// `user_email` from the response.
  final String? userEmail;

  /// `user_nicename` from the response, the URL friendly username.
  final String? userNicename;

  /// `user_display_name` from the response.
  final String? userDisplayName;

  /// The full body, including any fields a site adds through the
  /// `jwt_auth_token_before_dispatch` filter.
  final Map<String, dynamic> raw;

  /// Decoded claims of [token], or `null` when the token cannot be decoded.
  JwtClaims? get claims => JwtClaims.tryDecode(token);
}
