import 'package:flutter/material.dart';
import 'package:wordpress_jwt_auth/wordpress_jwt_auth.dart';
import 'package:wordpress_jwt_auth_example/constants/app_strings.dart';
import 'package:wordpress_jwt_auth_example/utils/error_messages.dart';
import 'package:wordpress_jwt_auth_example/widgets/auth_page_layout.dart';
import 'package:wordpress_jwt_auth_example/widgets/auth_scope.dart';
import 'package:wordpress_jwt_auth_example/widgets/auth_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    try {
      await AuthScope.of(context).register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      showMessage(context, AppStrings.accountCreated);
      Navigator.of(context).pop();
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
      title: AppStrings.createAccountTitle,
      subtitle: AppStrings.joinUsToday,
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
              label: AppStrings.email,
              icon: Icons.mail_outline,
              controller: _emailController,
              emptyMessage: AppStrings.pleaseEnterEmail,
              keyboardType: TextInputType.emailAddress,
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
              label: AppStrings.createAccountButton,
              isLoading: isLoading,
              onPressed: handleRegister,
            ),
          ],
        ),
      ),
      footer: AuthFooterLink(
        text: AppStrings.alreadyHaveAccount,
        linkText: AppStrings.login,
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}
