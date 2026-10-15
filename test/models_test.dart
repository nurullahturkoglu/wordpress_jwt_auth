import 'package:test/test.dart';
import 'package:wordpress_jwt_auth/wordpress_jwt_auth.dart';

import 'helpers/mock_adapter.dart';

void main() {
  group('TokenResponse', () {
    test('parses the plugin body and keeps extra fields', () {
      final token = fakeToken(userId: '13');
      final response = TokenResponse.fromJson({
        'token': token,
        'user_email': 'alice@example.com',
        'user_nicename': 'alice',
        'user_display_name': 'Alice',
        'user_role': 'subscriber',
      });

      expect(response.token, token);
      expect(response.userEmail, 'alice@example.com');
      expect(response.userNicename, 'alice');
      expect(response.userDisplayName, 'Alice');
      expect(response.raw['user_role'], 'subscriber');
      expect(response.claims?.userId, 13);
    });

    test('rejects a body without token', () {
      expect(
        () => TokenResponse.fromJson({'user_email': 'x'}),
        throwsFormatException,
      );
      expect(
        () => TokenResponse.fromJson({'token': ''}),
        throwsFormatException,
      );
    });
  });

  group('WordPressUser', () {
    test('parses the edit context fields', () {
      final user = WordPressUser.fromJson({
        'id': 13,
        'username': 'alice',
        'name': 'Alice',
        'slug': 'alice',
        'email': 'alice@example.com',
        'roles': ['subscriber', 'editor'],
      });

      expect(user.id, 13);
      expect(user.username, 'alice');
      expect(user.roles, ['subscriber', 'editor']);
    });

    test('tolerates the view context', () {
      final user = WordPressUser.fromJson({
        'id': 2,
        'name': 'Bob',
        'slug': 'bob',
      });

      expect(user.username, isNull);
      expect(user.email, isNull);
      expect(user.roles, isEmpty);
    });

    test('rejects a body without id', () {
      expect(
        () => WordPressUser.fromJson({'name': 'x'}),
        throwsFormatException,
      );
    });
  });

  group('RegistrationResult', () {
    test('parses the register endpoint body', () {
      final result = RegistrationResult.fromJson({
        'id': 20,
        'username': 'carol',
        'email': 'carol@example.com',
      });

      expect(result.id, 20);
      expect(result.username, 'carol');
    });

    test('rejects a body without id', () {
      expect(() => RegistrationResult.fromJson({}), throwsFormatException);
    });
  });
}
