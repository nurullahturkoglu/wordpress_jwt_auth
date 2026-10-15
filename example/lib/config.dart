class AppConfig {
  // Pass --dart-define=WP_BASE_URL=http://10.0.2.2:8080 for the Android emulator.
  static const String baseUrl = String.fromEnvironment(
    'WP_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  // Path of the endpoint added by wordpress/jwt-auth-register.php.
  static const String registerPath = 'register';
}
