/// Where the client keeps the JWT between calls.
///
/// Implement this with `flutter_secure_storage` or any other backend. The
/// `example/` app ships a secure storage implementation.
abstract interface class TokenStorage {
  /// Returns the stored token, or `null` when there is none.
  Future<String?> read();

  /// Replaces the stored token.
  Future<void> write(String token);

  /// Removes the stored token.
  Future<void> delete();
}

/// Keeps the token in memory only. Useful for tests and short-lived scripts.
class InMemoryTokenStorage implements TokenStorage {
  /// Creates an empty storage, or one pre-filled with [token].
  InMemoryTokenStorage([this._token]);

  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> delete() async => _token = null;
}
