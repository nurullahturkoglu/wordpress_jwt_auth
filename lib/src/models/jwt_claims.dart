import 'dart:convert';

/// The payload of a token issued by the plugin.
///
/// Decoding only reads the claims; the signature is not verified. Use it to
/// check expiry locally or to read the user ID without a network call.
class JwtClaims {
  /// Creates claims from already decoded values.
  const JwtClaims({
    required this.issuer,
    required this.issuedAt,
    required this.notBefore,
    required this.expiresAt,
    required this.userId,
    required this.raw,
  });

  /// Decodes the payload of [token]. Throws [FormatException] when the token
  /// is not a three part JWT with a JSON payload.
  factory JwtClaims.decode(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw const FormatException('Token must have three dot separated parts');
    }
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Token payload is not a JSON object');
    }
    final user = (decoded['data'] as Map<String, dynamic>?)?['user'];
    return JwtClaims(
      issuer: decoded['iss'] as String?,
      issuedAt: _date(decoded['iat']),
      notBefore: _date(decoded['nbf']),
      expiresAt: _date(decoded['exp']),
      userId: _int((user as Map<String, dynamic>?)?['id']),
      raw: decoded,
    );
  }

  /// Like [JwtClaims.decode] but returns `null` instead of throwing.
  static JwtClaims? tryDecode(String token) {
    try {
      return JwtClaims.decode(token);
    } on FormatException {
      return null;
    }
  }

  /// The `iss` claim, the site URL that signed the token.
  final String? issuer;

  /// The `iat` claim.
  final DateTime? issuedAt;

  /// The `nbf` claim.
  final DateTime? notBefore;

  /// The `exp` claim. The plugin defaults to seven days after issue.
  final DateTime? expiresAt;

  /// The WordPress user ID stored under `data.user.id`.
  final int? userId;

  /// The full decoded payload.
  final Map<String, dynamic> raw;

  /// Whether [expiresAt] is in the past. Tokens without `exp` never expire.
  bool get isExpired {
    final exp = expiresAt;
    return exp != null && DateTime.now().toUtc().isAfter(exp);
  }

  static DateTime? _date(Object? seconds) {
    final value = _int(seconds);
    if (value == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
  }

  static int? _int(Object? value) => switch (value) {
    int v => v,
    num v => v.toInt(),
    String v => int.tryParse(v),
    _ => null,
  };
}
