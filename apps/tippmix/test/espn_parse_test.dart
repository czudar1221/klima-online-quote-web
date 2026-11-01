import 'package:flutter_test/flutter_test.dart';
import 'package:tippmix_kalkulator/data/espn_feed.dart';
import 'package:tippmix_kalkulator/data/models.dart';
import 'package:tippmix_kalkulator/engine/rational.dart';

void main() {
  test('ESPN 1X2 moneyline → tizedes szorzó, nem minta', () {
    final event = {
      'id': '401',
      'date': '2026-11-01T16:30:00Z',
      'status': {
        'displayClock': "0'",
        'type': {'state': 'pre'},
      },
      'competitions': [
        {
          'date': '2026-11-01T16:30:00Z',
          'competitors': [
            {
              'homeAway': 'home',
              'score': '0',
              'team': {'displayName': 'Liverpool'},
            },
            {
              'homeAway': 'away',
              'score': '0',
              'team': {'displayName': 'Arsenal'},
            },
          ],
          'odds': [
            {
              'moneyline': {
                'home': {
                  'close': {'odds': '+185'},
                },
                'away': {
                  'close': {'odds': '+150'},
                },
                'draw': {
                  'close': {'odds': '+240'},
                },
              },
            },
          ],
        },
      ],
    };
    final match = EspnLiveFeed.parseEvent(
      event,
      sport: 'soccer',
      competition: 'Premier League',
    );
    expect(match, isNotNull);
    expect(match!.isSample, isFalse);
    expect(match.home, 'Liverpool');
    expect(match.away, 'Arsenal');
    expect(match.hasDraw, isTrue);
    expect(match.homeOdds, Rational.parseDecimal('2.85'));
    expect(match.awayOdds, Rational.parseDecimal('2.50'));
    expect(match.drawOdds, Rational.parseDecimal('3.40'));
    expect(match.status, MatchStatus.upcoming);
  });

  test('lejátszott meccs kimarad', () {
    final event = {
      'id': '2',
      'date': '2026-11-01T16:30:00Z',
      'status': {
        'type': {'state': 'post'},
      },
      'competitions': [
        {
          'competitors': [
            {
              'homeAway': 'home',
              'team': {'displayName': 'A'},
            },
            {
              'homeAway': 'away',
              'team': {'displayName': 'B'},
            },
          ],
          'odds': [
            {
              'homeTeamOdds': {'moneyLine': -150},
              'awayTeamOdds': {'moneyLine': 130},
            },
          ],
        },
      ],
    };
    expect(
      EspnLiveFeed.parseEvent(event, sport: 'basketball', competition: 'NBA'),
      isNull,
    );
  });
}
