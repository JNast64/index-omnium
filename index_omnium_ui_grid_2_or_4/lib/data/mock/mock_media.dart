import '../model/media_description.dart';

class MockMediaItem {
  final String id, type, title;
  final int? year;
  final String? imageUrl;
  final double? rating;
  final String? subtitle;
  final MediaDescription? desc;

  MockMediaItem({
    required this.id,
    required this.type,
    required this.title,
    this.year,
    this.imageUrl,
    this.rating,
    this.subtitle,
    this.desc,
  });
}

final mockTrending = [
  MockMediaItem(
      id: '1',
      type: 'tv',
      title: 'The Good Place',
      year: 2016,
      subtitle: 'Comedy • Fantasy',
      rating: 4.5,
      imageUrl: 'https://picsum.photos/300/450?1',
      desc: MovieTvDescription(
          synopsis:
              'After an unlikely afterlife mixup, Eleanor tries to become a better person.',
          genres: ['Comedy', 'Fantasy'],
          runtimeMinutes: 22,
          cast: ['Kristen Bell', 'Ted Danson'])),
  MockMediaItem(
      id: '2',
      type: 'movie',
      title: '12 Angry Men',
      year: 1957,
      subtitle: 'Drama',
      rating: 4.8,
      imageUrl: 'https://picsum.photos/300/450?2',
      desc: MovieTvDescription(
          synopsis:
              'Twelve jurors debate a life-or-death verdict in a single room.',
          genres: ['Drama'],
          runtimeMinutes: 96,
          directors: ['Sidney Lumet'])),
  MockMediaItem(
      id: 'B1',
      type: 'book',
      title: 'Don’t Fear the Reaper',
      year: 2023,
      subtitle: 'Horror • Thriller',
      imageUrl: 'https://picsum.photos/300/450?11',
      desc: BookDescription(
          synopsis:
              'A prison transport goes wrong during a blizzard; a killer vanishes into town.',
          authors: ['Stephen Graham Jones'],
          pageCount: 464,
          publisher: 'Saga Press')),
  MockMediaItem(
      id: 'G1',
      type: 'game',
      title: 'Donkey Kong 64',
      year: 1999,
      subtitle: 'Platformer',
      imageUrl: 'https://picsum.photos/300/450?12',
      desc: GameDescription(
          summary:
              'Collectathon platforming with multiple Kongs and sprawling 3D worlds.',
          platforms: ['N64'],
          developers: ['Rare'])),
  MockMediaItem(
      id: 'S1',
      type: 'song',
      title: 'Don’t Fear the Reaper',
      year: 1976,
      subtitle: 'Blue Öyster Cult',
      imageUrl: 'https://picsum.photos/300/450?13',
      desc: MusicDescription(
          artist: 'Blue Öyster Cult',
          album: 'Agents of Fortune',
          durationSec: 305,
          notes: 'Iconic cowbell, enduring rock classic.')),
];

