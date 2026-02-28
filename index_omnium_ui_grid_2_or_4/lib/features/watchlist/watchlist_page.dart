import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../common/widgets/media_card.dart';
import '../../data/mock/mock_media.dart';
import '../../services/firebase_library_service.dart';

class WatchlistPage extends StatelessWidget {
  const WatchlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirebaseLibraryService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Watchlist')),
      body: StreamBuilder<List<LibraryItem>>(
        stream: service.watchWatchlistItems(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading watchlist:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final items = snapshot.data ?? const <LibraryItem>[];

          // Empty state
          if (items.isEmpty) {
            return const _EmptyWatchlist();
          }

          // Normal list
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final entry = items[index];

              // Try to reconstruct a MockMediaItem if it's in the local catalog.
              final media = MockCatalog.byId(entry.sourceId) ??
                  MockMediaItem(
                    id: entry.sourceId,
                    type: entry.mediaType,
                    title: entry.title,
                    subtitle: entry.subtitle,
                    imageUrl: entry.imageUrl,
                    year: null,
                    rating: null,
                    desc: null,
                  );

              final watched = entry.watched;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Checkbox – persisted in Firestore
                    Checkbox(
                      value: watched,
                      onChanged: (value) async {
                        final newVal = value ?? false;
                        await service.setWatchlistItemWatched(
                          itemId: entry.id,
                          watched: newVal,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    // Card, dimmed when watched
                    Expanded(
                      child: Opacity(
                        opacity: watched ? 0.4 : 1.0,
                        child: MediaCard(
                          title: media.title,
                          type: media.type,
                          year: media.year,
                          imageUrl: media.imageUrl,
                          subtitle: media.subtitle,
                          rating: media.rating,
                          onTap: () => context.push(
                            '/detail/${media.id}',
                            extra: media,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove from watchlist',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await service.removeFromWatchlistBySourceId(
                          entry.sourceId,
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyWatchlist extends StatelessWidget {
  const _EmptyWatchlist();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bookmark_border, size: 48),
            const SizedBox(height: 16),
            Text('Your watchlist is empty', style: t.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Browse some media and tap “Add to watchlist” to save it here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
