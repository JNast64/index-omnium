import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/firebase_library_service.dart';

/// Top-level page that shows all user-created lists (except the watchlist).
class MyListsPage extends StatelessWidget {
  const MyListsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirebaseLibraryService.instance;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<LibraryList>>(
          stream: service.watchLists(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Error loading lists:\n${snap.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            // All lists for this user.
            final allLists = snap.data ?? const <LibraryList>[];

            // Hide the dedicated watchlist document (we show that in the
            // separate Watchlist tab).
            final lists = allLists.where((l) => l.isWatchlist != true).toList();

            if (lists.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.playlist_add_check_outlined, size: 48),
                      const SizedBox(height: 16),
                      Text('No lists yet', style: textTheme.titleMedium),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap the + button to create your first list.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: lists.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final list = lists[index];

                // createdAt may be null if older docs exist; handle safely.
                final created = list.createdAt;
                final createdLabel =
                    created != null ? 'Created: ${created.toLocal()}' : '';

                return ListTile(
                  title: Text(list.name),
                  subtitle: createdLabel.isNotEmpty ? Text(createdLabel) : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to the detail page; pass the list along as extra
                    // so DetailPage can show the title immediately.
                    context.push('/lists/${list.id}', extra: list);
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final name = await showDialog<String>(
            context: context,
            builder: (ctx) => const _NewListDialog(),
          );

          if (name != null && name.trim().isNotEmpty) {
            // Your current FirebaseLibraryService.createList() expects
            // a *positional* name argument (based on earlier fixes).
            await service.createList(name.trim());
          }
        },
        icon: const Icon(Icons.playlist_add),
        label: const Text('New List'),
      ),
    );
  }
}

class _NewListDialog extends StatefulWidget {
  const _NewListDialog();

  @override
  State<_NewListDialog> createState() => _NewListDialogState();
}

class _NewListDialogState extends State<_NewListDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New list'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'List name',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Create'),
        ),
      ],
    );
  }
}
