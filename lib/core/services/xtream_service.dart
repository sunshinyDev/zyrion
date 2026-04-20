import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/iptv_provider.dart';

// ── Safe type helpers ─────────────────────────────────────────────────────────
int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

// ── Data models ───────────────────────────────────────────────────────────────

class XtreamCategory {
  final String id;
  final String name;

  const XtreamCategory({required this.id, required this.name});

  factory XtreamCategory.fromJson(Map<String, dynamic> j) => XtreamCategory(
        id: j['category_id']?.toString() ?? '',
        name: j['category_name'] ?? '',
      );

  Map<String, dynamic> toJson() => {'category_id': id, 'category_name': name};
}

class XtreamStream {
  final int streamId;
  final String name;
  final String? icon;
  final String? categoryId;
  final String streamType;
  final double rating;
  final String? containerExtension;
  final String? year;

  const XtreamStream({
    required this.streamId,
    required this.name,
    this.icon,
    this.categoryId,
    required this.streamType,
    this.rating = 0,
    this.containerExtension,
    this.year,
  });

  factory XtreamStream.fromJson(Map<String, dynamic> j) => XtreamStream(
        streamId: _toInt(j['stream_id']) ?? 0,
        name: j['name']?.toString() ?? j['title']?.toString() ?? '',
        icon: j['stream_icon']?.toString(),
        categoryId: j['category_id']?.toString(),
        streamType: j['stream_type']?.toString() ?? 'live',
        rating: _toDouble(j['rating']) ?? 0,
        containerExtension: j['container_extension']?.toString(),
        year: j['year']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'stream_id': streamId,
        'name': name,
        'stream_icon': icon,
        'category_id': categoryId,
        'stream_type': streamType,
        'rating': rating,
        'container_extension': containerExtension,
        'year': year,
      };
}

class XtreamSeries {
  final int seriesId;
  final String name;
  final String? cover;
  final String? plot;
  final String? cast;
  final String? genre;
  final String? releaseDate;
  final double rating;
  final String? categoryId;

  const XtreamSeries({
    required this.seriesId,
    required this.name,
    this.cover,
    this.plot,
    this.cast,
    this.genre,
    this.releaseDate,
    this.rating = 0,
    this.categoryId,
  });

  factory XtreamSeries.fromJson(Map<String, dynamic> j) => XtreamSeries(
        seriesId: _toInt(j['series_id']) ?? 0,
        name: j['name']?.toString() ?? '',
        cover: j['cover']?.toString(),
        plot: j['plot']?.toString(),
        cast: j['cast']?.toString(),
        genre: j['genre']?.toString(),
        releaseDate: j['releaseDate']?.toString(),
        rating: _toDouble(j['rating']) ??
            _toDouble(j['rating_5based']) ??
            0,
        categoryId: j['category_id']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'series_id': seriesId,
        'name': name,
        'cover': cover,
        'plot': plot,
        'cast': cast,
        'genre': genre,
        'releaseDate': releaseDate,
        'rating': rating,
        'category_id': categoryId,
      };
}

class XtreamEpisode {
  final int id;
  final String title;
  final int season;
  final int episode;
  final String? info;
  final String containerExtension;

  const XtreamEpisode({
    required this.id,
    required this.title,
    required this.season,
    required this.episode,
    this.info,
    this.containerExtension = 'ts',
  });

  factory XtreamEpisode.fromJson(Map<String, dynamic> j) => XtreamEpisode(
        id: _toInt(j['id']) ?? 0,
        title: j['title']?.toString() ?? 'Episódio',
        season: _toInt(j['season']) ?? 1,
        episode: _toInt(j['episode_num']) ?? 1,
        info: j['info']?.toString(),
        containerExtension:
            j['container_extension']?.toString() ?? 'ts',
      );
}

// ── Auth result ───────────────────────────────────────────────────────────────

class XtreamAuthResult {
  final String? error;       // null = success
  final String? workingHost;
  final IptvUserInfo? userInfo;

  const XtreamAuthResult({this.error, this.workingHost, this.userInfo});
  bool get success => error == null;
}

// ── Cache helper ──────────────────────────────────────────────────────────────

class _Cache {
  static const _ttlLive = Duration(minutes: 10);
  static const _ttlVod = Duration(hours: 6);
  static const _ttlSeries = Duration(hours: 6);
  static const _ttlCategories = Duration(hours: 12);

  static String _key(String type, String? catId) =>
      'xtream_cache_${type}_${catId ?? "all"}';
  static String _tsKey(String type, String? catId) =>
      'xtream_ts_${type}_${catId ?? "all"}';

  static Duration _ttl(String type) {
    switch (type) {
      case 'live':
        return _ttlLive;
      case 'vod':
        return _ttlVod;
      case 'series':
        return _ttlSeries;
      default:
        return _ttlCategories;
    }
  }

