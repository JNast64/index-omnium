import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_keys.dart';
import '../data/mock/mock_media.dart';
import '../data/model/media_description.dart';

class TmdbService {
  TmdbService._();
  static final TmdbService instance = TmdbService._();

  static const String _host = 'api.themoviedb.org';
  static const String _imageBase = 'https://image.tmdb.org/t/p/w500';

  Future<List<MockMediaItem>> searchMovies(String query) async {
    final uri = Uri.https(
      _host,
      '/3/search/movie',
      {
        'api_key': ApiKeys.tmdbApiKey,
        'query': query,
        'include_adult': 'false',
        'language': 'en-US',
        'page': '1',
      },
    );

    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('TMDB movie search failed (${resp.statusCode})');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final results =
        (data['results'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    return results.map(_mapMovie).toList();
  }

  Future<List<MockMediaItem>> searchTv(String query) async {
    final uri = Uri.https(
      _host,
      '/3/search/tv',
      {
        'api_key': ApiKeys.tmdbApiKey,
        'query': query,
        'include_adult': 'false',
        'language': 'en-US',
        'page': '1',
      },
    );

    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('TMDB TV search failed (${resp.statusCode})');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final results =
        (data['results'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    return results.map(_mapTv).toList();
  }

  MockMediaItem _mapMovie(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final title = json['title'] as String? ??
        json['original_title'] as String? ??
        'Untitled movie';
    final overview = json['overview'] as String? ?? '';
    final poster = json['poster_path'] as String?;
    final date = json['release_date'] as String?;
    final year = _parseYear(date);
    final rating10 = (json['vote_average'] as num?)?.toDouble();
    final rating5 = rating10 != null ? rating10 / 2.0 : null;

    final desc = MovieTvDescription(
      synopsis: overview,
      genres: null,
      runtimeMinutes: null,
      directors: null,
      cast: null,
    );

    return MockMediaItem(
      id: 'tmdb_movie_$id',
      type: 'movie',
      title: title,
      subtitle: overview.isNotEmpty ? overview : null,
      year: year,
      rating: rating5,
      imageUrl: poster != null ? '$_imageBase$poster' : null,
      desc: desc,
    );
  }

  MockMediaItem _mapTv(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final title = json['name'] as String? ??
        json['original_name'] as String? ??
        'Untitled show';
    final overview = json['overview'] as String? ?? '';
    final poster = json['poster_path'] as String?;
    final date = json['first_air_date'] as String?;
    final year = _parseYear(date);
    final rating10 = (json['vote_average'] as num?)?.toDouble();
    final rating5 = rating10 != null ? rating10 / 2.0 : null;

    final desc = MovieTvDescription(
      synopsis: overview,
      genres: null,
      runtimeMinutes: null,
      directors: null,
      cast: null,
    );

    return MockMediaItem(
      id: 'tmdb_tv_$id',
      type: 'tv',
      title: title,
      subtitle: overview.isNotEmpty ? overview : null,
      year: year,
      rating: rating5,
      imageUrl: poster != null ? '$_imageBase$poster' : null,
      desc: desc,
    );
  }

  int? _parseYear(String? date) {
    if (date == null || date.isEmpty) return null;
    final yearStr = date.split('-').first;
    return int.tryParse(yearStr);
  }
}
