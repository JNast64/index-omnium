// lib/data/model/media_item.dart

enum MediaType {
  movie,
  tv,
  book,
  game,
  album,
  track,
}

MediaType mediaTypeFromString(String value) {
  switch (value) {
    case 'movie':
      return MediaType.movie;
    case 'tv':
      return MediaType.tv;
    case 'book':
      return MediaType.book;
    case 'game':
      return MediaType.game;
    case 'album':
      return MediaType.album;
    case 'track':
      return MediaType.track;
    default:
      return MediaType.movie;
  }
}

String mediaTypeToString(MediaType type) {
  return type.toString().split('.').last;
}

class MediaItem {
  final String mediaKey; // e.g. movie_tmdb_550
  final MediaType type;
  final String source; // tmdb | googleBooks | igdb | spotify
  final String sourceId;
  final String title;
  final String? subtitle;
  final int? year;
  final String? imageUrl;
  final List<String> creators;
  final List<String> genres;
  final String? summary;

  const MediaItem({
    required this.mediaKey,
    required this.type,
    required this.source,
    required this.sourceId,
    required this.title,
    this.subtitle,
    this.year,
    this.imageUrl,
    this.creators = const [],
    this.genres = const [],
    this.summary,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'mediaKey': mediaKey,
      'type': mediaTypeToString(type),
      'source': source,
      'sourceId': sourceId,
      'title': title,
      'subtitle': subtitle,
      'year': year,
      'imageUrl': imageUrl,
      'creators': creators,
      'genres': genres,
      'summary': summary,
    };
  }

  factory MediaItem.fromFirestore(Map<String, dynamic> data) {
    return MediaItem(
      mediaKey: data['mediaKey'] as String,
      type: mediaTypeFromString(data['type'] as String),
      source: data['source'] as String,
      sourceId: data['sourceId'] as String,
      title: data['title'] as String,
      subtitle: data['subtitle'] as String?,
      year: (data['year'] is int) ? data['year'] as int : null,
      imageUrl: data['imageUrl'] as String?,
      creators: (data['creators'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      genres: (data['genres'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      summary: data['summary'] as String?,
    );
  }
}
