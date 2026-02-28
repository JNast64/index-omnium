import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock/mock_media.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF1E1E1E);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Index Omnium',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  // Search bar
                  Material(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    child: TextField(
                      controller: _q,
                      style: const TextStyle(color: Colors.white),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        hintText: 'Search',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        border: InputBorder.none,
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white70,
                        ),
                      ),
                      onSubmitted: (value) {
                        final q = value.trim();
                        if (q.isEmpty) {
                          context.go('/search');
                        } else {
                          context.go('/search?q=${Uri.encodeComponent(q)}');
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Responsive media tiles
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, cons) {
                        final width = cons.maxWidth;

                        // 4x1 (large), 2x2 (medium), 1x1 (small)
                        int cols;
                        if (width >= 1000) {
                          cols = 4; // desktop / big window
                        } else if (width >= 600) {
                          cols = 2; // tablet / medium
                        } else {
                          cols = 1; // phone
                        }

                        return GridView.count(
                          crossAxisCount: cols,
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 18,
                          padding: const EdgeInsets.only(bottom: 12),
                          childAspectRatio: 1 / 1.2,
                          children: [
                            _Tile(
                              title: 'Books',
                              type: 'book',
                              items: MockCatalog.byType('book'),
                              onTap: () => context.go('/browse/book'),
                            ),
                            _Tile(
                              title: 'Movies',
                              type: 'movie',
                              items: MockCatalog.byType('movie'),
                              onTap: () => context.go('/browse/movie'),
                            ),
                            _Tile(
                              title: 'Shows',
                              type: 'tv',
                              items: MockCatalog.byType('tv'),
                              onTap: () => context.go('/browse/tv'),
                            ),
                            _Tile(
                              title: 'Games',
                              type: 'game',
                              items: MockCatalog.byType('game'),
                              onTap: () => context.go('/browse/game'),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatefulWidget {
  final String title;
  final String type;
  final List<MockMediaItem> items;
  final VoidCallback onTap;

  const _Tile({
    required this.title,
    required this.type,
    required this.items,
    required this.onTap,
  });

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  int i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || widget.items.isEmpty) return;
      setState(() => i = (i + 1) % widget.items.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.items.isNotEmpty ? widget.items[i] : null;
    final r = BorderRadius.circular(20);

    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: r,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item?.imageUrl != null)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                child: Image.network(
                  item!.imageUrl!,
                  key: ValueKey(item.imageUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback when picsum or any image URL fails.
                    return Container(
                      color: Colors.white10,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.white38,
                          size: 40,
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Container(color: Colors.white10),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _icon(widget.type),
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _icon(String t) {
    switch (t) {
      case 'movie':
        return Icons.movie;
      case 'tv':
        return Icons.tv;
      case 'song':
        return Icons.music_note;
      case 'book':
        return Icons.menu_book;
      case 'game':
        return Icons.sports_esports;
      default:
        return Icons.category;
    }
  }
}
