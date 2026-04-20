import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class EspnLeague {
  final String id;
  final String name;
  final String slug; // e.g. "soccer/bra.1"
  final String emoji;

  const EspnLeague({
    required this.id,
    required this.name,
    required this.slug,
    required this.emoji,
  });
}

class EspnTeam {
  final String id;
  final String name;
  final String abbreviation;
  final String? logo;
  final String homeAway; // "home" | "away"
  final String score;
  final bool? winner;

  const EspnTeam({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.homeAway,
    required this.score,
    this.logo,
    this.winner,
  });

  factory EspnTeam.fromJson(Map<String, dynamic> j) {
    final team = j['team'] as Map<String, dynamic>;
    return EspnTeam(
      id: team['id']?.toString() ?? '',
      name: team['displayName'] ?? team['name'] ?? '',
      abbreviation: team['abbreviation'] ?? '',
      logo: team['logo'] as String?,
      homeAway: j['homeAway'] ?? 'home',
      score: j['score']?.toString() ?? '',
      winner: j['winner'] as bool?,
    );
  }
}

class EspnEvent {
  final String id;
  final String name;
  final DateTime date;
  final String statusDescription; // "Full Time", "In Progress", "Scheduled"
  final String statusDetail;      // "FT", "45'", "19:00"
  final String statusState;       // "pre" | "in" | "post"
  final bool completed;
  final String? venue;
  final List<EspnTeam> teams;
  final String leagueName;

  const EspnEvent({
    required this.id,
    required this.name,
    required this.date,
    required this.statusDescription,
    required this.statusDetail,
    required this.statusState,
    required this.completed,
    this.venue,
    required this.teams,
    required this.leagueName,
  });

  EspnTeam? get homeTeam =>
      teams.where((t) => t.homeAway == 'home').firstOrNull;
  EspnTeam? get awayTeam =>
      teams.where((t) => t.homeAway == 'away').firstOrNull;

  bool get isLive => statusState == 'in';
  bool get isPre => statusState == 'pre';
  bool get isPost => statusState == 'post';

  factory EspnEvent.fromJson(
      Map<String, dynamic> j, String leagueName) {
    final comp = (j['competitions'] as List).first as Map<String, dynamic>;
    final status = comp['status'] as Map<String, dynamic>;
    final statusType = status['type'] as Map<String, dynamic>;

    final teams = (comp['competitors'] as List)
        .map((t) => EspnTeam.fromJson(t as Map<String, dynamic>))
        .toList();

    final venue = comp['venue'] != null
        ? (comp['venue'] as Map<String, dynamic>)['fullName'] as String?
        : null;

    return EspnEvent(
      id: j['id']?.toString() ?? '',
      name: j['name'] ?? '',
      date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
      statusDescription:
          statusType['description'] ?? statusType['name'] ?? '',
      statusDetail: statusType['shortDetail'] ??
          statusType['detail'] ??
          '',
      statusState: statusType['state'] ?? 'pre',
      completed: statusType['completed'] == true,
      venue: venue,
      teams: teams,
      leagueName: leagueName,
    );
  }
}

// ── Available leagues ─────────────────────────────────────────────────────────

const kEspnLeagues = [
  EspnLeague(
    id: 'bra1',
    name: 'Brasileirão',
    slug: 'soccer/bra.1',
    emoji: '🇧🇷',
  ),
  EspnLeague(
    id: 'ucl',
    name: 'Champions League',
    slug: 'soccer/uefa.champions',
    emoji: '⭐',
  ),
  EspnLeague(
    id: 'epl',
    name: 'Premier League',
    slug: 'soccer/eng.1',
    emoji: '🏴󠁧󠁢󠁥󠁮󠁧󠁿',
  ),
  EspnLeague(
    id: 'laliga',
    name: 'La Liga',
    slug: 'soccer/esp.1',
    emoji: '🇪🇸',
  ),
  EspnLeague(
    id: 'seriea',
    name: 'Serie A',
    slug: 'soccer/ita.1',
    emoji: '🇮🇹',
  ),
  EspnLeague(
    id: 'libertadores',
    name: 'Libertadores',
    slug: 'soccer/conmebol.libertadores',
    emoji: '🏆',
  ),
  EspnLeague(
    id: 'nba',
    name: 'NBA',
    slug: 'basketball/nba',
    emoji: '🏀',
  ),
  EspnLeague(
    id: 'nfl',
    name: 'NFL',
    slug: 'football/nfl',
    emoji: '🏈',
  ),
];

// ── Service ───────────────────────────────────────────────────────────────────

class EspnService {
  static final _dio = Dio(BaseOptions(
    baseUrl: 'https://site.api.espn.com/apis/site/v2/sports/',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  static Future<List<EspnEvent>> getScoreboard(EspnLeague league) async {
    try {
      final resp = await _dio.get('${league.slug}/scoreboard');
      final data = resp.data as Map<String, dynamic>;
      final events = data['events'] as List? ?? [];
      return events
          .map((e) =>
              EspnEvent.fromJson(e as Map<String, dynamic>, league.name))
          .toList();
    } catch (e) {
      debugPrint('[ESPN] Error fetching ${league.slug}: $e');
      return [];
    }
  }

  /// Fetch all leagues in parallel
  static Future<Map<String, List<EspnEvent>>> getAllScoreboards() async {
    final results = await Future.wait(
      kEspnLeagues.map((l) async {
        final events = await getScoreboard(l);
        return MapEntry(l.id, events);
      }),
    );
    return Map.fromEntries(results);
  }
}
