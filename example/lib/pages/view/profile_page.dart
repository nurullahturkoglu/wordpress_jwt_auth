import 'package:flutter/material.dart';
import 'package:wordpress_jwt_auth/wordpress_jwt_auth.dart';
import 'package:wordpress_jwt_auth_example/constants/app_strings.dart';
import 'package:wordpress_jwt_auth_example/utils/error_messages.dart';
import 'package:wordpress_jwt_auth_example/widgets/auth_scope.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  WordPressUser? user;
  String? error;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    setState(() {
      user = null;
      error = null;
    });
    try {
      final loaded = await AuthScope.of(context).currentUser();
      if (mounted) setState(() => user = loaded);
    } on InvalidTokenException {
      if (mounted) await signOut(context);
    } on JwtAuthException catch (e) {
      if (mounted) setState(() => error = describeError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = this.user;
    final error = this.error;
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: AppStrings.logout,
            onPressed: () => signOut(context),
          ),
        ],
      ),
      body: SafeArea(
        child: switch ((user, error)) {
          (null, null) => const Center(child: CircularProgressIndicator()),
          (null, final String message) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(AppStrings.couldNotLoadProfile),
                  const SizedBox(height: 8),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: loadUser,
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            ),
          ),
          (final WordPressUser user, _) => _ProfileBody(user: user),
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.user});

  final WordPressUser user;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final initial = user.name.isEmpty ? 'U' : user.name[0].toUpperCase();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: colorScheme.primary,
          child: Text(
            initial,
            style: textTheme.headlineMedium?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user.name,
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          user.email ?? '',
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        Card(
          child: Column(
            children: [
              _InfoTile(
                icon: Icons.tag,
                label: AppStrings.userId,
                value: user.id.toString(),
              ),
              const Divider(height: 1, indent: 72),
              _InfoTile(
                icon: Icons.alternate_email,
                label: AppStrings.username,
                value: user.username ?? user.slug,
              ),
              const Divider(height: 1, indent: 72),
              _InfoTile(
                icon: Icons.mail_outline,
                label: AppStrings.email,
                value: user.email ?? '',
              ),
              const Divider(height: 1, indent: 72),
              _InfoTile(
                icon: Icons.verified_user_outlined,
                label: AppStrings.roles,
                value: user.roles.join(', '),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: colorScheme.secondaryContainer,
        child: Icon(icon, color: colorScheme.onSecondaryContainer),
      ),
      title: Text(
        label,
        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
