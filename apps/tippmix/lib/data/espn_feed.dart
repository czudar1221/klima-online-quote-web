import 'dart:convert';

import 'package:http/http.dart' as http;

import '../engine/american_odds.dart';
import '../engine/rational.dart';
import 'feed_error.dart';
import 'models.dart';
import 'pattern_book.dart';
import 'sport_catalog.dart';
import 'squad.dart';

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
          for (final match in parseScoreboard(
            decoded,
            sport: board.sport,
            league: board.league,
          )) {
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

  Future<PatternBook> fetchPatterns(List<SportsMatch> live) async {
    final book = PatternBook();
    final leagues = <String>{};
    for (final m in live) {
      final key = m.leagueKey;
      if (key == null || !key.contains('/')) continue;
      final hasForm =
          parseFormCode(m.homeFormCode).isNotEmpty &&
          parseFormCode(m.awayFormCode).isNotEmpty;
      if (!hasForm) leagues.add(key);
    }
    final now = _now ?? DateTime.now().toUtc();
    for (final key in leagues) {
      final parts = key.split('/');
      final sport = parts[0];
      final league = parts.sublist(1).join('/');
      for (var i = 1; i <= 7; i++) {
        final day = DateTime.utc(now.year, now.month, now.day)
            .subtract(Duration(days: i));
        final ymd =
            '${day.year.toString().padLeft(4, '0')}'
            '${day.month.toString().padLeft(2, '0')}'
            '${day.day.toString().padLeft(2, '0')}';
        final uri = Uri.https(
          'site.api.espn.com',
          '/apis/site/v2/sports/$sport/$league/scoreboard',
          {'dates': ymd},
        );
        try {
          final res = await _client.get(uri, headers: {'User-Agent': _ua});
          if (res.statusCode < 200 || res.statusCode >= 300) continue;
          final decoded = jsonDecode(res.body);
          if (decoded is! Map<String, dynamic>) continue;
          for (final game in parseFinishedScoreboard(
            decoded,
            sport: sport,
          )) {
            book.addFinished(sport, game);
          }
        } catch (_) {}
      }
    }

    final injuryLeagues = <({String sport, String league})>{};
    for (final m in live) {
      final key = m.leagueKey;
      if (key == null || !key.contains('/')) continue;
      final parts = key.split('/');
      injuryLeagues.add((sport: parts[0], league: parts.sublist(1).join('/')));
    }
    for (final board in injuryLeagues) {
      final uri = Uri.https(
        'site.api.espn.com',
        '/apis/site/v2/sports/${board.sport}/${board.league}/injuries',
      );
      try {
        final res = await _client.get(uri, headers: {'User-Agent': _ua});
        if (res.statusCode < 200 || res.statusCode >= 300) continue;
        final decoded = jsonDecode(res.body);
        if (decoded is! Map<String, dynamic>) continue;
        _ingestInjuries(book, decoded, sport: board.sport);
      } catch (_) {}
    }
    return book;
  }

  static void _ingestInjuries(
    PatternBook book,
    Map<String, dynamic> json, {
    required String sport,
  }) {
    final groups = json['injuries'];
    if (groups is! List) return;
    for (final group in groups) {
      if (group is! Map<String, dynamic>) continue;
      final teamId = group['id']?.toString();
      final teamName = group['displayName'] as String? ?? '';
      final key = PatternBook.teamKey(
        id: teamId,
        name: teamName,
        sport: sport,
      );
      book.injuryKnownTeams.add(key);
      final items = group['injuries'];
      if (items is! List) continue;
      final players = <PlayerProfile>[];
      for (final item in items) {
        if (item is! Map<String, dynamic>) continue;
        final status = (item['status'] as String? ?? '').toLowerCase();
        if (!_isAbsenceStatus(status)) continue;
        final athlete = item['athlete'];
        var name = 'játékos';
        if (athlete is Map && athlete['displayName'] is String) {
          name = athlete['displayName'] as String;
        }
        players.add(
          PlayerProfile(
            name: name,
            role: PlayerRole.midfielder,
            importance: Rational(BigInt.one, BigInt.from(10)),
            available: false,
          ),
        );
      }
      book.injuriesByTeam[key] = players;
    }
  }

  static bool _isAbsenceStatus(String status) {
    if (status.contains('active') ||
        status.contains('probable') ||
        status.contains('questionable')) {
      return false;
    }
    return status.contains('out') ||
        status.contains('injur') ||
        status.contains('doubt') ||
        status.contains('suspend') ||
        status.contains('reserve');
  }

  static List<SportsMatch> parseScoreboard(
    Map<String, dynamic> json, {
    required String sport,
    String? league,
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
      final parsed = parseEvent(
        event,
        sport: sport,
        competition: leagueName,
        league: league,
      );
      if (parsed != null) matches.add(parsed);
    }
    return matches;
  }

  static List<FinishedResult> parseFinishedScoreboard(
    Map<String, dynamic> json, {
    required String sport,
  }) {
    final events = json['events'];
    if (events is! List) return const [];
    final out = <FinishedResult>[];
    for (final event in events) {
      if (event is! Map<String, dynamic>) continue;
      final parsed = parseFinishedEvent(event, sport: sport);
      if (parsed != null) out.add(parsed);
    }
    return out;
  }

  static FinishedResult? parseFinishedEvent(
    Map<String, dynamic> event, {
    required String sport,
  }) {
    final competitions = event['competitions'];
    if (competitions is! List || competitions.isEmpty) return null;
    final comp = competitions.first;
    if (comp is! Map<String, dynamic>) return null;
    final state =
        ((event['status'] as Map?)?['type'] as Map?)?['state'] as String? ??
        ((comp['status'] as Map?)?['type'] as Map?)?['state'] as String? ??
        '';
    if (state != 'post') return null;
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
    int? scoreOf(Map<String, dynamic> c) {
      final s = c['score'];
      if (s is int) return s;
      if (s is String) return int.tryParse(s);
      return null;
    }

    final hs = scoreOf(home);
    final as = scoreOf(away);
    if (hs == null || as == null) return null;
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

    String teamId(Map<String, dynamic> c) {
      final team = c['team'];
      if (team is Map && team['id'] != null) return team['id'].toString();
      return c['id']?.toString() ?? teamName(c);
    }

    return FinishedResult(
      homeId: teamId(home),
      awayId: teamId(away),
      homeName: teamName(home),
      awayName: teamName(away),
      homeScore: hs,
      awayScore: as,
      kickoff: DateTime.parse(kickoffRaw).toLocal(),
      allowsDraw: sport == 'soccer',
    );
  }

  static SportsMatch? parseEvent(
    Map<String, dynamic> event, {
    required String sport,
    required String competition,
    String? league,
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

    String? teamId(Map<String, dynamic> c) {
      final team = c['team'];
      if (team is Map && team['id'] != null) return team['id'].toString();
      return c['id']?.toString();
    }

    String? formOf(Map<String, dynamic> c) {
      final f = c['form'];
      if (f is String && f.isNotEmpty) return f;
      return null;
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
      homeTeamId: teamId(home),
      awayTeamId: teamId(away),
      leagueKey: league == null ? null : '$sport/$league',
      homeFormCode: formOf(home),
      awayFormCode: formOf(away),
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
