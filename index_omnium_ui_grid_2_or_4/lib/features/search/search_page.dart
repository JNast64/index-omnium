import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../common/empty_state.dart';
import '../../common/widgets/media_card.dart';
import '../../data/mock/mock_media.dart';
import '../../data/model/media_description.dart';
import '../../data/model/media_item.dart';
import '../../common/formatters.dart';
import '../../services/tmdb_service.dart';
import '../../services/google_books_service.dart';
import '../../services/igdb_service.dart';
import '../../services/spotify_service.dart';

class SearchPage extends StatefulWidget {
  final String initialQuery;

  const SearchPage({super.key, this.initialQuery = ''});

  @override
  State<SearchPage> createState() => _S();
}

class _S extends State<SearchPage> {
  String t = 'movie';
  String q = '';
  late final TextEditingController _controller;

  bool _loading = false;
  String? _error;
  List<MockMediaItem> _results = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    q = widget.initialQuery;
    _controller = TextEditingController(text: q);

    if (q.isNotEmpty) {
      _runSearch();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String v) {
    setState(() => q = v);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _runSearch);
  }

  Future<void> _runSearch() async {
    final query = q.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _error = null;
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      List<MockMediaItem> items;

      switch (t) {
        case 'movie':
          items = await TmdbService.instance.searchMovies(query);
          break;
        case 'tv':
          items = await TmdbService.instance.searchTv(query);
          break;
        case 'book':
          items = await GoogleBooksService.instance.searchBooks(query);
          break;
        case 'game':
          items = await IgdbService.instance.searchGames(query);
          break;
        case 'song':
          items = await SpotifyService.instance.searchTracks(query);
          break;
        default:
          items = const [];
      }

      if (!mounted) return;
      setState(() => _results = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _blurbFor(MockMediaItem item) {
    final d = item.desc;
    if (d is BookDescription) {
      if (d.authors.isNotEmpty) return 'by ${d.authors.join(', ')}';
    } else if (d is MusicDescription) {
      final who = '${d.artist}${d.album != null ? ' — ${d.album}' : ''}';
      final dur =
          d.durationSec != null ? ' • ${fmtSeconds(d.durationSec!)}' : '';
      return '$who$dur';
    } else if (d is MovieTvDescription) {
      final p = <String>[];
      if (d.genres != null && d.genres!.isNotEmpty) {
        p.add(d.genres!.take(2).join(' • '));
      }
      if (d.runtimeMinutes != null) p.add(fmtMinutes(d.runtimeMinutes!));
      return p.join(' • ');
    } else if (d is GameDescription) {
      final p = <String>[];
      if (d.platforms != null && d.platforms!.isNotEmpty) {
        p.add(d.platforms!.join(', '));
      }
      if (d.developers != null && d.developers!.isNotEmpty) {
        p.add('Dev: ${d.developers!.join(', ')}');
      }
      return p.join(' • ');
    }
    return '';
  }

  /// Convert the mock/API model into the shared MediaItem model that the
  /// library service, watchlist, and diary use.
  MediaItem _toMediaItem(MockMediaItem m) {
    final desc = m.desc;
    final creators = <String>[];
    final genres = <String>[];
    String? summary;

    if (desc is BookDescription) {
      creators.addAll(desc.authors);
      summary = desc.synopsis;
    } else if (desc is MovieTvDescription) {
      if (desc.directors != null) creators.addAll(desc.directors!);
      if (desc.cast != null && desc.cast!.isNotEmpty) {
        creators.addAll(desc.cast!.take(3));
      }
      if (desc.genres != null) genres.addAll(desc.genres!);
      summary = desc.synopsis;
    } else if (desc is MusicDescription) {
      if (desc.artist.isNotEmpty) creators.add(desc.artist);
      if (desc.album != null && desc.album!.isNotEmpty) {
        creators.add(desc.album!);
      }
      summary = desc.notes;
    } else if (desc is GameDescription) {
      if (desc.developers != null) creators.addAll(desc.developers!);
      // Use platforms as a rough stand-in for "genres" here.
      if (desc.platforms != null && desc.platforms!.isNotEmpty) {
        genres.addAll(desc.platforms!);
      }
      summary = desc.summary;
    }

    String source;
    switch (m.type) {
      case 'movie':
      case 'tv':
        source = 'tmdb';
        break;
      case 'book':
        source = 'googleBooks';
        break;
      case 'game':
        source = 'igdb';
        break;
      case 'song':
        source = 'spotify';
        break;
      default:
        source = 'unknown';
    }

    return MediaItem(
      mediaKey: m.id,
      type: mediaTypeFromString(m.type),
      source: source,
      sourceId: m.id,
      title: m.title,
      subtitle: m.subtitle,
      year: m.year,
      imageUrl: m.imageUrl,
      creators: creators,
      genres: genres,
      summary: summary,
    );
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Search title…',
                    ),
                    onChanged: _onQueryChanged,
                    onSubmitted: (_) => _runSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: t,
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => t = v);
                    _runSearch();
                  },
                  items: const [
                    DropdownMenuItem(value: 'movie', child: Text('Movies')),
                    DropdownMenuItem(value: 'tv', child: Text('TV')),
                    DropdownMenuItem(value: 'song', child: Text('Songs')),
                    DropdownMenuItem(value: 'book', child: Text('Books')),
                    DropdownMenuItem(value: 'game', child: Text('Games')),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildResults(c),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext c) {
    if (q.trim().isEmpty) {
      return const EmptyState(
        title: 'Try a search',
        message: 'Type a title and pick a media type.',
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    if (_results.isEmpty) {
      return const EmptyState(
        title: 'No results',
        message: 'Try a different query or media type.',
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (ctx, i) {
        final m = _results[i];
        final mediaItem = _toMediaItem(m);

        return MediaCard(
          title: m.title,
          type: m.type,
          year: m.year,
          imageUrl: m.imageUrl,
          rating: m.rating,
          subtitle: m.subtitle,
          blurb: _blurbFor(m),
          onTap: () => c.push('/detail/${m.id}', extra: m),
        );
      },
    );
  }
}
