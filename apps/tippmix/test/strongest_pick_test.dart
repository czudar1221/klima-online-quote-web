import 'package:flutter_test/flutter_test.dart';
import 'package:tippmix_kalkulator/data/models.dart';
import 'package:tippmix_kalkulator/data/squad.dart';
import 'package:tippmix_kalkulator/engine/probability.dart';
import 'package:tippmix_kalkulator/engine/rational.dart';
import 'package:tippmix_kalkulator/engine/strength.dart';
import 'package:tippmix_kalkulator/engine/strongest_pick.dart';

void main() {
  test('szoros 1X2: a legnagyobb esély a tipp, 45% marad 45%', () {
    final match = SportsMatch(
      id: 't',
      competition: 'NB',
      home: 'A',
      away: 'B',
      kickoff: DateTime(2026, 11, 1),
      status: MatchStatus.upcoming,
      homeOdds: Rational.parseDecimal('2,20'),
      drawOdds: Rational.parseDecimal('3,20'),
      awayOdds: Rational.parseDecimal('3,40'),
      sport: 'soccer',
    );
    final pick = strongestPick(
      StrengthModel.blend(match, TeamDirectory([])),
      hasDraw: true,
    );
    expect(pick.outcome, Outcome.home);
    expect(pick.chances.sum, Rational.one);
    expect(pick.chance < Rational(BigInt.one, BigInt.two), isTrue);
  });

  test('kétkimenetes piac: nincs X, a nagyobb oldal a tipp', () {
    final match = SportsMatch(
      id: 'nba',
      competition: 'NBA',
      home: 'Jazz',
      away: 'Celtics',
      kickoff: DateTime(2026, 11, 1),
      status: MatchStatus.upcoming,
      homeOdds: Rational.parseDecimal('1,80'),
      awayOdds: Rational.parseDecimal('2,10'),
      sport: 'basketball',
      sportLabel: 'Kosárlabda',
    );
    expect(match.hasDraw, isFalse);
    final pick = strongestPick(
      StrengthModel.blend(match, TeamDirectory([])),
      hasDraw: false,
    );
    expect(pick.twoWay, isTrue);
    expect(pick.outcome, Outcome.home);
    expect(pick.chances.draw, Rational.zero);
    expect(pick.chances.home + pick.chances.away, Rational.one);
  });

  test('de-vigelt piac összege 1 két kimenetre', () {
    final m = MarketProbabilities.fromDecimalOdds([
      Rational.parseDecimal('1,80'),
      Rational.parseDecimal('2,10'),
    ]);
    expect(m.fair[0] + m.fair[1], Rational.one);
  });
}
