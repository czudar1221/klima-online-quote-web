import 'dart:convert';

import 'package:http/http.dart' as http;

import '../engine/american_odds.dart';
import '../engine/rational.dart';
import 'feed_error.dart';
import 'models.dart';
import 'sport_catalog.dart';

/// ESPN site JSON (same payload as espn.com scoreboards). Not HTML scraping.
class EspnLiveFeed {
  EspnLiveFeed({http.Client? client, DateTime? now})
    : _client = client ?? http.Client(),
      _now = now;

  final http.Client _client;
  final DateTime? _now;

  static const _ua = 'TippmixKalkulator/1.0 (legitimate scoreboard JSON)';

  static const boards = <({String sport, String league})>[
    (sport: 'soccer', league: 'eng.1'),
    (sport: 'soccer', league: 'esp.1'),
    (sport: 'soccer', league: 'ger.1'),
    (sport: 'soccer', league: 'ita.1'),
    (sport: 'soccer', league: 'fra.1'),
    (sport: 'soccer', league: 'ned.1'),
    (sport: 'soccer', league: 'por.1'),
    (sport: 'soccer', league: 'uefa.champions'),
    (sport: 'soccer', league: 'uefa.europa'),
    (sport: 'soccer', league: 'uefa.europa.conf'),
    (sport: 'basketball', league: 'nba'),
    (sport: 'basketball', league: 'nbl'),
    (sport: 'hockey', league: 'nhl'),
    (sport: 'tennis', league: 'atp'),
    (sport: 'tennis', league: 'wta'),
    (sport: 'football', league: 'nfl'),
    (sport: 'football', league: 'college-football'),
    (sport: 'baseball', league: 'mlb'),
    (sport: 'mma', league: 'ufc'),
  ];

  Future<List<SportsMatch>> fetch() async {
    final now = _now ?? DateTime.now().toUtc();
    final dates = [
      for (var i = 0; i < 3; i++)
        DateTime.utc(now.year, now.month, now.day).add(Duration(days: i)),
    ];
    var failures = 0;
    final out = <SportsMatch>[];
    final seen = <String>{};

    for (final board in boards) {
      for (final day in dates) {
        final ymd =
            '${day.year.toString().padLeft(4, '0')}'
            '${day.month.toString().padLeft(2, '0')}'
            '${day.day.toString().padLeft(2, '0')}';
        final uri = Uri.https(
          'site.api.espn.com',
          '/apis/site/v2/sports/${board.sport}/${board.league}/scoreboard',
          {'dates': ymd},
        );
        try {
          final res = await _client.get(uri, headers: {'User-Agent': _ua});
          if (res.statusCode < 200 || res.statusCode >= 300) {
            failures++;
            continue;
          }
          final decoded = jsonDecode(res.body);
          if (decoded is! Map<String, dynamic>) continue;
          for (final match in parseScoreboard(decoded, sport: board.sport)) {
            if (seen.add(match.id)) out.add(match);
          }
        } catch (_) {
          failures++;
        }
      }
    }

    if (out.isEmpty && failures > 0) {
      throw FeedException('network');
    }
    out.sort((a, b) => a.kickoff.compareTo(b.kickoff));
    return out;
  }

  static List<SportsMatch> parseScoreboard(
    Map<String, dynamic> json, {
    required String sport,
  }) {
    var leagueName = sportLabelHu(sport);
    final leagues = json['leagues'];
    if (leagues is List && leagues.isNotEmpty && leagues.first is Map) {
      leagueName =
          (leagues.first as Map)['name'] as String? ?? leagueName;
    }
    final events = json['events'];
    if (events is! List) return const [];
    final matches = <SportsMatch>[];
    for (final event in events) {
      if (event is! Map<String, dynamic>) continue;
      final parsed = parseEvent(event, sport: sport, competition: leagueName);
      if (parsed != null) matches.add(parsed);
    }
    return matches;
  }

  static SportsMatch? parseEvent(
    Map<String, dynamic> event, {
    required String sport,
    required String competition,
  }) {
    final competitions = event['competitions'];
    if (competitions is! List || competitions.isEmpty) return null;
    final comp = competitions.first;
    if (comp is! Map<String, dynamic>) return null;
    final competitors = comp['competitors'];
    if (competitors is! List) return null;
    Map<String, dynamic>? home;
    Map<String, dynamic>? away;
    for (final c in competitors) {
      if (c is! Map<String, dynamic>) continue;
      if (c['homeAway'] == 'home') home = c;
      if (c['homeAway'] == 'away') away = c;
    }
    if (home == null || away == null) return null;

    final oddsList = comp['odds'];
    if (oddsList is! List || oddsList.isEmpty) return null;
    Map<String, dynamic>? odds;
    for (final item in oddsList) {
      if (item is Map<String, dynamic>) {
        odds = item;
        break;
      }
    }
    if (odds == null) return null;
    final lines = _extractLines(odds);
    if (lines == null) return null;

    final statusNode = (event['status'] as Map?)?['type'] as Map? ?? {};
    final state = statusNode['state'] as String? ?? 'pre';
    if (state == 'post') return null;
    final status = state == 'in' ? MatchStatus.live : MatchStatus.upcoming;
    final clock = (event['status'] as Map?)?['displayClock'] as String?;
    int? minute;
    if (clock != null) {
      minute = int.tryParse(clock.replaceAll(RegExp(r'[^0-9]'), ''));
    }

    final kickoffRaw = event['date'] as String? ?? comp['date'] as String?;
    if (kickoffRaw == null) return null;

    String teamName(Map<String, dynamic> c) {
      final team = c['team'];
      if (team is Map) {
        return (team['displayName'] ?? team['shortDisplayName'] ?? team['name'])
            as String;
      }
      return (c['displayName'] ?? '?') as String;
    }

    int? scoreOf(Map<String, dynamic> c) {
      final s = c['score'];
      if (s is int) return s;
      if (s is String) return int.tryParse(s);
      return null;
    }

    return SportsMatch(
      id: 'espn-${event['id']}',
      competition: competition,
      home: teamName(home),
      away: teamName(away),
      kickoff: DateTime.parse(kickoffRaw).toLocal(),
      status: status,
      minute: status == MatchStatus.live ? minute : null,
      homeScore: status == MatchStatus.live ? scoreOf(home) : null,
      awayScore: status == MatchStatus.live ? scoreOf(away) : null,
      homeOdds: lines.home,
      drawOdds: lines.draw,
      awayOdds: lines.away,
      isSample: false,
      sport: sport,
      sportLabel: sportLabelHu(sport),
    );
  }

  static ({Rational home, Rational? draw, Rational away})? _extractLines(
    Map<String, dynamic> odds,
  ) {
    final ml = odds['moneyline'];
    int? home;
    int? away;
    int? draw;
    if (ml is Map<String, dynamic>) {
      home = americanFromNested(_map(ml['home']));
      away = americanFromNested(_map(ml['away']));
      draw = americanFromNested(_map(ml['draw']));
    }
    home ??= parseAmerican(_map(odds['homeTeamOdds'])?['moneyLine']);
    away ??= parseAmerican(_map(odds['awayTeamOdds'])?['moneyLine']);
    draw ??= parseAmerican(_map(odds['drawOdds'])?['moneyLine']);

    if (home == null || away == null) return null;
    try {
      return (
        home: decimalFromAmerican(home),
        draw: draw == null ? null : decimalFromAmerican(draw),
        away: decimalFromAmerican(away),
      );
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? _map(Object? v) =>
      v is Map<String, dynamic> ? v : null;
}
