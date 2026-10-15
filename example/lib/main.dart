import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wordpress_jwt_auth/wordpress_jwt_auth.dart';
import 'package:wordpress_jwt_auth_example/config.dart';
import 'package:wordpress_jwt_auth_example/constants/app_routes.dart';
import 'package:wordpress_jwt_auth_example/constants/app_strings.dart';
import 'package:wordpress_jwt_auth_example/pages/view/books_page.dart';
import 'package:wordpress_jwt_auth_example/pages/view/home_page.dart';
import 'package:wordpress_jwt_auth_example/pages/view/login_page.dart';
import 'package:wordpress_jwt_auth_example/pages/view/profile_page.dart';
import 'package:wordpress_jwt_auth_example/pages/view/register_page.dart';
import 'package:wordpress_jwt_auth_example/services/secure_token_storage.dart';
import 'package:wordpress_jwt_auth_example/theme.dart';
import 'package:wordpress_jwt_auth_example/widgets/auth_gate.dart';
import 'package:wordpress_jwt_auth_example/widgets/auth_scope.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(
    MyApp(
      auth: WordPressJwtAuth(
        baseUrl: AppConfig.baseUrl,
        storage: SecureTokenStorage(),
        registerPath: AppConfig.registerPath,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.auth, this.initialRoute});

  final WordPressJwtAuth auth;

  /// Route to open first, for example `/profile`. Defaults to the home page.
  final String? initialRoute;

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      auth: auth,
      child: MaterialApp(
        title: AppStrings.appTitle,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        initialRoute: initialRoute,
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: systemUiStyle(Theme.of(context).brightness),
          child: child!,
        ),
        routes: {
          AppRoutes.login: (context) => const LoginPage(),
          AppRoutes.register: (context) => const RegisterPage(),
          AppRoutes.home: (context) => const AuthGate(child: HomePage()),
          AppRoutes.book: (context) => const AuthGate(child: BookPage()),
          AppRoutes.profile: (context) => const AuthGate(child: ProfilePage()),
        },
        home: const AuthGate(child: HomePage()),
      ),
    );
  }
}
