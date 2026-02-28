import 'dart:math';

import '../data/mock/mock_media.dart';
import 'tmdb_service.dart';
import 'google_books_service.dart';
import 'spotify_service.dart';
import 'igdb_service.dart';

/// Tiny facade that returns ~10 items for a given media [type].
/// Uses the real API services under the hood.
class MediaBrowseService {
  MediaBrowseService._();
  static final MediaBrowseService I = MediaBrowseService._();

  final _rng = Random();

  // use the singleton instances exposed by each service
  final _tmdb = TmdbService.instance;
  final _books = GoogleBooksService.instance;
  final _spotify = SpotifyService.instance;
  final _igdb = IgdbService.instance;

  Future<List<MockMediaItem>> browseType(String type) async {
    switch (type) {
      case 'movie':
        return _browseMovies();
      case 'tv':
        return _browseTv();
      case 'book':
        return _browseBooks();
      case 'game':
        return _browseGames();
      case 'song':
        return _browseSongs();
      default:
        return const <MockMediaItem>[];
    }
  }

  Future<List<MockMediaItem>> _browseMovies() async {
    const queries = ['star', 'love', 'war', 'night', 'city', 'story'];
    final q = queries[_rng.nextInt(queries.length)];

    final movies = await _tmdb.searchMovies(q); // already List<MockMediaItem>
    final limited = movies.take(10).toList();
    MockCatalog.registerExternalItems(limited);
    return limited;
  }

  Future<List<MockMediaItem>> _browseTv() async {
    const queries = ['house', 'crime', 'world', 'family', 'comedy'];
    final q = queries[_rng.nextInt(queries.length)];

    final shows = await _tmdb.searchTv(q);
    final limited = shows.take(10).toList();
    MockCatalog.registerExternalItems(limited);
    return limited;
  }

  Future<List<MockMediaItem>> _browseBooks() async {
    const topics = ['history', 'fantasy', 'science', 'mystery', 'music'];
    final q = topics[_rng.nextInt(topics.length)];

    final books = await _books.searchBooks(q);
    final limited = books.take(10).toList();
    MockCatalog.registerExternalItems(limited);
    return limited;
  }

  Future<List<MockMediaItem>> _browseGames() async {
    const topics = ['adventure', 'action', 'rpg', 'sports', 'racing'];
    final q = topics[_rng.nextInt(topics.length)];

    final games = await _igdb.searchGames(q);
    final limited = games.take(10).toList();
    MockCatalog.registerExternalItems(limited);
    return limited;
  }

  Future<List<MockMediaItem>> _browseSongs() async {
    const topics = ['hits', 'lofi', 'jazz', 'rock', 'chill', 'pop'];
    final q = topics[_rng.nextInt(topics.length)];

    final tracks = await _spotify.searchTracks(q);
    final limited = tracks.take(10).toList();
    MockCatalog.registerExternalItems(limited);
    return limited;
  }
}
