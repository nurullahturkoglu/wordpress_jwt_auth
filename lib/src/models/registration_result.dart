/// Body of a successful call to the register endpoint shipped in
/// `wordpress/jwt-auth-register.php`.
class RegistrationResult {
  /// Creates a result from already parsed values.
  const RegistrationResult({
    required this.id,
    required this.username,
    required this.email,
  });

  /// Parses the endpoint's JSON body. Throws [FormatException] when `id` is
  /// missing.
  factory RegistrationResult.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int) {
      throw const FormatException('Response has no user id');
    }
    return RegistrationResult(
      id: id,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  /// ID of the new user.
  final int id;

  /// Login name of the new user.
  final String username;

  /// Email of the new user.
  final String email;
}
