// lib/config/api_keys.dart

// All external API keys / client IDs for Index Omnium.

class ApiKeys {
  // TMDB (movies/TV) – from https://www.themoviedb.org/settings/api
  static const String tmdbApiKey = '9c19339f503f20fd4a7bdfa96a92d34c';

  // Google Books – from the Google Cloud "Your API key" popup
  static const String googleBooksApiKey =
      'AIzaSyBA4Q3Kmqz1jN1nqM-j_FcDjQZtfwO-I5U';

  // IGDB / Twitch – from your Twitch dev console app ("INdex Omnium")
  static const String igdbClientId = '8imctls174y6gvduiocn9hzifa2vml';
  static const String igdbClientSecret = '5p7kiff1uzgvwezgnxjnl4dfyx20w1';

  // Spotify – from https://developer.spotify.com/dashboard
  static const String spotifyClientId = '39c6f37b57fe493388f23eee50cbf813';
  static const String spotifyClientSecret = '609920df828948efa32e022ec87c4733';

  // The redirect URI you configured in Spotify
  static const String spotifyRedirectUri =
      'http://127.0.0.1:61510/auth/spotify/callback';

  // Twitch redirect (for reference if you ever need it)
  static const String twitchRedirectUri = 'https://localhost';
}
