import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/firebase_library_service.dart';

class DiaryPage extends StatelessWidget {
  const DiaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirebaseLibraryService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: StreamBuilder<List<DiaryEntry>>(
        stream: service.watchDiaryEntries(),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading diary:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final entries = snapshot.data ?? const <DiaryEntry>[];

          // Empty state
          if (entries.isEmpty) {
            return const _EmptyDiary();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final e = entries[i];
              final ratingText =
                  e.rating != null ? e.rating!.toStringAsFixed(1) : '–';
              final when = e.createdAt?.toLocal();
              final subtitleText = when != null ? 'Created: $when' : '';

              return Card(
                child: ListTile(
                  onTap: () => ctx.push('/diaryEntry/${e.id}'),
                  leading: const CircleAvatar(
                    child: Icon(Icons.edit_note, size: 18),
                  ),
                  title: Text(e.title),
                  subtitle: Text(
                    'Rating: $ratingText  •  $when',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Delete diary entry?'),
                          content: Text(
                            'Remove this diary entry for "${e.title}"?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (ok == true) {
                        await service.deleteDiaryEntry(e.id!);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),

      // 👇 NEW: button to create a brand-new diary entry
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Assumes you have a route like '/diaryEntry/:entryId'
          // This will use 'new' as a special id for "create mode"
          context.push('/diaryEntry/new');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptyDiary extends StatelessWidget {
  const _EmptyDiary();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_outlined, size: 40),
            const SizedBox(height: 12),
            Text(
              'No diary entries yet',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button to create a diary entry.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
