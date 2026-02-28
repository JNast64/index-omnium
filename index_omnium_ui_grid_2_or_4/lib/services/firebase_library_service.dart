import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

//  Used when creating LibraryItem from mock items if needed
import '../data/mock/mock_media.dart';

/// Firestore-backed library for a single signed-in user.
///
/// Collections:
///   users/{uid}
///     lists/{listId}
///       items/{itemId}
///     diaryEntries/{entryId}
class FirebaseLibraryService {
  // ---------------------------------------------------------------------------
  // Singleton wiring
  // ---------------------------------------------------------------------------

  FirebaseLibraryService._({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  static final FirebaseLibraryService instance = FirebaseLibraryService._();

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  User get _user {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user in FirebaseLibraryService.');
    }
    return user;
  }

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users').doc(_user.uid);

  CollectionReference<Map<String, dynamic>> get _listsCol =>
      _userDoc.collection('lists');

  CollectionReference<Map<String, dynamic>> _itemsCol(String listId) =>
      _listsCol.doc(listId).collection('items');

  CollectionReference<Map<String, dynamic>> get _diaryCol =>
      _userDoc.collection('diaryEntries');

  // ---------------------------------------------------------------------------
  // Lists (including special "watchlist")
  // ---------------------------------------------------------------------------

  /// Watch all lists for the current user.
  Stream<List<LibraryList>> watchLists() {
    return _listsCol.orderBy('createdAt', descending: false).snapshots().map(
          (snap) => snap.docs.map(LibraryList.fromSnapshot).toList(),
        );
  }

  /// Create a new list.
  Future<String> createList(String name) async {
    final now = FieldValue.serverTimestamp();
    final doc = await _listsCol.add({
      'name': name,
      'isWatchlist': false,
      'createdAt': now,
      'updatedAt': now,
    });
    return doc.id;
  }

  /// Rename an existing list.
  Future<void> renameList({
    required String listId,
    required String newName,
  }) async {
    await _listsCol.doc(listId).update({
      'name': newName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a list and all of its items.
  Future<void> deleteList(String listId) async {
    final items = await _itemsCol(listId).get();
    for (final doc in items.docs) {
      await doc.reference.delete();
    }
    await _listsCol.doc(listId).delete();
  }

  /// Watch items for a particular list.
  Stream<List<LibraryItem>> watchListItems(String listId) {
    return _itemsCol(listId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs.map(LibraryItem.fromSnapshot).toList(),
        );
  }

  /// Upsert a list item (used by lists & watchlist).
  Future<void> upsertItem({
    required String listId,
    required LibraryItem item,
  }) async {
    final now = FieldValue.serverTimestamp();

    if (item.id.isEmpty) {
      // New document
      await _itemsCol(listId).add({
        ...item.toMap(),
        'createdAt': now,
        'updatedAt': now,
      });
    } else {
      // Existing document
      await _itemsCol(listId).doc(item.id).set(
        {
          ...item.toMap(),
          'updatedAt': now,
        },
        SetOptions(merge: true),
      );
    }
  }

  /// Remove a single item from a list by its document id.
  Future<void> removeItem({
    required String listId,
    required String itemId,
  }) async {
    await _itemsCol(listId).doc(itemId).delete();
  }

  // ---------------------------------------------------------------------------
  // Special watchlist helpers
  // ---------------------------------------------------------------------------

  /// Ensure the user has a special "watchlist" list and return its id.
  Future<String> ensureWatchlist() async {
    final existing =
        await _listsCol.where('isWatchlist', isEqualTo: true).get();
    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    final now = FieldValue.serverTimestamp();
    final doc = await _listsCol.add({
      'name': 'Watchlist',
      'isWatchlist': true,
      'createdAt': now,
      'updatedAt': now,
    });
    return doc.id;
  }

  /// Convenience: add an item straight to the watchlist.
  Future<void> addItemToWatchlist(LibraryItem item) async {
    final watchlistId = await ensureWatchlist();
    await upsertItem(listId: watchlistId, item: item);
  }

  /// Stream of items specifically in the user's watchlist.
  ///
  /// Convenience for `watchListItems(await ensureWatchlist())`.
  Stream<List<LibraryItem>> watchWatchlistItems() async* {
    final watchlistId = await ensureWatchlist();
    yield* watchListItems(watchlistId);
  }

  /// Remove all watchlist entries that refer to a given source id (TMDB / IGDB, etc.).
  Future<void> removeFromWatchlistBySourceId(String sourceId) async {
    final watchlistId = await ensureWatchlist();
    final query = await _itemsCol(watchlistId)
        .where('sourceId', isEqualTo: sourceId)
        .get();

    for (final doc in query.docs) {
      await doc.reference.delete();
    }
  }

  /// Update just the `watched` flag for a watchlist item.
  Future<void> setWatchlistItemWatched({
    required String itemId,
    required bool watched,
  }) async {
    final watchlistId = await ensureWatchlist();
    await _itemsCol(watchlistId).doc(itemId).update({
      'watched': watched,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
  // Diary entries
  // ---------------------------------------------------------------------------

  Stream<List<DiaryEntry>> watchDiaryEntries() {
    return _diaryCol.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs.map(DiaryEntry.fromSnapshot).toList(),
        );
  }

  Future<DiaryEntry?> fetchDiaryEntry(String entryId) async {
    final doc = await _diaryCol.doc(entryId).get();
    if (!doc.exists) return null;
    return DiaryEntry.fromSnapshot(doc);
  }

  Future<void> saveDiaryEntry(DiaryEntry entry) async {
    final now = FieldValue.serverTimestamp();

    if (entry.id == null) {
      await _diaryCol.add({
        ...entry.toMap(),
        'createdAt': now,
        'updatedAt': now,
      });
    } else {
      await _diaryCol.doc(entry.id).set(
        {
          ...entry.toMap(),
          'updatedAt': now,
        },
        SetOptions(merge: true),
      );
    }
  }

  Future<void> deleteDiaryEntry(String entryId) async {
    await _diaryCol.doc(entryId).delete();
  }
}

// ============================================================================
// Data models used by the service
// ============================================================================

class LibraryList {
  LibraryList({
    required this.id,
    required this.name,
    required this.isWatchlist,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final bool isWatchlist;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isWatchlist': isWatchlist,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory LibraryList.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return LibraryList(
      id: doc.id,
      name: data['name'] as String? ?? 'Untitled list',
      isWatchlist: data['isWatchlist'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class LibraryItem {
  LibraryItem({
    this.id = '',
    required this.title,
    this.subtitle,
    required this.mediaType,
    required this.source,
    required this.sourceId,
    this.imageUrl,
    this.watched = false,
  });

  /// Firestore document id (empty when creating a brand new item).
  final String id;

  final String title;
  final String? subtitle;

  /// E.g. 'movie', 'tv', 'book', 'game', 'album', 'track'
  final String mediaType;

  /// E.g. 'tmdb', 'googleBooks', 'igdb', 'spotify', 'manual'
  final String source;

  /// The id from the source API (TMDB id, Google Books volume id, etc).
  final String sourceId;

  final String? imageUrl;

  /// Whether the user has marked this as watched (for watchlist).
  final bool watched;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'mediaType': mediaType,
      'source': source,
      'sourceId': sourceId,
      'imageUrl': imageUrl,
      'watched': watched,
    };
  }

  factory LibraryItem.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return LibraryItem(
      id: doc.id,
      title: data['title'] as String? ?? 'Untitled',
      subtitle: data['subtitle'] as String?,
      mediaType: data['mediaType'] as String? ?? 'other',
      source: data['source'] as String? ?? 'manual',
      sourceId: data['sourceId'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      watched: data['watched'] as bool? ?? false,
    );
  }
}

class DiaryEntry {
  DiaryEntry({
    this.id,
    required this.title,
    required this.body,
    this.rating = 3.0,
    this.mediaItemId,
    this.mediaType,
    this.imageUrl,
    this.year,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String title;
  final String body;
  final double rating;

  /// Optional link back to the media item being logged.
  final String? mediaItemId;
  final String? mediaType;
  final String? imageUrl;
  final int? year;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'rating': rating,
      'mediaItemId': mediaItemId,
      'mediaType': mediaType,
      'imageUrl': imageUrl,
      'year': year,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory DiaryEntry.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return DiaryEntry(
      id: doc.id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 3.0,
      mediaItemId: data['mediaItemId'] as String?,
      mediaType: data['mediaType'] as String?,
      imageUrl: data['imageUrl'] as String?,
      year: data['year'] as int?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