  static Future<String?> get(String type, String? catId) async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_tsKey(type, catId));
    if (ts == null) return null;
    final age = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(ts));
    if (age > _ttl(type)) {
      // expired — remove
      await prefs.remove(_key(type, catId));
      await prefs.remove(_tsKey(type, catId));
      return null;
    }
    return prefs.getString(_key(type, catId));
  }

  static Future<void> set(
      String type, String? catId, String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(type, catId), data);
    await prefs.setInt(
        _tsKey(type, catId), DateTime.now().millisecondsSinceEpoch);
  }

  /// Returns remaining TTL as human-readable string, or null if not cached
  static Future<String?> remainingTtl(
      String type, String? catId) async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_tsKey(type, catId));
    if (ts == null) return null;
    final cached = DateTime.fromMillisecondsSinceEpoch(ts);
    final expires = cached.add(_ttl(type));
    final remaining = expires.difference(DateTime.now());
    if (remaining.isNegative) return null;
    if (remaining.inHours >= 1) return '${remaining.inHours}h restantes';
    return '${remaining.inMinutes}min restantes';
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys()
        .where((k) => k.startsWith('xtream_'))
        .toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}

// ── Service ───────────────────────────────────────────────────────────────────

class XtreamService {
  final IptvProvider provider;
  final Dio _dio;

