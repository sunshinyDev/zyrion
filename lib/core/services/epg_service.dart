import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/iptv_provider.dart';

class EpgEntry {
  final String title;
  final String? description;
  final DateTime start;
  final DateTime stop;
  final bool isNow;

  const EpgEntry({
    required this.title,
    this.description,
    required this.start,
    required this.stop,
    this.isNow = false,
  });

  String get timeRange {
    String fmt(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '${fmt(start)} – ${fmt(stop)}';
  }

  factory EpgEntry.fromJson(Map<String, dynamic> j) {
    String decodeB64(String? s) {
      if (s == null || s.isEmpty) return '';
      try {
        return utf8.decode(base64Decode(s));
      } catch (_) {
        return s;
      }
    }

    final start = DateTime.tryParse(
            j['start']?.toString() ?? '') ??
        DateTime.now();
    final stop = DateTime.tryParse(
            j['stop']?.toString() ?? '') ??
        DateTime.now().add(const Duration(hours: 1));
    final now = DateTime.now();

    return EpgEntry(
      title: decodeB64(j['title']?.toString()),
      description: decodeB64(j['description']?.toString()),
      start: start,
      stop: stop,
      isNow: now.isAfter(start) && now.isBefore(stop),
    );
  }
}

class EpgService {
  final IptvProvider provider;
  final Dio _dio;

  EpgService(this.provider)
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ));

  Future<List<EpgEntry>> getEpg(int streamId,
      {int limit = 10}) async {
    try {
      final resp = await _dio.get(
        '${provider.baseUrl}/player_api.php',
        queryParameters: {
          'username': provider.username,
          'password': provider.password,
          'action': 'get_simple_data_table',
          'stream_id': streamId,
        },
      );
      final data = resp.data is String
          ? jsonDecode(resp.data as String) as Map<String, dynamic>
          : resp.data as Map<String, dynamic>;

      final listings =
          (data['epg_listings'] as List?) ?? [];
      final now = DateTime.now();

      // Filter to current + upcoming, sort by start
      final entries = listings
          .map((e) =>
              EpgEntry.fromJson(e as Map<String, dynamic>))
          .where((e) => e.stop.isAfter(now))
          .toList()
        ..sort((a, b) => a.start.compareTo(b.start));

      return entries.take(limit).toList();
    } catch (e) {
      debugPrint('[EPG] Error for stream $streamId: $e');
      return [];
    }
  }
}
