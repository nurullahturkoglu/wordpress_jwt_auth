import 'package:flutter/material.dart';
import 'package:wordpress_jwt_auth_example/constants/app_strings.dart';

class BookPage extends StatefulWidget {
  const BookPage({super.key});

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  static const List<String> _books = [
    'Clean Code',
    'The Pragmatic Programmer',
    'Refactoring',
    'Design Patterns',
    'Working Effectively with Legacy Code',
    'Domain-Driven Design',
    'Continuous Delivery',
    'Flutter in Action',
    'Dart Apprentice',
    'WordPress Plugin Development',
  ];

  String _query = '';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filtered = _books
        .where((book) => book.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.books)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SearchBar(
                hintText: AppStrings.searchBooks,
                leading: const Icon(Icons.search),
                elevation: const WidgetStatePropertyAll(0),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 56,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppStrings.noBooksFound,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.tertiaryContainer,
                            child: Icon(
                              Icons.menu_book_outlined,
                              color: colorScheme.onTertiaryContainer,
                            ),
                          ),
                          title: Text(filtered[index]),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
