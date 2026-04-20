import 'package:firebase_database/firebase_database.dart';
import '../models/profile.dart';

class ProfileService {
  final String providerCode;
  final FirebaseDatabase _db;

  ProfileService(this.providerCode)
      : _db = FirebaseDatabase.instance;

  DatabaseReference get _profilesRef =>
      _db.ref('profiles/$providerCode');

  DatabaseReference get _historyRef =>
      _db.ref('watch_history/$providerCode');

  // ── Profiles ──────────────────────────────────────────────────────

  Future<List<AppProfile>> getProfiles() async {
    final snap = await _profilesRef.get();
    if (!snap.exists || snap.value == null) return [];
    final map = Map<dynamic, dynamic>.from(snap.value as Map);
    return map.entries
        .map((e) => AppProfile.fromMap(
            e.key.toString(),
            Map<dynamic, dynamic>.from(e.value as Map)))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<AppProfile> createProfile(String name, String avatar) async {
    final ref = _profilesRef.push();
    final profile = AppProfile(
      id: ref.key!,
      name: name,
      avatar: avatar,
      createdAt: DateTime.now(),
    );
    await ref.set(profile.toMap());
    return profile;
  }

  Future<void> deleteProfile(String profileId) async {
    await _profilesRef.child(profileId).remove();
    await _historyRef.child(profileId).remove();
  }

  // ── Watch history ─────────────────────────────────────────────────

  Future<List<WatchItem>> getHistory(String profileId,
      {String? type, int limit = 30}) async {
    final snap = await _historyRef.child(profileId).get();
    if (!snap.exists || snap.value == null) return [];
    final map = Map<dynamic, dynamic>.from(snap.value as Map);
    var items = map.values
        .map((v) =>
            WatchItem.fromMap(Map<dynamic, dynamic>.from(v as Map)))
        .where((i) => type == null || i.type == type)
        .toList()
      ..sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
    if (items.length > limit) items = items.sublist(0, limit);
    return items;
  }

  Future<void> addToHistory(String profileId, WatchItem item) async {
    // Use item.id as key so same content overwrites previous entry
    await _historyRef
        .child(profileId)
        .child(item.id)
        .set(item.toMap());

    // Keep only last 100 items per profile
    await _pruneHistory(profileId);
  }

  Future<void> _pruneHistory(String profileId) async {
    final snap = await _historyRef.child(profileId).get();
    if (!snap.exists || snap.value == null) return;
    final map = Map<dynamic, dynamic>.from(snap.value as Map);
    if (map.length <= 100) return;

    final items = map.entries
        .map((e) => MapEntry(
            e.key.toString(),
            WatchItem.fromMap(
                Map<dynamic, dynamic>.from(e.value as Map))))
        .toList()
      ..sort((a, b) =>
          b.value.watchedAt.compareTo(a.value.watchedAt));

    // Remove oldest beyond 100
    for (final entry in items.sublist(100)) {
      await _historyRef
          .child(profileId)
          .child(entry.key)
          .remove();
    }
  }

  Future<void> removeFromHistory(
      String profileId, String itemId) async {
    await _historyRef.child(profileId).child(itemId).remove();
  }

  Stream<List<WatchItem>> watchHistory(String profileId,
      {String? type}) {
    return _historyRef.child(profileId).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <WatchItem>[];
      }
      final map = Map<dynamic, dynamic>.from(
          event.snapshot.value as Map);
      var items = map.values
          .map((v) => WatchItem.fromMap(
              Map<dynamic, dynamic>.from(v as Map)))
          .where((i) => type == null || i.type == type)
          .toList()
        ..sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
      return items.take(30).toList();
    });
  }
}
