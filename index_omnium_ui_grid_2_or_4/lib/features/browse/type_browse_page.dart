import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../common/widgets/media_card.dart';
import '../../common/formatters.dart';
import '../../data/mock/mock_media.dart';
import '../../data/model/media_description.dart';
import '../../services/media_browse_service.dart';

class TypeBrowsePage extends StatefulWidget {
  final String type;
  const TypeBrowsePage({super.key, required this.type});

  @override
  State<TypeBrowsePage> createState() => _TypeBrowsePageState();
}

class _TypeBrowsePageState extends State<TypeBrowsePage> {
  late Future<List<MockMediaItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = MediaBrowseService.I.browseType(widget.type);
  }

  String _titleFor(String t) {
    switch (t) {
      case 'movie':
        return 'Movies';
      case 'tv':
        return 'Shows';
      case 'book':
        return 'Books';
      case 'game':
        return 'Games';
      case 'song':
        return 'Songs';
      default:
        return t;
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

  void _reload() {
    setState(() {
      _future = MediaBrowseService.I.browseType(widget.type);
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _titleFor(widget.type);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Always go back to HomePage route
            context.go('/'); // change this if your Home route path is different
          },
        ),
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<MockMediaItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: 'Could not load $title',
              onRetry: _reload,
            );
          }

          final items = snapshot.data ?? const <MockMediaItem>[];
          if (items.isEmpty) {
            return _EmptyState(
              message: 'No $title to show right now.',
              onRetry: _reload,
            );
          }

          final shuffled = List<MockMediaItem>.from(items)..shuffle(Random());

          return LayoutBuilder(
            builder: (context, cons) {
              final w = cons.maxWidth;
              final h = MediaQuery.of(context).size.height;

              final useList = (w < 600) || (h < 600);

              if (useList) {
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: shuffled.length,
                  itemBuilder: (_, i) {
                    final m = shuffled[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MediaCard(
                        title: m.title,
                        type: m.type,
                        year: m.year,
                        imageUrl: m.imageUrl,
                        rating: m.rating,
                        subtitle: m.subtitle,
                        blurb: _blurbFor(m),
                        onTap: () => context.push('/detail/${m.id}'),
                      ),
                    );
                  },
                );
              }

              final cols = w >= 900 ? 4 : 2;
              const spacing = 12.0;
              final tileW = (w - (spacing * (cols - 1)) - 24) / cols;
              const tileH = 210.0;
              final imgW = (tileW * 0.38).clamp(96, 180);

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: tileW / tileH,
                ),
                itemCount: shuffled.length,
                itemBuilder: (_, i) {
                  final m = shuffled[i];
                  return MediaCard(
                    imageWidth: imgW.toDouble(),
                    title: m.title,
                    type: m.type,
                    year: m.year,
                    imageUrl: m.imageUrl,
                    rating: m.rating,
                    subtitle: m.subtitle,
                    blurb: _blurbFor(m),
                    onTap: () => context.push('/detail/${m.id}'),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 12),
            Text(message),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _EmptyState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.movie_outlined, size: 40),
            const SizedBox(height: 12),
            Text(message),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
