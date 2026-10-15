// Entry point used to capture the README screenshots.
//
// flutter run -t lib/main_screenshots.dart \
//   --dart-define=WP_BASE_URL=http://localhost:8080 \
//   --dart-define=SCREENSHOT_ROUTE=/profile
//
// Signs in as the demo user created by docker/setup.sh first, so the
// AuthGate below the requested route lets it stay on screen.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wordpress_jwt_auth/wordpress_jwt_auth.dart';
import 'package:wordpress_jwt_auth_example/config.dart';
import 'package:wordpress_jwt_auth_example/main.dart';

const _route = String.fromEnvironment('SCREENSHOT_ROUTE', defaultValue: '/');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final auth = WordPressJwtAuth(
    baseUrl: AppConfig.baseUrl,
    storage: InMemoryTokenStorage(),
    registerPath: AppConfig.registerPath,
  );
  await auth.login(username: 'demo', password: 'demo1234');
  runApp(MyApp(auth: auth, initialRoute: _route));
}
