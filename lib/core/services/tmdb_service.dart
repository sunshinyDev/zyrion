import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

// TMDB public API — no key needed for basic search
// Uses the v3 API with a read-only public token approach
// For production, add your own API key via --dart-define=TMDB_KEY=xxx

class TmdbMedia {
  final int id;
  final String title;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final double voteAverage;
  final List<String> genres;
  final String mediaType; // 'movie' | 'tv'

  const TmdbMedia({
    required this.id,
    required this.title,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.voteAverage = 0,
    this.genres = const [],
    required this.mediaType,
  });

  String? get posterUrl => posterPath != null
      ? 'https://image.tmdb.org/t/p/w500$posterPath'
      : null;

  String? get backdropUrl => backdropPath != null
      ? 'https://image.tmdb.org/t/p/w780$backdropPath'
      : null;

  factory TmdbMedia.fromJson(Map<String, dynamic> j, String type) {
    final title = j['title'] ?? j['name'] ?? '';
    return TmdbMedia(
      id: (j['id'] as num?)?.toInt() ?? 0,
      title: title.toString(),
      overview: j['overview']?.toString(),
      posterPath: j['poster_path']?.toString(),
      backdropPath: j['backdrop_path']?.toString(),
      releaseDate:
          (j['release_date'] ?? j['first_air_date'])?.toString(),
      voteAverage:
          (j['vote_average'] as num?)?.toDouble() ?? 0,
      mediaType: type,
    );
  }
}

class TmdbService {
  // Public TMDB API key (read-only, safe to embed)
  static const _apiKey =
      const String.fromEnvironment('TMDB_KEY', defaultValue: '');

  static final _dio = Dio(BaseOptions(
    baseUrl: 'https://api.themoviedb.org/3/',
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 10),
    queryParameters: {
      'api_key': _apiKey.isNotEmpty ? _apiKey : null,
      'language': 'pt-BR',
    },
  ));

  /// Search for a movie or TV show by name
  static Future<TmdbMedia?> search(String title,
      {String type = 'multi'}) async {
    if (_apiKey.isEmpty) return null;
    try {
      // Clean title: remove year, quality tags, etc.
      final clean = _cleanTitle(title);
      final resp = await _dio.get(
        'search/$type',
        queryParameters: {'query': clean, 'page': 1},
      );
      final results =
          (resp.data['results'] as List?) ?? [];
      if (results.isEmpty) return null;
      final first = results.first as Map<String, dynamic>;
      final mediaType =
          first['media_type']?.toString() ?? type;
      return TmdbMedia.fromJson(first, mediaType);
    } catch (e) {
      debugPrint('[TMDB] search error: $e');
      return null;
    }
  }

  /// Get movie details by TMDB id
  static Future<TmdbMedia?> getMovie(int id) async {
    if (_apiKey.isEmpty) return null;
    try {
      final resp = await _dio.get('movie/$id');
      return TmdbMedia.fromJson(
          resp.data as Map<String, dynamic>, 'movie');
    } catch (e) {
      debugPrint('[TMDB] getMovie error: $e');
      return null;
    }
  }

  /// Get TV show details by TMDB id
  static Future<TmdbMedia?> getTv(int id) async {
    if (_apiKey.isEmpty) return null;
    try {
      final resp = await _dio.get('tv/$id');
      return TmdbMedia.fromJson(
          resp.data as Map<String, dynamic>, 'tv');
    } catch (e) {
      debugPrint('[TMDB] getTv error: $e');
      return null;
    }
  }

  static String _cleanTitle(String title) {
    return title
        .replaceAll(RegExp(r'\(\d{4}\)'), '') // remove (2024)
        .replaceAll(RegExp(r'\b(FHD|HD|SD|4K|UHD|H265|H264)\b',
            caseSensitive: false), '')
        .replaceAll(RegExp(r'\[.*?\]'), '') // remove [tags]
        .replaceAll(RegExp(r'[♦️⭐✔️]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
