import 'package:flutter/material.dart';
import 'package:wordpress_jwt_auth_example/constants/app_routes.dart';
import 'package:wordpress_jwt_auth_example/constants/app_strings.dart';
import 'package:wordpress_jwt_auth_example/widgets/auth_scope.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.home),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: AppStrings.logout,
            onPressed: () => signOut(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Card(
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 40,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.welcomeLoggedIn,
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.homeSubtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _NavCard(
              icon: Icons.menu_book_outlined,
              title: AppStrings.books,
              subtitle: AppStrings.booksSubtitle,
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.book),
            ),
            const SizedBox(height: 12),
            _NavCard(
              icon: Icons.person_outline,
              title: AppStrings.profile,
              subtitle: AppStrings.profileSubtitle,
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: colorScheme.secondaryContainer,
          child: Icon(icon, color: colorScheme.onSecondaryContainer),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
