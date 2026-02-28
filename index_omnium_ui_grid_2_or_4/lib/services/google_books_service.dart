import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_keys.dart';
import '../data/mock/mock_media.dart';
import '../data/model/media_description.dart';

class GoogleBooksService {
  GoogleBooksService._();
  static final GoogleBooksService instance = GoogleBooksService._();

  Future<List<MockMediaItem>> searchBooks(String query) async {
    final uri = Uri.https(
      'www.googleapis.com',
      '/books/v1/volumes',
      {
        'q': query,
        'key': ApiKeys.googleBooksApiKey,
        'maxResults': '20',
      },
    );

    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Google Books search failed (${resp.statusCode})');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final items =
        (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    return items.map(_mapVolume).toList();
  }

  MockMediaItem _mapVolume(Map<String, dynamic> item) {
    final id = item['id']?.toString() ?? '';
    final info = (item['volumeInfo'] ?? {}) as Map<String, dynamic>;
    final title = info['title'] as String? ?? 'Untitled book';
    final authors =
        (info['authors'] as List<dynamic>?)?.cast<String>() ?? const [];
    final description = info['description'] as String? ?? '';
    final thumbnail =
        (info['imageLinks'] as Map<String, dynamic>?)?['thumbnail'] as String?;
    final published = info['publishedDate'] as String?;
    final year = _parseYear(published);
    final rating = (info['averageRating'] as num?)?.toDouble();
    final pageCount = info['pageCount'] as int?;
    final publisher = info['publisher'] as String?;

    final desc = BookDescription(
      synopsis: description,
      authors: authors,
      pageCount: pageCount,
      publisher: publisher,
    );

    return MockMediaItem(
      id: 'google_book_$id',
      type: 'book',
      title: title,
      subtitle: authors.isNotEmpty ? 'by ${authors.join(', ')}' : null,
      year: year,
      rating: rating,
      imageUrl: thumbnail,
      desc: desc,
    );
  }

  int? _parseYear(String? published) {
    if (published == null || published.isEmpty) return null;
    // formats like "2005" or "2005-06-01"
    final yearStr = published.split('-').first;
    return int.tryParse(yearStr);
  }
}
