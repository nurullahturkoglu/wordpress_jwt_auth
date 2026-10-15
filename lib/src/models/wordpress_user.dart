/// A user as returned by `GET /wp-json/wp/v2/users/me?context=edit`.
class WordPressUser {
  /// Creates a user from already parsed values.
  const WordPressUser({
    required this.id,
    required this.name,
    required this.slug,
    required this.username,
    required this.email,
    required this.roles,
    required this.raw,
  });

  /// Parses the WordPress REST user object. Throws [FormatException] when
  /// `id` is missing.
  factory WordPressUser.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int) {
      throw const FormatException('User has no id');
    }
    final roles = json['roles'];
    return WordPressUser(
      id: id,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      username: json['username'] as String?,
      email: json['email'] as String?,
      roles: roles is List ? roles.whereType<String>().toList() : const [],
      raw: json,
    );
  }

  /// WordPress user ID.
  final int id;

  /// Display name.
  final String name;

  /// URL friendly username.
  final String slug;

  /// Login name. Only present with `context=edit`.
  final String? username;

  /// Email address. Only present with `context=edit`.
  final String? email;

  /// Roles such as `subscriber`. Only present with `context=edit`.
  final List<String> roles;

  /// The full user object.
  final Map<String, dynamic> raw;
}
