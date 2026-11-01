import 'package:flutter_test/flutter_test.dart';
import 'package:tippmix_kalkulator/data/espn_feed.dart';
import 'package:tippmix_kalkulator/data/models.dart';
import 'package:tippmix_kalkulator/data/squad.dart';
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
              'form': 'DWWWW',
              'team': {'id': '364', 'displayName': 'Liverpool'},
            },
            {
              'homeAway': 'away',
              'score': '0',
              'form': 'DWDWW',
              'team': {'id': '359', 'displayName': 'Arsenal'},
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
      league: 'eng.1',
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
    expect(match.homeTeamId, '364');
    expect(match.homeFormCode, 'DWWWW');
    expect(match.leagueKey, 'soccer/eng.1');
  });

  test('lejátszott eredmény formához, szorzó nélkül', () {
    final event = {
      'id': '9',
      'date': '2026-10-26T16:30:00Z',
      'status': {
        'type': {'state': 'post'},
      },
      'competitions': [
        {
          'competitors': [
            {
              'homeAway': 'home',
              'score': '3',
              'winner': true,
              'team': {'id': '331', 'displayName': 'Brighton'},
            },
            {
              'homeAway': 'away',
              'score': '0',
              'winner': false,
              'team': {'id': '357', 'displayName': 'Leeds'},
            },
          ],
        },
      ],
    };
    final game = EspnLiveFeed.parseFinishedEvent(event, sport: 'soccer');
    expect(game, isNotNull);
    expect(game!.homeScore, 3);
    expect(game.resultFor('331'), FormResult.win);
    expect(game.resultFor('357'), FormResult.loss);
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
