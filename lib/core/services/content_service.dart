import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/content_model.dart';

/// Fetches content metadata from Firestore.
/// Structure: /content/{id} documents with ContentModel fields.
class ContentService {
  final FirebaseFirestore _firestore;

  ContentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('content');

  /// Stream all featured content for the home carousel.
  Stream<List<ContentModel>> watchFeatured() {
    return _collection
        .where('isFeatured', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snap) =>
            snap.docs.map(ContentModel.fromFirestore).toList());
  }

  /// Stream movies.
  Stream<List<ContentModel>> watchMovies({int limit = 20}) {
    return _collection
        .where('type', isEqualTo: 'movie')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map(ContentModel.fromFirestore).toList());
  }

  /// Stream series.
  Stream<List<ContentModel>> watchSeries({int limit = 20}) {
    return _collection
        .where('type', isEqualTo: 'series')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map(ContentModel.fromFirestore).toList());
  }

  /// Stream live channels.
  Stream<List<ContentModel>> watchLiveChannels() {
    return _collection
        .where('type', isEqualTo: 'liveChannel')
        .where('isLive', isEqualTo: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map(ContentModel.fromFirestore).toList());
  }

  /// Fetch a single content item by ID.
  Future<ContentModel?> getContent(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return ContentModel.fromFirestore(doc);
  }

  /// Search content by title (client-side filtering for simplicity).
  /// For production, use Algolia or Typesense for full-text search.
  Future<List<ContentModel>> search(String query) async {
    final snap = await _collection.get();
    final all = snap.docs.map(ContentModel.fromFirestore).toList();
    final q = query.toLowerCase();
    return all
        .where((c) =>
            c.title.toLowerCase().contains(q) ||
            c.genres.any((g) => g.toLowerCase().contains(q)))
        .toList();
  }
}

final contentServiceProvider = Provider<ContentService>((ref) {
  return ContentService();
});

// Stream providers for reactive UI
final featuredContentProvider = StreamProvider<List<ContentModel>>((ref) {
  return ref.watch(contentServiceProvider).watchFeatured();
});

final moviesProvider = StreamProvider<List<ContentModel>>((ref) {
  return ref.watch(contentServiceProvider).watchMovies();
});

final seriesProvider = StreamProvider<List<ContentModel>>((ref) {
  return ref.watch(contentServiceProvider).watchSeries();
});

final liveChannelsProvider = StreamProvider<List<ContentModel>>((ref) {
  return ref.watch(contentServiceProvider).watchLiveChannels();
});
