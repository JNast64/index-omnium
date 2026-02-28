import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_keys.dart';
import '../data/mock/mock_media.dart';
import '../data/model/media_description.dart';

class IgdbService {
  IgdbService._();
  static final IgdbService instance = IgdbService._();

  String? _accessToken;
  DateTime? _tokenExpiry;

  Future<void> _ensureToken() async {
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return;
    }

    final uri = Uri.https('id.twitch.tv', '/oauth2/token', {
      'client_id': ApiKeys.igdbClientId,
      'client_secret': ApiKeys.igdbClientSecret,
      'grant_type': 'client_credentials',
    });

    final resp = await http.post(uri);
    if (resp.statusCode != 200) {
      throw Exception('Failed to obtain IGDB token (${resp.statusCode})');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    _accessToken = data['access_token'] as String?;
    final expiresIn = data['expires_in'] as int? ?? 0;
    _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
  }

  Future<List<MockMediaItem>> searchGames(String query) async {
    await _ensureToken();

    final uri = Uri.https('api.igdb.com', '/v4/games');
    final body = '''
search "$query";
fields id,name,first_release_date,summary,cover.image_id;
limit 20;
''';

    final resp = await http.post(
      uri,
      headers: {
        'Client-ID': ApiKeys.igdbClientId,
        'Authorization': 'Bearer $_accessToken',
        'Accept': 'application/json',
      },
      body: body,
    );

    if (resp.statusCode != 200) {
      throw Exception('IGDB search failed (${resp.statusCode})');
    }

    final list = jsonDecode(resp.body) as List<dynamic>;
    final maps = list.cast<Map<String, dynamic>>();
    return maps.map(_mapGame).toList();
  }

  MockMediaItem _mapGame(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final name = json['name'] as String? ?? 'Untitled game';
    final summary = json['summary'] as String? ?? '';
    final firstRelease = json['first_release_date'];

    int? year;
    if (firstRelease is int) {
      final dt = DateTime.fromMillisecondsSinceEpoch(
        firstRelease * 1000,
        isUtc: true,
      );
      year = dt.year;
    }

    // Build IGDB cover URL from cover.image_id, if present
    String? imageUrl;
    final cover = json['cover'];
    if (cover is Map<String, dynamic>) {
      final imageId = cover['image_id'] as String?;
      if (imageId != null && imageId.isNotEmpty) {
        imageUrl =
            'https://images.igdb.com/igdb/image/upload/t_cover_big/$imageId.jpg';
      }
    }

    final desc = GameDescription(
      summary: summary,
      platforms: null,
      developers: null,
    );

    return MockMediaItem(
      id: 'igdb_game_$id',
      type: 'game',
      title: name,
      subtitle: summary.isNotEmpty ? summary : null,
      year: year,
      rating: null,
      imageUrl: imageUrl,
      desc: desc,
    );
  }
}