final sourceMore = [
  MockMediaItem(
      id: '7',
      type: 'movie',
      title: 'The Godfather Part II',
      year: 1974,
      subtitle: 'Crime',
      imageUrl: 'https://picsum.photos/300/450?7',
      desc: MovieTvDescription(
          synopsis:
              'Michael expands the family empire while Vito’s past unfolds.',
          genres: ['Crime', 'Drama'],
          runtimeMinutes: 202,
          directors: ['Francis Ford Coppola'],
          cast: ['Al Pacino', 'Robert De Niro'])),
  MockMediaItem(
      id: '8',
      type: 'movie',
      title: 'The Shawshank Redemption',
      year: 1994,
      subtitle: 'Drama',
      imageUrl: 'https://picsum.photos/300/450?8',
      desc: MovieTvDescription(
          synopsis:
              'Hope finds a foothold in the bleak confines of Shawshank prison.',
          genres: ['Drama'],
          runtimeMinutes: 142,
          directors: ['Frank Darabont'])),
  MockMediaItem(
      id: '9',
      type: 'movie',
      title: 'City of God',
      year: 2002,
      subtitle: 'Crime',
      imageUrl: 'https://picsum.photos/300/450?9',
      desc: MovieTvDescription(
          synopsis: 'Friendship and survival in the favelas of Rio de Janeiro.',
          genres: ['Crime', 'Drama'],
          runtimeMinutes: 130)),
  MockMediaItem(
      id: '10',
      type: 'movie',
      title: 'The Human Condition I',
      year: 1959,
      subtitle: 'War',
      imageUrl: 'https://picsum.photos/300/450?10',
      desc: MovieTvDescription(
          synopsis:
              'A pacifist thrust into war confronts the limits of conscience.',
          genres: ['War', 'Drama'],
          runtimeMinutes: 208)),

  // --- A View to a Kill set ---

  // Movie
  MockMediaItem(
    id: 'AVTAK_MOVIE',
    type: 'movie',
    title: 'A View to a Kill',
    year: 1985,
    subtitle: 'Action • Spy',
    imageUrl: 'https://picsum.photos/300/450?20',
    rating: 3.5,
    desc: MovieTvDescription(
      synopsis:
          'James Bond investigates an industrialist whose microchip scheme threatens global stability.',
      genres: ['Action', 'Spy', 'Thriller'],
      runtimeMinutes: 131,
      directors: ['John Glen'],
      cast: ['Roger Moore', 'Christopher Walken', 'Grace Jones'],
    ),
  ),

  // Song
  MockMediaItem(
    id: 'AVTAK_SONG',
    type: 'song',
    title: 'A View to a Kill',
    year: 1985,
    subtitle: 'Duran Duran',
    imageUrl: 'https://picsum.photos/300/450?21',
    rating: 4.0,
    desc: MusicDescription(
      artist: 'Duran Duran',
      album: 'A View to a Kill (Single)',
      durationSec: 230, // ~3:50
      notes:
          'Glossy 80s Bond theme with big synths and one of the series’ biggest pop crossovers.',
    ),
  ),

  // Book (novelization)
  MockMediaItem(
    id: 'AVTAK_BOOK',
    type: 'book',
    title: 'A View to a Kill',
    year: 1985,
    subtitle: 'James Bond novelization',
    imageUrl: 'https://picsum.photos/300/450?22',
    rating: 3.2,
    desc: BookDescription(
      synopsis:
          '007 races to stop a Silicon Valley–focused plot as the film’s story is adapted into prose.',
      authors: ['John Gardner'],
      pageCount: 240,
      publisher: 'Jonathan Cape',
    ),
  ),

  // Game
  MockMediaItem(
    id: 'AVTAK_GAME',
    type: 'game',
    title: 'A View to a Kill',
    year: 1985,
    subtitle: 'Action adventure',
    imageUrl: 'https://picsum.photos/300/450?23',
    rating: 2.8,
    desc: GameDescription(
      summary:
          'Retro adaptation of the Bond film, mixing driving and action levels inspired by key scenes.',
      platforms: ['Commodore 64', 'ZX Spectrum', 'Amstrad CPC'],
      developers: ['Domark'],
    ),
  ),
];

class MockCatalog {
  // Extra items coming from external APIs (TMDB, Spotify, etc.)
  static final List<MockMediaItem> _external = [];

  /// All items: built-in mock data + external items.
  static List<MockMediaItem> all() =>
      [...mockTrending, ...sourceMore, ..._external];

  /// Register / merge items fetched from APIs so DetailPage can find them by id.
  static void registerExternalItems(Iterable<MockMediaItem> items) {
    for (final item in items) {
      final index = _external.indexWhere((e) => e.id == item.id);
      if (index == -1) {
        _external.add(item);
      } else {
        _external[index] = item;
      }
    }
  }

  static List<MockMediaItem> byType(String t) =>
      all().where((e) => e.type == t).toList();

  static MockMediaItem? byId(String id) {
    try {
      return all().firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
