import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock/mock_media.dart';
import '../../data/model/media_description.dart';
import '../../services/firebase_library_service.dart';

class DiaryEntryPage extends StatefulWidget {
  final String entryId; // 'new' for create, Firestore id for edit

  const DiaryEntryPage({
    super.key,
    required this.entryId,
  });

  @override
  State<DiaryEntryPage> createState() => _DiaryEntryPageState();
}

class _DiaryEntryPageState extends State<DiaryEntryPage> {
  final _bodyController = TextEditingController();
  double _rating = 0.0;
  bool _loading = true;
  bool _saving = false;
  bool _editing = false;

  DiaryEntry? _entry;
  MockMediaItem? _media;

  bool get _isNew => widget.entryId == 'new';

  @override
  void initState() {
    super.initState();
    _editing = _isNew;
    _load();
  }

  Future<void> _load() async {
    final service = FirebaseLibraryService.instance;

    if (_isNew) {
      setState(() {
        _entry = DiaryEntry(
          id: null,
          title: 'New diary entry',
          body: '',
          mediaItemId: null,
          mediaType: null,
          imageUrl: null,
          year: null,
          rating: 0,
        );
        _rating = 0;
        _bodyController.text = '';
        _media = null;
        _loading = false;
      });
      return;
    }

    final entry = await service.fetchDiaryEntry(widget.entryId);
    if (!mounted) return;

    // Try to resolve from MockCatalog first (same-session items).
    MockMediaItem? media;
    if (entry?.mediaItemId != null) {
      media = MockCatalog.byId(entry!.mediaItemId!);
    }

    // Fallback: build a lightweight media object from stored fields.
    if (media == null && entry != null && entry.mediaType != null) {
      media = MockMediaItem(
        id: entry.mediaItemId ?? entry.id ?? 'diary-${entry.hashCode}',
        type: entry.mediaType!,
        title: entry.title,
        subtitle: null,
        imageUrl: entry.imageUrl,
        year: entry.year,
        desc: null,
      );
    }

    double r = entry?.rating ?? 0;
    // Old entries might be 0–10; normalise to 0–5.
    if (r > 5) r = r / 2;
    r = r.clamp(0, 5);

    setState(() {
      _entry = entry;
      _media = media;
      _rating = r;
      _bodyController.text = entry?.body ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    final entry = _entry;
    if (entry == null) return;

    final service = FirebaseLibraryService.instance;

    setState(() => _saving = true);

    final updated = DiaryEntry(
      id: entry.id,
      title: entry.title,
      body: _bodyController.text,
      mediaItemId: entry.mediaItemId,
      mediaType: entry.mediaType,
      imageUrl: entry.imageUrl,
      year: entry.year,
      rating: _rating, // always 0–5
      createdAt: entry.createdAt,
      updatedAt: DateTime.now(),
    );

    await service.saveDiaryEntry(updated);

    if (!mounted) return;

    setState(() {
      _saving = false;
      _editing = false;
      _entry = updated;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Diary entry saved')),
    );

    if (_isNew) {
      GoRouter.of(context).go('/diary');
    }
  }

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_entry == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Diary Entry'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              final router = GoRouter.of(context);
              if (router.canPop()) {
                router.pop();
              } else {
                router.go('/diary');
              }
            },
          ),
        ),
        body: const Center(
          child: Text('Diary entry not found.'),
        ),
      );
    }

    final e = _entry!;
    final title = _media?.title ?? e.title;
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final router = GoRouter.of(context);
            if (router.canPop()) {
              router.pop();
            } else {
              router.go('/diary');
            }
          },
        ),
        actions: [
          if (!_editing && !_isNew)
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _editing = true),
            ),
          if (_editing)
            IconButton(
              tooltip: 'Save',
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              onPressed: _saving ? null : _save,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isWide
            ? _buildWideLayout(context, e, title)
            : _buildNarrowLayout(context, e),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Layouts
  // ---------------------------------------------------------------------------

  Widget _buildWideLayout(
    BuildContext context,
    DiaryEntry e,
    String title,
  ) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              // LEFT COLUMN
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _media != null
                        ? _BigPoster(media: _media!)
                        : _NoPosterPlaceholder(),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _RatingRow(
                        rating: _rating,
                        editing: _editing,
                        onChanged: (v) => setState(() => _rating = v),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_media != null)
                      _MediaInfoCard(media: _media!)
                    else
                      _TextInfoCard(title: e.title),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // RIGHT COLUMN
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          '$title – ${_rating.toStringAsFixed(1)}/5',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notes',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: TextField(
                                  controller: _bodyController,
                                  maxLines: null,
                                  expands: true,
                                  enabled: _editing,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Timestamps(entry: e),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context, DiaryEntry e) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_media != null)
            _BigPoster(media: _media!)
          else
            _NoPosterPlaceholder(),
          const SizedBox(height: 12),
          _RatingRow(
            rating: _rating,
            editing: _editing,
            onChanged: (v) => setState(() => _rating = v),
          ),
          const SizedBox(height: 16),
          if (_media != null)
            _MediaInfoCard(media: _media!)
          else
            _TextInfoCard(title: e.title),
          const SizedBox(height: 16),
          Text(
            'Notes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bodyController,
            maxLines: 10,
            enabled: _editing,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              disabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _Timestamps(entry: e),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Small helper widgets
// -----------------------------------------------------------------------------

class _BigPoster extends StatelessWidget {
  final MockMediaItem media;

  const _BigPoster({required this.media});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: media.imageUrl != null
            ? Image.network(
                media.imageUrl!,
                fit: BoxFit.cover,
              )
            : Container(
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: const Icon(Icons.image, size: 64),
              ),
      ),
    );
  }
}

