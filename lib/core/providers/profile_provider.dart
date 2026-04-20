import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile.dart';
import '../providers/iptv_provider.dart';
import '../services/profile_service.dart';

// ── Active profile ────────────────────────────────────────────────────────────
final activeProfileProvider = StateProvider<AppProfile?>((ref) => null);

// ── Profile service ───────────────────────────────────────────────────────────
final profileServiceProvider = Provider<ProfileService?>((ref) {
  final p = ref.watch(iptvProviderDataProvider);
  if (p == null) return null;
  return ProfileService(p.providerCode);
});

// ── All profiles ──────────────────────────────────────────────────────────────
final profilesProvider = FutureProvider<List<AppProfile>>((ref) async {
  final svc = ref.watch(profileServiceProvider);
  if (svc == null) return [];
  return svc.getProfiles();
});

// ── Watch history (stream, filtered by type) ──────────────────────────────────
final watchHistoryProvider =
    StreamProvider.family<List<WatchItem>, String?>((ref, type) {
  final svc = ref.watch(profileServiceProvider);
  final profile = ref.watch(activeProfileProvider);
  if (svc == null || profile == null) return const Stream.empty();
  return svc.watchHistory(profile.id, type: type);
});

// ── Persist active profile id ─────────────────────────────────────────────────
const _kActiveProfileKey = 'active_profile_id';

Future<void> saveActiveProfileId(String id) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kActiveProfileKey, id);
}

Future<String?> loadActiveProfileId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_kActiveProfileKey);
}

Future<void> clearActiveProfileId() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kActiveProfileKey);
}
