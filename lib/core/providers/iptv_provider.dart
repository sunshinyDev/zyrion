import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/iptv_provider.dart';
import '../services/xtream_service.dart';

// ── Provider instance ─────────────────────────────────────────────────────────
final iptvProviderDataProvider = StateProvider<IptvProvider?>((ref) => null);

// ── XtreamService ─────────────────────────────────────────────────────────────
final xtreamServiceProvider = Provider<XtreamService?>((ref) {
  final p = ref.watch(iptvProviderDataProvider);
  if (p == null) return null;
  return XtreamService(p);
});

// ── Helper: throws StateError when service not ready ─────────────────────────
// FutureProviders catch this and show loading state via whenReady extension
XtreamService _requireSvc(Ref ref) {
  final svc = ref.watch(xtreamServiceProvider);
  if (svc == null) throw StateError('XtreamService not ready');
  return svc;
}

// ── Live categories ───────────────────────────────────────────────────────────
final liveCategoriesProvider =
    FutureProvider<List<XtreamCategory>>((ref) async {
  final svc = _requireSvc(ref);
  return svc.getLiveCategories();
});

// ── Live streams ──────────────────────────────────────────────────────────────
final liveStreamsProvider =
    FutureProvider.family<List<XtreamStream>, String?>((ref, categoryId) async {
  final svc = _requireSvc(ref);
  return svc.getLiveStreams(categoryId: categoryId);
});

// ── VOD categories ────────────────────────────────────────────────────────────
final vodCategoriesProvider =
    FutureProvider<List<XtreamCategory>>((ref) async {
  final svc = _requireSvc(ref);
  return svc.getVodCategories();
});

// ── VOD streams ───────────────────────────────────────────────────────────────
final vodStreamsProvider =
    FutureProvider.family<List<XtreamStream>, String?>((ref, categoryId) async {
  final svc = _requireSvc(ref);
  return svc.getVodStreams(categoryId: categoryId);
});

// ── Series categories ─────────────────────────────────────────────────────────
final seriesCategoriesProvider =
    FutureProvider<List<XtreamCategory>>((ref) async {
  final svc = _requireSvc(ref);
  return svc.getSeriesCategories();
});

// ── Series list ───────────────────────────────────────────────────────────────
final seriesListProvider =
    FutureProvider.family<List<XtreamSeries>, String?>((ref, categoryId) async {
  final svc = _requireSvc(ref);
  return svc.getSeries(categoryId: categoryId);
});

// ── Series episodes ───────────────────────────────────────────────────────────
final seriesEpisodesProvider =
    FutureProvider.family<Map<String, List<XtreamEpisode>>, int>(
        (ref, seriesId) async {
  final svc = _requireSvc(ref);
  return svc.getSeriesEpisodes(seriesId);
});