  XtreamService(this.provider)
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          // Large timeout for big responses (series list ~1.3MB per category)
          receiveTimeout: const Duration(seconds: 60),
        ));

  String get _effectiveBaseUrl => provider.baseUrl;

  // ── Auth ──────────────────────────────────────────────────────────

  Future<XtreamAuthResult> authenticateWithHostsFull(
      List<String> hostUrls) async {
    if (hostUrls.isEmpty) {
      return const XtreamAuthResult(
          error: 'Nenhum servidor disponível para este provedor.');
    }

    for (final baseUrl in hostUrls) {
      try {
        final url = baseUrl.endsWith('/')
            ? '${baseUrl}player_api.php'
            : '$baseUrl/player_api.php';
        debugPrint('[Xtream] Trying: $url');
        final resp = await _dio.get(
          url,
          queryParameters: {
            'username': provider.username,
            'password': provider.password,
          },
        );
        final raw = resp.data;
        final data = raw is String
            ? jsonDecode(raw) as Map<String, dynamic>
            : raw as Map<String, dynamic>;

        final userInfoJson =
            data['user_info'] as Map<String, dynamic>?;
        final auth =
            (userInfoJson?['auth'] as num?)?.toInt();

        if (auth == 1) {
          debugPrint('[Xtream] Connected via: $baseUrl');
          final userInfo = userInfoJson != null
              ? IptvUserInfo.fromJson(userInfoJson)
              : null;
          return XtreamAuthResult(
            workingHost: baseUrl,
            userInfo: userInfo,
          );
        }
        return const XtreamAuthResult(
            error: 'Usuário ou senha inválidos.');
      } on DioException catch (e) {
        debugPrint('[Xtream] Failed $baseUrl: ${e.message}');
        continue;
      } catch (e) {
        debugPrint('[Xtream] Error $baseUrl: $e');
        continue;
      }
    }
    return const XtreamAuthResult(
        error:
            'Não foi possível conectar a nenhum servidor do provedor.');
  }

  // Legacy helpers
  Future<String?> authenticateWithHosts(List<String> hosts) async {
    final r = await authenticateWithHostsFull(hosts);
    return r.error;
  }

  // ── Fetch with cache ──────────────────────────────────────────────

  Future<List<XtreamCategory>> getLiveCategories() =>
      _getCachedCategories('live_cats', 'get_live_categories');

  Future<List<XtreamCategory>> getVodCategories() =>
      _getCachedCategories('vod_cats', 'get_vod_categories');

  Future<List<XtreamCategory>> getSeriesCategories() =>
      _getCachedCategories('series_cats', 'get_series_categories');

  Future<List<XtreamCategory>> _getCachedCategories(
      String cacheType, String action) async {
    final cached = await _Cache.get(cacheType, null);
    if (cached != null) {
      final list = jsonDecode(cached) as List;
      return list
          .map((e) =>
              XtreamCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final result = await _fetchCategories(action);
    await _Cache.set(cacheType, null,
        jsonEncode(result.map((e) => e.toJson()).toList()));
    return result;
  }

  Future<List<XtreamCategory>> _fetchCategories(String action) async {
    final resp = await _dio.get(
      '$_effectiveBaseUrl/player_api.php',
      queryParameters: {
        'username': provider.username,
        'password': provider.password,
        'action': action,
      },
    );
    final list = resp.data is String
        ? jsonDecode(resp.data as String)
        : resp.data as List;
    return (list as List)
        .map((e) =>
            XtreamCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<XtreamStream>> getLiveStreams(
      {String? categoryId}) async {
    final cacheKey = 'live_${categoryId ?? "all"}';
    final cached = await _Cache.get('live', categoryId);
    if (cached != null) {
      final list = jsonDecode(cached) as List;
      return list
          .map((e) =>
              XtreamStream.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final result = await _fetchStreams(
        'get_live_streams', categoryId: categoryId);
    await _Cache.set('live', categoryId,
        jsonEncode(result.map((e) => e.toJson()).toList()));
    return result;
  }

  Future<List<XtreamStream>> getVodStreams(
      {String? categoryId}) async {
    final cached = await _Cache.get('vod', categoryId);
    if (cached != null) {
      final list = jsonDecode(cached) as List;
      return list
          .map((e) =>
              XtreamStream.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final result = await _fetchStreams(
        'get_vod_streams', categoryId: categoryId);
    await _Cache.set('vod', categoryId,
        jsonEncode(result.map((e) => e.toJson()).toList()));
    return result;
  }

  Future<List<XtreamSeries>> getSeries({String? categoryId}) async {
    final cached = await _Cache.get('series', categoryId);
    if (cached != null) {
      final list = jsonDecode(cached) as List;
      return list
          .map((e) =>
              XtreamSeries.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final result =
        await _fetchSeriesList(categoryId: categoryId);
    await _Cache.set('series', categoryId,
        jsonEncode(result.map((e) => e.toJson()).toList()));
    return result;
  }

  Future<List<XtreamStream>> _fetchStreams(String action,
      {String? categoryId}) async {
    final params = <String, dynamic>{
      'username': provider.username,
      'password': provider.password,
      'action': action,
    };
    if (categoryId != null) params['category_id'] = categoryId;
    final resp = await _dio.get(
      '$_effectiveBaseUrl/player_api.php',
      queryParameters: params,
    );
    final list = resp.data is String
        ? jsonDecode(resp.data as String)
        : resp.data as List;
    return (list as List)
        .map((e) =>
            XtreamStream.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<XtreamSeries>> _fetchSeriesList(
      {String? categoryId}) async {
    final params = <String, dynamic>{
      'username': provider.username,
      'password': provider.password,
      'action': 'get_series',
    };
    if (categoryId != null) params['category_id'] = categoryId;
    final resp = await _dio.get(
      '$_effectiveBaseUrl/player_api.php',
      queryParameters: params,
    );
    final list = resp.data is String
        ? jsonDecode(resp.data as String)
        : resp.data as List;
    return (list as List)
        .map((e) =>
            XtreamSeries.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, List<XtreamEpisode>>> getSeriesEpisodes(
      int seriesId) async {
    final cacheKey = 'eps_$seriesId';
    final cached = await _Cache.get(cacheKey, null);
    if (cached != null) {
      final map = jsonDecode(cached) as Map<String, dynamic>;
      return map.map((season, eps) => MapEntry(
            season,
            (eps as List)
                .map((e) => XtreamEpisode.fromJson(
                    e as Map<String, dynamic>))
                .toList(),
          ));
    }

    final resp = await _dio.get(
      '$_effectiveBaseUrl/player_api.php',
      queryParameters: {
        'username': provider.username,
        'password': provider.password,
        'action': 'get_series_info',
        'series_id': seriesId,
      },
    );
    final data = resp.data is String
        ? jsonDecode(resp.data as String) as Map<String, dynamic>
        : resp.data as Map<String, dynamic>;

    final episodes =
        data['episodes'] as Map<String, dynamic>? ?? {};
    final result = <String, List<XtreamEpisode>>{};
    episodes.forEach((season, eps) {
      result[season] = (eps as List)
          .map((e) =>
              XtreamEpisode.fromJson(e as Map<String, dynamic>))
          .toList();
    });

    // Cache episodes for 24h
    await _Cache.set(cacheKey, null, jsonEncode(
      result.map((s, eps) => MapEntry(
            s,
            eps
                .map((e) => {
                      'id': e.id,
                      'title': e.title,
                      'season': e.season,
                      'episode_num': e.episode,
                      'container_extension': e.containerExtension,
                    })
                .toList(),
          )),
    ));

    return result;
  }

  // ── Cache TTL info ────────────────────────────────────────────────
  static Future<String?> cacheTtl(String type, String? catId) =>
      _Cache.remainingTtl(type, catId);

  static Future<void> clearCache() => _Cache.clearAll();

  // ── Stream URLs ───────────────────────────────────────────────────
  String liveUrl(int streamId) =>
      provider.liveStreamUrl(streamId.toString());

  String vodUrl(int streamId, String ext) =>
      provider.vodStreamUrl(streamId.toString(), ext);

  String seriesUrl(int streamId, String ext) =>
      provider.seriesStreamUrl(streamId.toString(), ext);
}
