import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_keys.dart';
import '../data/mock/mock_media.dart';
import '../data/model/media_description.dart';

class SpotifyService {
  SpotifyService._();
  static final SpotifyService instance = SpotifyService._();

  String? _accessToken;
  DateTime? _tokenExpiry;

  Future<void> _ensureToken() async {
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return;
    }

    final creds = '${ApiKeys.spotifyClientId}:${ApiKeys.spotifyClientSecret}';
    final basic = base64Encode(utf8.encode(creds));

    final resp = await http.post(
      Uri.https('accounts.spotify.com', '/api/token'),
      headers: {
        'Authorization': 'Basic $basic',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'grant_type=client_credentials',
    );

    if (resp.statusCode != 200) {
      throw Exception('Spotify token request failed (${resp.statusCode})');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    _accessToken = data['access_token'] as String;
    final expiresIn = (data['expires_in'] as num?)?.toInt() ?? 3600;
    _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
  }

  Future<List<MockMediaItem>> searchTracks(String query) async {
    await _ensureToken();

    final uri = Uri.https(
      'api.spotify.com',
      '/v1/search',
      {
        'q': query,
        'type': 'track',
        'limit': '20',
      },
    );

    final resp = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );

    if (resp.statusCode != 200) {
      throw Exception('Spotify search failed (${resp.statusCode})');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final tracks = ((data['tracks'] ?? {}) as Map<String, dynamic>)['items']
            as List<dynamic>? ??
        const [];
    final maps = tracks.cast<Map<String, dynamic>>();
    return maps.map(_mapTrack).toList();
  }

  MockMediaItem _mapTrack(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final name = json['name'] as String? ?? 'Untitled track';
    final artists =
        (json['artists'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final primaryArtist =
        artists.isNotEmpty ? artists.first['name'] as String? : null;
    final artistNames = artists
        .map((a) => a['name'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    final album = (json['album'] ?? {}) as Map<String, dynamic>;
    final albumName = album['name'] as String?;
    final images =
        (album['images'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final imageUrl = images.isNotEmpty ? images.first['url'] as String? : null;
    final releaseDate = album['release_date'] as String?;
    final year = _parseYear(releaseDate);
    final durationMs = json['duration_ms'] as int?;
    final popularity = (json['popularity'] as num?)?.toDouble();

    final desc = MusicDescription(
      artist:
          primaryArtist ?? (artistNames.isNotEmpty ? artistNames.first : ''),
      album: albumName,
      durationSec: durationMs != null ? durationMs ~/ 1000 : null,
      notes: null,
    );

    double? rating;
    if (popularity != null) {
      rating = (popularity / 100.0) * 5.0; // map 0–100 popularity to 0–5
    }

    return MockMediaItem(
      id: 'spotify_track_$id',
      type: 'song',
      title: name,
      subtitle: [
        if (artistNames.isNotEmpty) artistNames.join(', '),
        if (albumName != null) albumName,
      ].where((s) => s != null && s.isNotEmpty).join(' — '),
      year: year,
      rating: rating,
      imageUrl: imageUrl,
      desc: desc,
    );
  }

  int? _parseYear(String? d) {
    if (d == null || d.isEmpty) return null;
    return int.tryParse(d.split('-').first);
  }
}