class _NoPosterPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined, size: 40),
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final double rating; // 0–5
  final bool editing;
  final ValueChanged<double> onChanged;

  const _RatingRow({
    required this.rating,
    required this.editing,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Rating:'),
            const SizedBox(width: 8),
            _StarRating(
              value: rating,
              onChanged: editing ? onChanged : null,
            ),
            const SizedBox(width: 8),
            Text(rating.toStringAsFixed(1)),
          ],
        ),
        if (editing) ...[
          const SizedBox(height: 8),
          Slider(
            min: 0,
            max: 5,
            divisions: 10,
            value: rating,
            label: rating.toStringAsFixed(1),
            onChanged: onChanged,
          ),
        ],
      ],
    );
  }
}

class _MediaInfoCard extends StatelessWidget {
  final MockMediaItem media;

  const _MediaInfoCard({required this.media});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    // Build a short description based on the media's description object.
    String? overview;
    final d = media.desc;
    if (d is MovieTvDescription) {
      overview = d.synopsis;
    } else if (d is BookDescription) {
      overview = d.synopsis;
    } else if (d is GameDescription) {
      overview = d.summary;
    } else if (d is MusicDescription) {
      overview = '${d.artist}${d.album != null ? ' — ${d.album}' : ''}';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(media.title, style: t.titleMedium),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (media.year != null)
                  Text('Year: ${media.year}', style: t.bodySmall),
                Text('Type: ${media.type}', style: t.bodySmall),
              ],
            ),
            if (overview != null && overview.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                overview,
                style: t.bodySmall,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TextInfoCard extends StatelessWidget {
  final String title;
  const _TextInfoCard({required this.title});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(title, style: t.titleMedium),
      ),
    );
  }
}

class _Timestamps extends StatelessWidget {
  final DiaryEntry entry;
  const _Timestamps({required this.entry});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Created: ${entry.createdAt?.toLocal() ?? ''}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          'Last updated: ${entry.updatedAt?.toLocal() ?? ''}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Star control where `value` is 0–5.
class _StarRating extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;

  const _StarRating({
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const totalStars = 5;
    final filled = value.clamp(0, totalStars.toDouble());

    final List<Widget> stars = [];
    for (int i = 1; i <= totalStars; i++) {
      final icon = filled >= i
          ? Icons.star
          : (filled >= i - 0.5 ? Icons.star_half : Icons.star_border);

      stars.add(
        IconButton(
          iconSize: 28,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          icon: Icon(icon),
          color: Colors.amber,
          onPressed: onChanged == null ? null : () => onChanged!(i.toDouble()),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: stars,
    );
  }
}
