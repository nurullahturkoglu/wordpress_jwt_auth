import 'package:flutter/material.dart';
import 'package:wordpress_jwt_auth/wordpress_jwt_auth.dart';
import 'package:wordpress_jwt_auth_example/constants/app_routes.dart';
import 'package:wordpress_jwt_auth_example/constants/app_strings.dart';
import 'package:wordpress_jwt_auth_example/utils/error_messages.dart';
import 'package:wordpress_jwt_auth_example/widgets/auth_page_layout.dart';
import 'package:wordpress_jwt_auth_example/widgets/auth_scope.dart';
import 'package:wordpress_jwt_auth_example/widgets/auth_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    try {
      await AuthScope.of(context).login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      showMessage(context, AppStrings.loginSuccessful);
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
    } on JwtAuthException catch (e) {
      if (!mounted) return;
      showMessage(context, describeError(e), error: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageLayout(
      title: AppStrings.signInTitle,
      subtitle: AppStrings.welcomeBack,
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              label: AppStrings.username,
              icon: Icons.person_outline,
              controller: _usernameController,
              emptyMessage: AppStrings.pleaseEnterUsername,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              label: AppStrings.password,
              icon: Icons.lock_outline,
              controller: _passwordController,
              emptyMessage: AppStrings.pleaseEnterPassword,
              obscureText: true,
            ),
            const SizedBox(height: 24),
            AuthSubmitButton(
              label: AppStrings.signIn,
              isLoading: isLoading,
              onPressed: handleLogin,
            ),
          ],
        ),
      ),
      footer: AuthFooterLink(
        text: AppStrings.dontHaveAccount,
        linkText: AppStrings.createAccount,
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.register),
      ),
    );
  }
}
