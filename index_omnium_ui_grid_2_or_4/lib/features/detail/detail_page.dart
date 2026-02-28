import 'package:flutter/material.dart';

import '../../common/widgets/media_badge.dart';
import '../../data/mock/mock_media.dart';
import '../../data/mock/mock_store.dart';
import '../../data/model/media_description.dart';
import '../../common/formatters.dart';
import '../../services/firebase_library_service.dart' as lib;

class DetailPage extends StatelessWidget {
  final String itemId;
  final dynamic initialItem; // can be passed from Search via GoRouter.extra

  const DetailPage({
    super.key,
    required this.itemId,
    this.initialItem,
  });

  Future<void> _toggleWatchlist(MockMediaItem item) async {
    final store = MockStore.I;
    final service = lib.FirebaseLibraryService.instance;

    // Check if this item was in the local watchlist before toggling.
    final wasInWatchlist = store.isInWatchlist(item.id);

    // 1) Update local mock store so the UI reacts immediately.
    store.toggleWatchlist(item);

    // 2) Mirror the change into Firestore.
    if (wasInWatchlist) {
      // It was in the watchlist → remove from Firestore.
      await service.removeFromWatchlistBySourceId(item.id);
    } else {
      // It wasn't in the watchlist → add to Firestore.
      final libItem = lib.LibraryItem(
        title: item.title,
        subtitle: item.subtitle,
        mediaType: item.type,
        source: 'mock', // you can refine this later per source
        sourceId: item.id,
        imageUrl: item.imageUrl,
      );

      await service.addItemToWatchlist(libItem);
    }
  }

  @override
  Widget build(BuildContext c) {
    final store = MockStore.I;

    // Prefer the object passed via route; fall back to lookup by ID.
    final item = initialItem ?? MockCatalog.byId(itemId);

    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Item not found')),
      );
    }

    return AnimatedBuilder(
      animation: store,
      builder: (_, __) {
        final inWatchlist = store.isInWatchlist(item.id);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              item.title,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                tooltip:
                    inWatchlist ? 'Remove from Watchlist' : 'Add to Watchlist',
                icon: Icon(
                  inWatchlist ? Icons.bookmark : Icons.bookmark_add_outlined,
                ),
                onPressed: () => _toggleWatchlist(item),
              ),
            ],
          ),
          body: ListView(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: item.imageUrl != null
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Theme.of(c).colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.image),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        MediaBadge(type: item.type),
                        const SizedBox(width: 8),
                        if (item.year != null)
                          Text(
                            '${item.year}',
                            style: Theme.of(c).textTheme.titleMedium,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      style: Theme.of(c).textTheme.headlineSmall,
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(item.subtitle!),
                    ],
                    const SizedBox(height: 16),

                    // Watchlist button (backed by MockStore + Firestore)
                    FilledButton.icon(
                      onPressed: () => _toggleWatchlist(item),
                      icon: Icon(
                        inWatchlist
                            ? Icons.bookmark_remove
                            : Icons.bookmark_add_outlined,
                      ),
                      label: Text(
                        inWatchlist
                            ? 'Remove from Watchlist'
                            : 'Add to Watchlist',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Add to List (now Firestore-backed)
                    FilledButton.icon(
                      onPressed: () async {
                        await showDialog(
                          context: c,
                          builder: (_) => _AddToListDialog(item: item),
                        );
                      },
                      icon: const Icon(Icons.playlist_add),
                      label: const Text('Add to List'),
                    ),
                    const SizedBox(height: 12),

                    // Log to Diary (Firestore)
                    OutlinedButton.icon(
                      onPressed: () => _showDiaryDialog(c, item),
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Log to Diary'),
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'Overview',
                      style: Theme.of(c).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _DescriptionView(desc: item.desc),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDiaryDialog(BuildContext context, dynamic item) async {
    final service = lib.FirebaseLibraryService.instance;
    double rating = 3.0;
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Add to Diary'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle!,
                        style: Theme.of(ctx)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey),
                      ),
                    ],
                    if (item.year != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${item.year}',
                        style: Theme.of(ctx).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Rating: ${rating.toStringAsFixed(1)}',
                      style: Theme.of(ctx).textTheme.bodyMedium,
                    ),
                    Slider(
                      min: 0,
                      max: 5,
                      divisions: 10,
                      value: rating,
                      label: rating.toStringAsFixed(1),
                      onChanged: (v) => setState(() => rating = v),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Your thoughts',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final entry = lib.DiaryEntry(
                      id: null,
                      title: item.title,
                      body: controller.text,
                      mediaItemId: item.id,
                      mediaType: item.type,
                      imageUrl: item.imageUrl,
                      year: item.year,
                      rating: rating,
                    );
                    await service.saveDiaryEntry(entry);
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Description rendering
class _DescriptionView extends StatelessWidget {
  final MediaDescription? desc;
  const _DescriptionView({required this.desc});

  @override
  Widget build(BuildContext c) {
    final t = Theme.of(c).textTheme;
    if (desc == null) {
      return const Text('No description available.');
    }

    if (desc is MovieTvDescription) {
      final d = desc as MovieTvDescription;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(d.synopsis),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (d.genres != null && d.genres!.isNotEmpty)
                Chip(label: Text(d.genres!.join(' • '))),
              if (d.runtimeMinutes != null)
                Chip(label: Text(fmtMinutes(d.runtimeMinutes!))),
              if (d.directors != null && d.directors!.isNotEmpty)
                Chip(label: Text('Director: ${d.directors!.join(', ')}')),
            ],
          ),
          if (d.cast != null && d.cast!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Cast', style: t.titleSmall),
            Text(d.cast!.join(', ')),
          ],
        ],
      );
    }

    if (desc is BookDescription) {
      final d = desc as BookDescription;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(d.synopsis),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                label: Text(
                  'Author${d.authors.length > 1 ? 's' : ''}: '
                  '${d.authors.join(', ')}',
                ),
              ),
              if (d.pageCount != null)
                Chip(label: Text('${d.pageCount} pages')),
              if (d.publisher != null)
                Chip(label: Text('Publisher: ${d.publisher}')),
            ],
          ),
        ],
      );
    }

    if (desc is GameDescription) {
      final d = desc as GameDescription;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(d.summary),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (d.platforms != null && d.platforms!.isNotEmpty)
                Chip(label: Text('Platforms: ${d.platforms!.join(', ')}')),
              if (d.developers != null && d.developers!.isNotEmpty)
                Chip(label: Text('Dev: ${d.developers!.join(', ')}')),
            ],
          ),
        ],
      );
    }

    final m = desc as MusicDescription;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${m.artist}${m.album != null ? ' — ${m.album}' : ''}'),
        if (m.durationSec != null) ...[
          const SizedBox(height: 8),
          Text('Duration: ${fmtSeconds(m.durationSec!)}'),
        ],
        if (m.notes != null && m.notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(m.notes!),
        ],
      ],
    );
  }
}

