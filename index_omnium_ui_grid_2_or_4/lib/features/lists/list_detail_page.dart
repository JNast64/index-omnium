import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import '../../common/widgets/poster_tile.dart';
import '../../data/mock/mock_media.dart';
import '../../services/firebase_library_service.dart';

import '../../services/tmdb_service.dart';
import '../../services/google_books_service.dart';
import '../../services/igdb_service.dart';
import '../../services/spotify_service.dart';

class ListDetailPage extends StatefulWidget {
  final String listId;
  final dynamic initialList; // optional LibraryList passed from router

  const ListDetailPage({
    super.key,
    required this.listId,
    this.initialList,
  });

  @override
  State<ListDetailPage> createState() => _ListDetailPageState();
}

class _ListDetailPageState extends State<ListDetailPage> {
  // Local copy so drag-reorder feels instant. Order is not yet persisted.
  List<LibraryItem>? _itemsCache;

  @override
  Widget build(BuildContext context) {
    final service = FirebaseLibraryService.instance;

    return StreamBuilder<List<LibraryList>>(
      stream: service.watchLists(),
      builder: (context, listsSnap) {
        if (listsSnap.connectionState == ConnectionState.waiting &&
            !listsSnap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (listsSnap.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading list:\n${listsSnap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final allLists = listsSnap.data ?? const <LibraryList>[];

        LibraryList? list;
        try {
          list = allLists.firstWhere((l) => l.id == widget.listId);
        } catch (_) {
          final extra = widget.initialList;
          if (extra is LibraryList) list = extra;
        }

        if (list == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('List not found')),
          );
        }

        // Non-null handle used below to avoid nullable warnings
        final currentList = list;

        return Scaffold(
          appBar: AppBar(
            title: Text(currentList.name),
            actions: [
              IconButton(
                tooltip: 'Add items',
                icon: const Icon(Icons.add),
                onPressed: () async {
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => _AddItemsSheet(listId: currentList.id),
                  );
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'rename') {
                    final newTitle = await showDialog<String>(
                      context: context,
                      builder: (_) =>
                          _RenameListDialog(initial: currentList.name),
                    );
                    if (newTitle != null && newTitle.trim().isNotEmpty) {
                      await service.renameList(
                        listId: currentList.id,
                        newName: newTitle.trim(),
                      );
                    }
                  } else if (value == 'clear') {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Clear list?'),
                        content: Text(
                          'Remove all items from "${currentList.name}"?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      final items =
                          await service.watchListItems(currentList.id).first;
                      for (final it in items) {
                        await service.removeItem(
                          listId: currentList.id,
                          itemId: it.id,
                        );
                      }
                    }
                  } else if (value == 'delete') {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Delete list?'),
                        content: Text(
                          'Delete "${currentList.name}" permanently?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await service.deleteList(currentList.id);
                      if (mounted) Navigator.of(context).pop();
                    }
                  }
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(
                    value: 'rename',
                    child: Text('Rename list'),
                  ),
                  PopupMenuItem(
                    value: 'clear',
                    child: Text('Clear items'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete list'),
                  ),
                ],
              ),
            ],
          ),
          body: StreamBuilder<List<LibraryItem>>(
            stream: service.watchListItems(currentList.id),
            builder: (context, itemsSnap) {
              if (itemsSnap.connectionState == ConnectionState.waiting &&
                  !itemsSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (itemsSnap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Error loading items:\n${itemsSnap.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final items = itemsSnap.data ?? const <LibraryItem>[];

              // Local cache so drag reorder stays local.
              if (_itemsCache == null || _itemsCache!.length != items.length) {
                _itemsCache = List.of(items);
              }
              final localItems = _itemsCache!;

              if (localItems.isEmpty) {
                return const _EmptyState();
              }

              return LayoutBuilder(
                builder: (context, cons) {
                  final w = cons.maxWidth;
                  int cols = 3;
                  if (w >= 1200) {
                    cols = 7;
                  } else if (w >= 1000) {
                    cols = 6;
                  } else if (w >= 800) {
                    cols = 5;
                  } else if (w >= 600) {
                    cols = 4;
                  }

                  return ReorderableGridView.count(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                    crossAxisCount: cols,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.6,
                    dragStartDelay: const Duration(milliseconds: 150),
                    onReorder: (oldIndex, newIndex) {
                      final item = localItems.removeAt(oldIndex);
                      localItems.insert(newIndex, item);
                      HapticFeedback.selectionClick();
                      setState(() {});
                    },
                    children: [
                      for (var i = 0; i < localItems.length; i++)
                        _ReorderableTile(
                          key: ValueKey(localItems[i].id),
                          listId: currentList.id,
                          item: localItems[i],
                          rank: i + 1,
                        ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.movie_outlined, size: 48),
            const SizedBox(height: 16),
            Text('No items in this list yet', style: t.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button in the app bar to add movies, shows, games, or books.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReorderableTile extends StatelessWidget {
  final String listId;
  final LibraryItem item;
  final int rank;

  const _ReorderableTile({
    super.key,
    required this.listId,
    required this.item,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    // Try to resolve the media from the in-memory catalog first.
    final existing = MockCatalog.byId(item.sourceId);

    // Fallback: build a lightweight MockMediaItem from the LibraryItem so
    // DetailPage always has something to render, even after app restart.
    final media = existing ??
        MockMediaItem(
          id: item.sourceId,
          type: item.mediaType,
          title: item.title,
          subtitle: item.subtitle,
          imageUrl: item.imageUrl,
          year: null,
          desc: null,
        );

    return Stack(
      children: [
        PosterTile(
          imageUrl: media.imageUrl ?? item.imageUrl,
          rank: rank,
          semanticsLabel: item.title,
          onTap: () {
            context.push('/detail/${media.id}', extra: media);
          },
        ),
        const Positioned(
          left: 6,
          top: 6,
          child: Icon(Icons.drag_handle, size: 20),
        ),
        Positioned(
          right: 6,
          top: 6,
          child: Material(
            color: Colors.transparent,
            child: IconButton(
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Remove',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final toRemoveTitle = item.title;
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Remove item?'),
                    content: Text(toRemoveTitle),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  final service = FirebaseLibraryService.instance;
                  await service.removeItem(
                    listId: listId,
                    itemId: item.id,
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _AddItemsSheet extends StatefulWidget {
  final String listId;
  const _AddItemsSheet({required this.listId});

  @override
  State<_AddItemsSheet> createState() => _AddItemsSheetState();
}

class _AddItemsSheetState extends State<_AddItemsSheet> {
  String _type = 'movie';
  String _query = '';

  bool _loading = false;
  List<MockMediaItem> _results = const [];

  // API services
  final TmdbService _tmdb = TmdbService.instance;
  final GoogleBooksService _books = GoogleBooksService.instance;
  final IgdbService _igdb = IgdbService.instance;
  final SpotifyService _spotify = SpotifyService.instance;

  @override
  void initState() {
    super.initState();
    _loadResults(); // initial load with default items
  }

  Future<void> _loadResults() async {
    setState(() {
      _loading = true;
    });

    try {
      final q = _query.trim();
      List<MockMediaItem> items;

      if (q.isEmpty) {
        // Fallback to local mock items when there's no search text.
        items = MockCatalog.byType(_type);
      } else {
        switch (_type) {
          case 'movie':
            items = await _tmdb.searchMovies(q);
            break;
          case 'tv':
            items = await _tmdb.searchTv(q);
            break;
          case 'book':
            items = await _books.searchBooks(q);
            break;
          case 'game':
            items = await _igdb.searchGames(q);
            break;
          case 'song':
            items = await _spotify.searchTracks(q);
            break;
          default:
            items = const [];
        }

        // So DetailPage / MockCatalog.byId can find these by id later.
        MockCatalog.registerExternalItems(items);
      }

      if (!mounted) return;
      setState(() {
        _results = items;
      });
    } catch (e, st) {
      debugPrint('Error loading AddItemsSheet results: $e\n$st');
      if (!mounted) return;
      setState(() {
        _results = const [];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = FirebaseLibraryService.instance;

    return StreamBuilder<List<LibraryItem>>(
      stream: service.watchListItems(widget.listId),
      builder: (context, itemsSnap) {
        final existing = itemsSnap.data ?? const <LibraryItem>[];
        final existingIds = existing.map((e) => e.sourceId).toSet();

        final results = _results;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search…',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: _loadResults,
                              ),
                            ),
                            onChanged: (v) {
                              _query = v;
                            },
                            onSubmitted: (v) {
                              _query = v;
                              _loadResults();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _type,
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() {
                              _type = v;
                            });
                            _loadResults();
                          },
                          items: const [
                            DropdownMenuItem(
                              value: 'movie',
                              child: Text('Movies'),
                            ),
                            DropdownMenuItem(
                              value: 'tv',
                              child: Text('TV'),
                            ),
                            DropdownMenuItem(
                              value: 'game',
                              child: Text('Games'),
                            ),
                            DropdownMenuItem(
                              value: 'book',
                              child: Text('Books'),
                            ),
                            DropdownMenuItem(
                              value: 'song',
                              child: Text('Songs'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _loading && results.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : LayoutBuilder(
                            builder: (context, cons) {
                              final w = cons.maxWidth;
                              int cols = 3;
                              if (w >= 1200) {
                                cols = 7;
                              } else if (w >= 1000) {
                                cols = 6;
                              } else if (w >= 800) {
                                cols = 5;
                              } else if (w >= 600) {
                                cols = 4;
                              }

                              if (results.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No results. Try a different search.',
                                  ),
                                );
                              }

                              return GridView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  0,
                                  12,
                                  12,
                                ),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  // Taller tiles so we avoid overflow stripes.
                                  childAspectRatio: 0.6,
                                ),
                                itemCount: results.length,
                                itemBuilder: (_, i) {
                                  final m = results[i];
                                  final already = existingIds.contains(m.id);

                                  return Stack(
                                    children: [
                                      PosterTile(
                                        imageUrl: m.imageUrl,
                                        rank: i + 1,
                                        semanticsLabel: m.title,
                                        onTap: already
                                            ? null
                                            : () async {
                                                final item = LibraryItem(
                                                  id: '',
                                                  title: m.title,
                                                  subtitle: m.subtitle,
                                                  mediaType: m.type,
                                                  source:
                                                      _sourceForType(m.type),
                                                  sourceId: m.id,
                                                  imageUrl: m.imageUrl,
                                                );
                                                await service.upsertItem(
                                                  listId: widget.listId,
                                                  item: item,
                                                );
                                              },
                                      ),
                                      if (already)
                                        const Positioned(
                                          right: 6,
                                          top: 6,
                                          child: CircleAvatar(
                                            radius: 12,
                                            child: Icon(
                                              Icons.check,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.done),
                      label: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Map our media type to a source label for Firestore.
  String _sourceForType(String type) {
    switch (type) {
      case 'movie':
      case 'tv':
        return 'tmdb';
      case 'book':
        return 'googleBooks';
      case 'game':
        return 'igdb';
      case 'song':
        return 'spotify';
      default:
        return 'mock';
    }
  }
}

class _RenameListDialog extends StatefulWidget {
  final String initial;
  const _RenameListDialog({required this.initial});

  @override
  State<_RenameListDialog> createState() => _RenameListDialogState();
}

class _RenameListDialogState extends State<_RenameListDialog> {
  late final TextEditingController _c =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename list'),
      content: TextField(
        controller: _c,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _c.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
