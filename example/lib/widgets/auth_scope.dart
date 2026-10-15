import 'package:flutter/material.dart';
import 'package:wordpress_jwt_auth/wordpress_jwt_auth.dart';
import 'package:wordpress_jwt_auth_example/constants/app_routes.dart';

class AuthScope extends InheritedWidget {
  const AuthScope({super.key, required this.auth, required super.child});

  final WordPressJwtAuth auth;

  static WordPressJwtAuth of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'No AuthScope found above this widget');
    return scope!.auth;
  }

  @override
  bool updateShouldNotify(AuthScope oldWidget) => auth != oldWidget.auth;
}

Future<void> signOut(BuildContext context) async {
  final navigator = Navigator.of(context);
  await AuthScope.of(context).logout();
  navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
}
