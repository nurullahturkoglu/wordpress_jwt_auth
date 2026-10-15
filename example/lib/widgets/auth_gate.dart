import 'package:flutter/material.dart';
import 'package:wordpress_jwt_auth/wordpress_jwt_auth.dart';
import 'package:wordpress_jwt_auth_example/constants/app_routes.dart';
import 'package:wordpress_jwt_auth_example/constants/app_strings.dart';
import 'package:wordpress_jwt_auth_example/utils/error_messages.dart';
import 'package:wordpress_jwt_auth_example/widgets/auth_scope.dart';

/// Shows [child] only while the stored token is valid.
///
/// Expired or rejected tokens send the user to the login page. A site that
/// cannot be reached keeps the token and offers a retry.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _authenticated = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() => _error = null);
    final auth = AuthScope.of(context);

    final claims = await auth.claims();
    if (claims == null || claims.isExpired) {
      await auth.logout();
      _goToLogin();
      return;
    }

    final bool valid;
    try {
      valid = await auth.validateToken();
    } on JwtAuthException catch (e) {
      if (mounted) setState(() => _error = describeError(e));
      return;
    }

    if (!valid) {
      _goToLogin();
      return;
    }
    if (mounted) setState(() => _authenticated = true);
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_authenticated) return widget.child;

    final error = _error;
    return Scaffold(
      body: Center(
        child: error == null
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _check,
                      child: const Text(AppStrings.retry),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
