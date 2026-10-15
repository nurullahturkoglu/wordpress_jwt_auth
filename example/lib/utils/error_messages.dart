import 'package:flutter/material.dart';
import 'package:wordpress_jwt_auth/wordpress_jwt_auth.dart';
import 'package:wordpress_jwt_auth_example/constants/app_strings.dart';

String describeError(JwtAuthException error) {
  return switch (error) {
    InvalidCredentialsException() => AppStrings.usernameOrPasswordIncorrect,
    InvalidTokenException() => AppStrings.sessionExpired,
    ServerConfigurationException() =>
      '${AppStrings.serverNotConfigured} (${error.code})',
    RegistrationException() => error.message,
    NetworkException() => AppStrings.networkError,
    UnexpectedResponseException() => AppStrings.unexpectedResponse,
  };
}

void showMessage(BuildContext context, String text, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: error
          ? Theme.of(context).colorScheme.error
          : Colors.green,
    ),
  );
}