/// Dialog to choose / create a list **using Firestore**.
class _AddToListDialog extends StatelessWidget {
  final dynamic item;
  const _AddToListDialog({required this.item});

  @override
  Widget build(BuildContext context) {
    final service = lib.FirebaseLibraryService.instance;

    lib.LibraryItem _toLibraryItem() {
      return lib.LibraryItem(
        // id empty -> new Firestore doc
        title: item.title,
        subtitle: item.subtitle,
        mediaType: item.type,
        source: 'mock', // for now; can be 'tmdb', 'igdb', etc. later
        sourceId: item.id,
        imageUrl: item.imageUrl,
      );
    }

    return AlertDialog(
      title: const Text('Add to List'),
      content: SizedBox(
        width: 400,
        child: StreamBuilder<List<lib.LibraryList>>(
          stream: service.watchLists(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error loading lists:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              );
            }

            final lists = (snapshot.data ?? const <lib.LibraryList>[])
                // hide the special watchlist; this dialog is for custom lists
                .where((l) => !l.isWatchlist)
                .toList();

            if (lists.isEmpty) {
              return const Text(
                'You don\'t have any lists yet.\n\n'
                'Tap "New List" below to create one.',
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: lists.length,
              itemBuilder: (ctx, i) {
                final l = lists[i];

                return ListTile(
                  title: Text(l.name),
                  subtitle: Text('Created: ${l.createdAt.toLocal()}'),
                  trailing: const Icon(Icons.add),
                  onTap: () async {
                    final libItem = _toLibraryItem();
                    await service.upsertItem(
                      listId: l.id,
                      item: libItem,
                    );
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          onPressed: () async {
            final name = await showDialog<String>(
              context: context,
              builder: (ctx) => const _NewListDialog(),
            );
            if (name != null && name.trim().isNotEmpty) {
              final id = await service.createList(name.trim());
              final libItem = _toLibraryItem();
              await service.upsertItem(listId: id, item: libItem);
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            }
          },
          icon: const Icon(Icons.playlist_add),
          label: const Text('New List'),
        ),
      ],
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
      title: const Text('New List'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'List name',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Create'),
        ),
      ],
    );
  }
}
