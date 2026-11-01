import 'dart:convert';

import 'package:http/http.dart' as http;

import '../engine/rational.dart';
import 'feed_error.dart';
import 'models.dart';
import 'odds_api_config.dart';
import 'sport_catalog.dart';

/// the-odds-api.com — legitimate odds API, optional `ODDS_API_KEY`.
class OddsApiFeed {
  OddsApiFeed({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<SportsMatch>> fetch() async {
    if (!OddsApiConfig.isConfigured) return const [];

    final sportsRes = await _client.get(
      Uri.https('api.the-odds-api.com', '/v4/sports/', {
        'apiKey': OddsApiConfig.apiKey,
      }),
    );
    if (sportsRes.statusCode < 200 || sportsRes.statusCode >= 300) {
      throw FeedException('network');
    }
    final sportsJson = jsonDecode(sportsRes.body);
    if (sportsJson is! List) throw FeedException('network');

    final keys = <String>[];
    for (final item in sportsJson) {
      if (item is! Map<String, dynamic>) continue;
      if (item['active'] != true) continue;
      final key = item['key'] as String?;
      if (key == null || !isTippmixOddsSport(key)) continue;
      keys.add(key);
    }

    final out = <SportsMatch>[];
    var failures = 0;
    for (final key in keys) {
      try {
        final res = await _client.get(
          Uri.https('api.the-odds-api.com', '/v4/sports/$key/odds/', {
            'apiKey': OddsApiConfig.apiKey,
            'regions': 'eu',
            'markets': 'h2h',
            'oddsFormat': 'decimal',
          }),
        );
        if (res.statusCode < 200 || res.statusCode >= 300) {
          failures++;
          continue;
        }
        final decoded = jsonDecode(res.body);
        if (decoded is! List) continue;
        for (final event in decoded) {
          if (event is Map<String, dynamic>) {
            final match = parseEvent(event, sportKey: key);
            if (match != null) out.add(match);
          }
        }
      } catch (_) {
        failures++;
      }
    }
    if (out.isEmpty && failures > 0 && keys.isNotEmpty) {
      throw FeedException('network');
    }
    return out;
  }

  static SportsMatch? parseEvent(
    Map<String, dynamic> event, {
    required String sportKey,
  }) {
    final home = event['home_team'] as String?;
    final away = event['away_team'] as String?;
    final commence = event['commence_time'] as String?;
    if (home == null || away == null || commence == null) return null;
    final bookmakers = event['bookmakers'];
    if (bookmakers is! List || bookmakers.isEmpty) return null;
    Map<String, dynamic>? h2h;
    for (final book in bookmakers) {
      if (book is! Map<String, dynamic>) continue;
      final markets = book['markets'];
      if (markets is! List) continue;
      for (final market in markets) {
        if (market is Map<String, dynamic> && market['key'] == 'h2h') {
          h2h = market;
          break;
        }
      }
      if (h2h != null) break;
    }
    if (h2h == null) return null;
    final outcomes = h2h['outcomes'];
    if (outcomes is! List) return null;
    Rational? homeOdds;
    Rational? awayOdds;
    Rational? drawOdds;
    for (final o in outcomes) {
      if (o is! Map<String, dynamic>) continue;
      final name = o['name'] as String? ?? '';
      final price = o['price'];
      if (price is! num) continue;
      final odd = Rational.parseDecimal(price.toString());
      if (odd <= Rational.one) continue;
      if (name.toLowerCase() == 'draw') {
        drawOdds = odd;
      } else if (name == home) {
        homeOdds = odd;
      } else if (name == away) {
        awayOdds = odd;
      }
    }
    if (homeOdds == null || awayOdds == null) return null;
    final sport = sportFromOddsKey(sportKey);
    return SportsMatch(
      id: 'odds-${event['id']}',
      competition: (event['sport_title'] as String?) ?? sportLabelHu(sport),
      home: home,
      away: away,
      kickoff: DateTime.parse(commence).toLocal(),
      status: MatchStatus.upcoming,
      homeOdds: homeOdds,
      drawOdds: drawOdds,
      awayOdds: awayOdds,
      isSample: false,
      sport: sport,
      sportLabel: sportLabelHu(sport),
    );
  }
}
