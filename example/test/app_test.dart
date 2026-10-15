import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordpress_jwt_auth/wordpress_jwt_auth.dart';
import 'package:wordpress_jwt_auth_example/constants/app_strings.dart';
import 'package:wordpress_jwt_auth_example/main.dart';

import 'helpers/mock_adapter.dart';

const validToken = {
  'code': 'jwt_auth_valid_token',
  'data': {'status': 200},
};

void main() {
  late MockAdapter adapter;
  late InMemoryTokenStorage storage;

  setUp(() {
    adapter = MockAdapter();
    storage = InMemoryTokenStorage();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MyApp(
        auth: WordPressJwtAuth(
          baseUrl: 'https://example.com',
          dio: mockDio(adapter),
          storage: storage,
          registerPath: 'register',
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AuthGate', () {
    testWidgets('shows the login page when no token is stored', (tester) async {
      await pumpApp(tester);

      expect(find.text(AppStrings.signInTitle), findsOneWidget);
      expect(adapter.requests, isEmpty);
    });

    testWidgets('shows the home page when the site accepts the token', (
      tester,
    ) async {
      await storage.write(fakeToken());
      adapter.enqueueJson(200, validToken);

      await pumpApp(tester);

      expect(find.text(AppStrings.welcomeLoggedIn), findsOneWidget);
    });

    testWidgets('drops an expired token without asking the site', (
      tester,
    ) async {
      final past = DateTime.now().millisecondsSinceEpoch ~/ 1000 - 60;
      await storage.write(fakeToken(exp: past));

      await pumpApp(tester);

      expect(find.text(AppStrings.signInTitle), findsOneWidget);
      expect(adapter.requests, isEmpty);
      expect(await storage.read(), isNull);
    });

    testWidgets('goes to login and clears the token when the site rejects it', (
      tester,
    ) async {
      await storage.write(fakeToken());
      adapter.enqueueJson(
        403,
        wpError('jwt_auth_invalid_token', 'Expired token', 403),
      );

      await pumpApp(tester);

      expect(find.text(AppStrings.signInTitle), findsOneWidget);
      expect(await storage.read(), isNull);
    });

    testWidgets('keeps the token and offers a retry when offline', (
      tester,
    ) async {
      await storage.write(fakeToken());
      adapter.enqueueFailure(const FormatException('offline'));

      await pumpApp(tester);

      expect(find.text(AppStrings.networkError), findsOneWidget);
      expect(await storage.read(), isNotNull);

      adapter.enqueueJson(200, validToken);
      await tester.tap(find.text(AppStrings.retry));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.welcomeLoggedIn), findsOneWidget);
    });
  });

  group('LoginPage', () {
    testWidgets('validates empty fields before calling the site', (
      tester,
    ) async {
      await pumpApp(tester);

      await tester.tap(find.text(AppStrings.signIn));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.pleaseEnterUsername), findsOneWidget);
      expect(find.text(AppStrings.pleaseEnterPassword), findsOneWidget);
      expect(adapter.requests, isEmpty);
    });

    testWidgets('shows a message on wrong credentials', (tester) async {
      await pumpApp(tester);
      adapter.enqueueJson(
        403,
        wpError(
          '[jwt_auth] incorrect_password',
          '<strong>Error:</strong> wrong',
          403,
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'alice');
      await tester.enterText(find.byType(TextFormField).at(1), 'wrong');
      await tester.tap(find.text(AppStrings.signIn));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.usernameOrPasswordIncorrect), findsOneWidget);
      expect(find.text(AppStrings.signInTitle), findsOneWidget);
      expect(await storage.read(), isNull);
    });

    testWidgets('stores the token and opens the home page on success', (
      tester,
    ) async {
      await pumpApp(tester);
      final token = fakeToken();
      adapter
        ..enqueueJson(200, {'token': token, 'user_display_name': 'Alice'})
        ..enqueueJson(200, validToken);

      await tester.enterText(find.byType(TextFormField).at(0), 'alice');
      await tester.enterText(find.byType(TextFormField).at(1), 'secret');
      await tester.tap(find.text(AppStrings.signIn));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.welcomeLoggedIn), findsOneWidget);
      expect(await storage.read(), token);
      expect(adapter.requests.first.data, {
        'username': 'alice',
        'password': 'secret',
      });
    });
  });

  group('RegisterPage', () {
    Future<void> openRegister(WidgetTester tester) async {
      await pumpApp(tester);
      await tester.tap(find.text(AppStrings.createAccount));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.createAccountTitle), findsOneWidget);
    }

    Future<void> fillAndSubmit(WidgetTester tester) async {
      await tester.enterText(find.byType(TextFormField).at(0), 'carol');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'carol@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'secret');
      await tester.ensureVisible(find.text(AppStrings.createAccountButton));
      await tester.tap(find.text(AppStrings.createAccountButton));
      await tester.pumpAndSettle();
    }

    testWidgets('returns to login after a successful registration', (
      tester,
    ) async {
      await openRegister(tester);
      adapter.enqueueJson(201, {
        'id': 20,
        'username': 'carol',
        'email': 'carol@example.com',
      });

      await fillAndSubmit(tester);

      expect(find.text(AppStrings.accountCreated), findsOneWidget);
      expect(find.text(AppStrings.signInTitle), findsOneWidget);
      expect(adapter.requests.single.uri.path, '/wp-json/jwt-auth/v1/register');
    });

    testWidgets('shows the server message when the username is taken', (
      tester,
    ) async {
      await openRegister(tester);
      adapter.enqueueJson(
        400,
        wpError(
          'existing_user_login',
          'Sorry, that username already exists!',
          400,
        ),
      );

      await fillAndSubmit(tester);

      expect(find.text('Sorry, that username already exists!'), findsOneWidget);
      expect(find.text(AppStrings.createAccountTitle), findsOneWidget);
    });
  });

  testWidgets('ProfilePage shows the user from users/me', (tester) async {
    await storage.write(fakeToken());
    adapter
      ..enqueueJson(200, validToken)
      ..enqueueJson(200, validToken)
      ..enqueueJson(200, {
        'id': 13,
        'username': 'alice',
        'name': 'Alice',
        'slug': 'alice',
        'email': 'alice@example.com',
        'roles': ['subscriber'],
      });
    await pumpApp(tester);

    await tester.tap(find.text(AppStrings.profileSubtitle));
    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('alice@example.com'), findsNWidgets(2));
    expect(find.text('subscriber'), findsOneWidget);
    expect(adapter.requests.last.uri.path, '/wp-json/wp/v2/users/me');
  });

  testWidgets('logout clears the token and shows the login page', (
    tester,
  ) async {
    await storage.write(fakeToken());
    adapter.enqueueJson(200, validToken);
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.signInTitle), findsOneWidget);
    expect(await storage.read(), isNull);
  });
}
