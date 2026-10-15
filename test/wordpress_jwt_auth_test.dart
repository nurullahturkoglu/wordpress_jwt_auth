import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:wordpress_jwt_auth/wordpress_jwt_auth.dart';

import 'helpers/mock_adapter.dart';

void main() {
  late MockAdapter adapter;
  late InMemoryTokenStorage storage;
  late WordPressJwtAuth auth;

  setUp(() {
    adapter = MockAdapter();
    storage = InMemoryTokenStorage();
    auth = WordPressJwtAuth(
      baseUrl: 'https://example.com/',
      dio: mockDio(adapter),
      storage: storage,
      registerPath: 'register',
    );
  });

  group('login', () {
    test('posts credentials, stores the token and returns the body', () async {
      final token = fakeToken(userId: '13');
      adapter.enqueueJson(200, {
        'token': token,
        'user_email': 'alice@example.com',
        'user_nicename': 'alice',
        'user_display_name': 'Alice',
      });

      final response = await auth.login(username: 'alice', password: 'secret');

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(
        request.uri.toString(),
        'https://example.com/wp-json/jwt-auth/v1/token',
      );
      expect(request.data, {'username': 'alice', 'password': 'secret'});
      expect(request.headers.containsKey('Authorization'), isFalse);
      expect(response.userDisplayName, 'Alice');
      expect(response.claims?.userId, 13);
      expect(await storage.read(), token);
    });

    test('maps a wrong password to InvalidCredentialsException', () async {
      adapter.enqueueJson(
        403,
        wpError(
          '[jwt_auth] incorrect_password',
          '<strong>Error:</strong> The password you entered for the username '
              '<strong>alice</strong> is incorrect. '
              '<a href="https://example.com/wp-login.php?action=lostpassword">'
              'Lost your password?</a>',
          403,
        ),
      );

      await expectLater(
        auth.login(username: 'alice', password: 'wrong'),
        throwsA(
          isA<InvalidCredentialsException>()
              .having((e) => e.reason, 'reason', 'incorrect_password')
              .having((e) => e.statusCode, 'statusCode', 403)
              .having(
                (e) => e.message,
                'message',
                'Error: The password you entered for the username alice is '
                    'incorrect. Lost your password?',
              ),
        ),
      );
      expect(await storage.read(), isNull);
    });

    test('maps an unknown username to InvalidCredentialsException', () async {
      adapter.enqueueJson(
        403,
        wpError('[jwt_auth] invalid_username', 'Unknown username.', 403),
      );

      await expectLater(
        auth.login(username: 'nobody', password: 'x'),
        throwsA(
          isA<InvalidCredentialsException>().having(
            (e) => e.reason,
            'reason',
            'invalid_username',
          ),
        ),
      );
    });

    test('maps a missing secret key to ServerConfigurationException', () async {
      adapter.enqueueJson(
        403,
        wpError(
          'jwt_auth_bad_config',
          'JWT is not configured properly, please contact the admin',
          403,
        ),
      );

      await expectLater(
        auth.login(username: 'alice', password: 'secret'),
        throwsA(
          isA<ServerConfigurationException>().having(
            (e) => e.code,
            'code',
            'jwt_auth_bad_config',
          ),
        ),
      );
    });

    test('maps a missing route to ServerConfigurationException', () async {
      adapter.enqueueJson(
        404,
        wpError(
          'rest_no_route',
          'No route was found matching the URL and request method.',
          404,
        ),
      );

      await expectLater(
        auth.login(username: 'alice', password: 'secret'),
        throwsA(
          isA<ServerConfigurationException>().having(
            (e) => e.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
    });

    test('wraps transport failures in NetworkException', () async {
      adapter.enqueueFailure(const FormatException('connection refused'));

      await expectLater(
        auth.login(username: 'alice', password: 'secret'),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.cause,
            'cause',
            isA<DioException>(),
          ),
        ),
      );
    });

    test('rejects a non JSON body', () async {
      adapter.enqueue((_) => htmlResponse(200, '<html>login page</html>'));

      await expectLater(
        auth.login(username: 'alice', password: 'secret'),
        throwsA(
          isA<UnexpectedResponseException>().having(
            (e) => e.statusCode,
            'statusCode',
            200,
          ),
        ),
      );
    });

    test('rejects a JSON body without token', () async {
      adapter.enqueueJson(200, {'user_email': 'alice@example.com'});

      await expectLater(
        auth.login(username: 'alice', password: 'secret'),
        throwsA(isA<UnexpectedResponseException>()),
      );
      expect(await storage.read(), isNull);
    });
  });

  group('validateToken', () {
    test('returns false without a request when nothing is stored', () async {
      expect(await auth.validateToken(), isFalse);
      expect(adapter.requests, isEmpty);
    });

    test('sends the bearer header and returns true', () async {
      await storage.write('abc');
      adapter.enqueueJson(200, {
        'code': 'jwt_auth_valid_token',
        'data': {'status': 200},
      });

      expect(await auth.validateToken(), isTrue);

      final request = adapter.requests.single;
      expect(
        request.uri.toString(),
        'https://example.com/wp-json/jwt-auth/v1/token/validate',
      );
      expect(request.headers['Authorization'], 'Bearer abc');
      expect(await storage.read(), 'abc');
    });

    test('clears the storage when the site rejects the token', () async {
      await storage.write('abc');
      adapter.enqueueJson(
        403,
        wpError('jwt_auth_invalid_token', 'Expired token', 403),
      );

      expect(await auth.validateToken(), isFalse);
      expect(await storage.read(), isNull);
    });

    test('keeps the token when the site is unreachable', () async {
      await storage.write('abc');
      adapter.enqueueFailure(const FormatException('offline'));

      await expectLater(auth.validateToken(), throwsA(isA<NetworkException>()));
      expect(await storage.read(), 'abc');
    });
  });

  group('claims', () {
    test('decodes the stored token locally', () async {
      await storage.write(fakeToken(userId: '42'));

      expect((await auth.claims())?.userId, 42);
      expect(adapter.requests, isEmpty);
    });

    test('returns null without a token', () async {
      expect(await auth.claims(), isNull);
    });
  });

  group('currentUser', () {
    test('fetches users/me with context=edit', () async {
      await storage.write('abc');
      adapter.enqueueJson(200, {
        'id': 13,
        'username': 'alice',
        'name': 'Alice',
        'slug': 'alice',
        'email': 'alice@example.com',
        'roles': ['subscriber'],
      });

      final user = await auth.currentUser();

      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(
        request.uri.toString(),
        'https://example.com/wp-json/wp/v2/users/me?context=edit',
      );
      expect(request.headers['Authorization'], 'Bearer abc');
      expect(user.id, 13);
      expect(user.roles, ['subscriber']);
    });

    test('throws InvalidTokenException without a token', () async {
      await expectLater(
        auth.currentUser(),
        throwsA(isA<InvalidTokenException>()),
      );
      expect(adapter.requests, isEmpty);
    });

    test('maps rest_not_logged_in to InvalidTokenException', () async {
      await storage.write('abc');
      adapter.enqueueJson(
        401,
        wpError('rest_not_logged_in', 'You are not currently logged in.', 401),
      );

      await expectLater(
        auth.currentUser(),
        throwsA(
          isA<InvalidTokenException>().having(
            (e) => e.isExpired,
            'isExpired',
            isFalse,
          ),
        ),
      );
    });

    test('flags an expired token', () async {
      await storage.write('abc');
      adapter.enqueueJson(
        403,
        wpError('jwt_auth_invalid_token', 'Expired token', 403),
      );

      await expectLater(
        auth.currentUser(),
        throwsA(
          isA<InvalidTokenException>().having(
            (e) => e.isExpired,
            'isExpired',
            isTrue,
          ),
        ),
      );
    });
  });

  group('register', () {
    test('throws StateError when no path is configured', () async {
      final noRegister = WordPressJwtAuth(
        baseUrl: 'https://example.com',
        dio: mockDio(adapter),
      );

      await expectLater(
        noRegister.register(username: 'a', email: 'a@b.c', password: 'p'),
        throwsStateError,
      );
      expect(adapter.requests, isEmpty);
    });

    test('posts to the configured path and parses the result', () async {
      adapter.enqueueJson(201, {
        'id': 20,
        'username': 'carol',
        'email': 'carol@example.com',
      });

      final result = await auth.register(
        username: 'carol',
        email: 'carol@example.com',
        password: 'secret',
      );

      final request = adapter.requests.single;
      expect(
        request.uri.toString(),
        'https://example.com/wp-json/jwt-auth/v1/register',
      );
      expect(request.data, {
        'username': 'carol',
        'email': 'carol@example.com',
        'password': 'secret',
      });
      expect(result.id, 20);
    });

    test('maps WordPress user errors to RegistrationException', () async {
      adapter.enqueueJson(
        400,
        wpError(
          'existing_user_login',
          'Sorry, that username already exists!',
          400,
        ),
      );

      await expectLater(
        auth.register(username: 'alice', email: 'a@b.c', password: 'p'),
        throwsA(
          isA<RegistrationException>().having(
            (e) => e.code,
            'code',
            'existing_user_login',
          ),
        ),
      );
    });

    test('keeps configuration errors typed', () async {
      adapter.enqueueJson(
        404,
        wpError('rest_no_route', 'No route was found', 404),
      );

      await expectLater(
        auth.register(username: 'alice', email: 'a@b.c', password: 'p'),
        throwsA(isA<ServerConfigurationException>()),
      );
    });
  });

  test('logout clears the storage', () async {
    await storage.write('abc');

    await auth.logout();

    expect(await storage.read(), isNull);
  });

  test('stripHtml removes tags and decodes entities', () {
    expect(
      WordPressJwtAuth.stripHtml(
        '<strong>Error:</strong>&nbsp;Tom&#039;s &amp; Jerry&#8217;s <a href="#">link</a>',
      ),
      'Error: Tom\'s & Jerry’s link',
    );
  });
}
