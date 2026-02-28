// lib/data/mock/mock_store.dart
import 'package:flutter/foundation.dart';

import 'mock_media.dart';

/// One custom list of media items (e.g. "Godzilla Movies").
class MockList {
  final String id;
  String title;
  final List<MockMediaItem> items;

  MockList({
    required this.id,
    required this.title,
    List<MockMediaItem>? items,
  }) : items = items ?? [];
}

/// A "snapshot" of a media item at the time you log it to the diary.
/// Works for both mock items and API items.
class DiaryMediaSnapshot {
  final String sourceId; // original item id
  final String type; // 'movie', 'tv', 'book', 'game', 'song', etc.
  final String title;
  final String? subtitle;
  final int? year;
  final String? imageUrl;

  DiaryMediaSnapshot({
    required this.sourceId,
    required this.type,
    required this.title,
    this.subtitle,
    this.year,
    this.imageUrl,
  });
}

/// A diary entry for a single media item.
class DiaryEntry {
  final String id;
  final DiaryMediaSnapshot item;
  double rating;
  String? review;
  final DateTime loggedAt;

  DiaryEntry({
    required this.id,
    required this.item,
    required this.rating,
    required this.loggedAt,
    this.review,
  });
}

/// Central in-memory store used by the UI (lists, watchlist, diary).
class MockStore extends ChangeNotifier {
  MockStore._internal();
  static final MockStore I = MockStore._internal();

  // ---------- LISTS ----------

  final List<MockList> _lists = [];

  List<MockList> get lists => List.unmodifiable(_lists);

  MockList createList(String title) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final list = MockList(id: id, title: title);
    _lists.add(list);
    notifyListeners();
    return list;
  }

  MockList? listById(String id) {
    try {
      return _lists.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  void deleteList(MockList list) {
    _lists.removeWhere((l) => l.id == list.id);
    notifyListeners();
  }

  void addToList(MockList list, MockMediaItem item) {
    // Avoid duplicates
    if (!list.items.any((m) => m.id == item.id)) {
      list.items.add(item);
      notifyListeners();
    }
  }

  /// Some places call `store.notify()`
  void notify() => notifyListeners();

  // ---------- WATCHLIST ----------

  final List<MockMediaItem> _watchlist = [];
  final Set<String> _watchedWatchlistIds =
      {}; // which watchlist items are watched

  List<MockMediaItem> get watchlist => List.unmodifiable(_watchlist);

  bool isInWatchlist(String itemId) {
    return _watchlist.any((m) => m.id == itemId);
  }

  /// Has this watchlist item been marked as watched?
  bool isWatchlistItemWatched(String itemId) {
    return _watchedWatchlistIds.contains(itemId);
  }

  /// Add/remove from watchlist (bookmark button on Detail page).
  void toggleWatchlist(MockMediaItem item) {
    final existingIndex = _watchlist.indexWhere((m) => m.id == item.id);

    if (existingIndex >= 0) {
      _watchlist.removeAt(existingIndex);
      _watchedWatchlistIds.remove(item.id); // clear watched flag when removed
    } else {
      _watchlist.add(item);
    }
    notifyListeners();
  }

  /// Toggle watched/unwatched without removing from watchlist.
  void toggleWatchlistWatched(MockMediaItem item) {
    if (_watchedWatchlistIds.contains(item.id)) {
      _watchedWatchlistIds.remove(item.id);
    } else {
      _watchedWatchlistIds.add(item.id);
    }
    notifyListeners();
  }

  // ---------- DIARY ----------

  final List<DiaryEntry> _diary = [];

  /// Most recent entries first.
  List<DiaryEntry> get diary => List.unmodifiable(
      _diary..sort((a, b) => b.loggedAt.compareTo(a.loggedAt)));

  /// Add a new diary entry given primitive fields, so it works for any item type.
  void addDiaryEntry({
    required String itemId,
    required String type,
    required String title,
    String? subtitle,
    int? year,
    String? imageUrl,
    required double rating,
    String? review,
  }) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();

    final snapshot = DiaryMediaSnapshot(
      sourceId: itemId,
      type: type,
      title: title,
      subtitle: subtitle,
      year: year,
      imageUrl: imageUrl,
    );

    final entry = DiaryEntry(
      id: id,
      item: snapshot,
      rating: rating,
      review: review,
      loggedAt: DateTime.now(),
    );

    _diary.add(entry);
    notifyListeners();
  }

  void deleteDiaryEntry(String id) {
    _diary.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void updateDiaryEntry({
    required String id,
    required double rating,
    required String review,
  }) {
    try {
      final entry = _diary.firstWhere((e) => e.id == id);
      entry.rating = rating;
      entry.review = review;
      notifyListeners();
    } catch (_) {
      // ignore if not found
    }
  }
}
