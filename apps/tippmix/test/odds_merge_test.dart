import 'package:flutter_test/flutter_test.dart';
import 'package:tippmix_kalkulator/data/live_feed.dart';
import 'package:tippmix_kalkulator/data/models.dart';
import 'package:tippmix_kalkulator/data/odds_api_feed.dart';
import 'package:tippmix_kalkulator/data/sport_catalog.dart';
import 'package:tippmix_kalkulator/engine/rational.dart';

SportsMatch _espn({
  required String home,
  required String away,
  required DateTime kickoff,
}) {
  return SportsMatch(
    id: 'espn-1',
    competition: 'Premier League',
    home: home,
    away: away,
    kickoff: kickoff,
    status: MatchStatus.upcoming,
    homeOdds: Rational.parseDecimal('2.10'),
    drawOdds: Rational.parseDecimal('3.40'),
    awayOdds: Rational.parseDecimal('3.50'),
    homeTeamId: '364',
    awayTeamId: '359',
    sport: 'soccer',
    sportLabel: 'Labdarúgás',
    leagueKey: 'soccer/eng.1',
    homeFormCode: 'DWWWW',
    awayFormCode: 'DWDWW',
  );
}

void main() {
  test('Odds API whitelist is Tippmix-like, not every sport', () {
    expect(isTippmixOddsSport('soccer_epl'), isTrue);
    expect(isTippmixOddsSport('politics_us_presidential'), isFalse);
    expect(sportFromOddsKey('soccer_epl'), 'soccer');
    expect(sportFromOddsKey('icehockey_nhl'), 'hockey');
  });

  test('Odds API event → decimal h2h, nem minta', () {
    final match = OddsApiFeed.parseEvent({
      'id': 'abc',
      'sport_title': 'EPL',
      'home_team': 'Liverpool',
      'away_team': 'Arsenal',
      'commence_time': '2026-11-01T16:30:00Z',
      'bookmakers': [
        {
          'markets': [
            {
              'key': 'h2h',
              'outcomes': [
                {'name': 'Liverpool', 'price': 2.85},
                {'name': 'Arsenal', 'price': 2.5},
                {'name': 'Draw', 'price': 3.4},
              ],
            },
          ],
        },
      ],
    }, sportKey: 'soccer_epl');
    expect(match, isNotNull);
    expect(match!.isSample, isFalse);
    expect(match.sport, 'soccer');
    expect(match.homeOdds, Rational.parseDecimal('2.85'));
    expect(match.drawOdds, Rational.parseDecimal('3.4'));
  });

  test('laza név: Man Utd + Bayern München is ESPN formát kap', () {
    final kickoff = DateTime.utc(2026, 11, 1, 16, 30);
    final espn = [
      _espn(
        home: 'Manchester United',
        away: 'FC Bayern München',
        kickoff: kickoff,
      ).copyWith(homeFormCode: 'WLWWD', awayFormCode: 'WWWWW'),
    ];
    final odds = SportsMatch(
      id: 'odds-loose',
      competition: 'UCL',
      home: 'Man Utd',
      away: 'Bayern Munich',
      kickoff: kickoff.add(const Duration(hours: 20)),
      status: MatchStatus.upcoming,
      homeOdds: Rational.parseDecimal('2.90'),
      drawOdds: Rational.parseDecimal('3.40'),
      awayOdds: Rational.parseDecimal('2.40'),
      sport: 'soccer',
      sportLabel: 'Labdarúgás',
    );
    final merged = mergeEspnFormWithOdds(espn, [odds]);
    expect(merged, hasLength(1));
    expect(merged.single.homeFormCode, 'WLWWD');
    expect(merged.single.awayFormCode, 'WWWWW');
    expect(merged.single.homeTeamId, '364');
    expect(merged.single.leagueKey, 'soccer/eng.1');
    expect(merged.single.homeOdds, Rational.parseDecimal('2.90'));
  });

  test('összefésülés: Odds API szorzó, ESPN forma és csapat-id', () {
    final kickoff = DateTime.utc(2026, 11, 1, 16, 30);
    final espn = _espn(home: 'Liverpool', away: 'Arsenal', kickoff: kickoff);
    final odds = SportsMatch(
      id: 'odds-1',
      competition: 'EPL',
      home: 'Liverpool',
      away: 'Arsenal',
      kickoff: kickoff.add(const Duration(hours: 1)),
      status: MatchStatus.upcoming,
      homeOdds: Rational.parseDecimal('2.85'),
      drawOdds: Rational.parseDecimal('3.40'),
      awayOdds: Rational.parseDecimal('2.50'),
      sport: 'soccer',
      sportLabel: 'Labdarúgás',
    );
    final merged = mergeEspnFormWithOdds([espn], [odds]);
    expect(merged, hasLength(1));
    expect(merged.single.homeOdds, Rational.parseDecimal('2.85'));
    expect(merged.single.awayOdds, Rational.parseDecimal('2.50'));
    expect(merged.single.homeTeamId, '364');
    expect(merged.single.homeFormCode, 'DWWWW');
    expect(merged.single.leagueKey, 'soccer/eng.1');
    expect(merged.single.id, 'odds-1');
  });
}
