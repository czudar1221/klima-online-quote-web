import 'package:flutter_test/flutter_test.dart';
import 'package:tippmix_kalkulator/data/models.dart';
import 'package:tippmix_kalkulator/data/pattern_book.dart';
import 'package:tippmix_kalkulator/engine/rational.dart';
import 'package:tippmix_kalkulator/engine/strategy.dart';
import 'package:tippmix_kalkulator/engine/strength.dart';
import 'package:tippmix_kalkulator/l10n/copy.dart';

SportsMatch _m({
  required String id,
  required Rational home,
  required Rational away,
}) {
  return SportsMatch(
    id: id,
    competition: 'NBA',
    home: 'H',
    away: 'A',
    kickoff: DateTime(2026, 11, 1),
    status: MatchStatus.upcoming,
    homeOdds: home,
    awayOdds: away,
    sport: 'basketball',
    sportLabel: 'Kosárlabda',
  );
}

void main() {
  test('hiányzó szorzó kiesik, nem találunk ki történelmet', () {
    expect(
      _m(id: 'ok', home: Rational.fromInt(2), away: Rational.fromInt(2)).hasValidOdds,
      isTrue,
    );
    expect(
      _m(
        id: 'bad',
        home: Rational.one,
        away: Rational.fromInt(2),
      ).hasValidOdds,
      isFalse,
    );
  });

  test('alulárazott ha modell · szorzó > 1, felülárazott ha < 1', () {
    final match = _m(
      id: 'v',
      home: Rational.fromInt(2),
      away: Rational.fromInt(2),
    );
    final under = StrategyPick(
      match: match,
      outcome: Outcome.home,
      chance: Rational(BigInt.from(3), BigInt.from(5)),
      odds: Rational.fromInt(2),
      modelChance: Rational(BigInt.from(3), BigInt.from(5)),
      pattern: PatternSignal.form,
      chances: ThreeWay(
        home: Rational(BigInt.from(3), BigInt.from(5)),
        draw: Rational.zero,
        away: Rational(BigInt.from(2), BigInt.from(5)),
      ),
    );
    expect(under.valueMark, ValueMark.underpriced);
    expect(under.valueLine.contains(Copy.valueUnder), isTrue);

    final over = StrategyPick(
      match: match,
      outcome: Outcome.home,
      chance: Rational(BigInt.from(2), BigInt.from(5)),
      odds: Rational.fromInt(2),
      modelChance: Rational(BigInt.from(2), BigInt.from(5)),
      pattern: PatternSignal.form,
      chances: ThreeWay(
        home: Rational(BigInt.from(2), BigInt.from(5)),
        draw: Rational.zero,
        away: Rational(BigInt.from(3), BigInt.from(5)),
      ),
    );
    expect(over.valueMark, ValueMark.overpriced);
    expect(over.valueEdge, Rational(BigInt.from(-1), BigInt.from(5)));
  });

  test('fél Kelly: p=4/5, o=2, bank 100000 → 30000', () {
    final s = halfKellyStake(
      chance: Rational(BigInt.from(4), BigInt.from(5)),
      odds: Rational.fromInt(2),
      bank: Rational.fromInt(100000),
    );
    expect(s, Rational.fromInt(30000));
  });

  test('nincs modell: nincs értékjel', () {
    final pick = StrategyPick(
      match: _m(id: 'n', home: Rational.fromInt(2), away: Rational.fromInt(2)),
      outcome: Outcome.home,
      chance: Rational(BigInt.one, BigInt.two),
      odds: Rational.fromInt(2),
      chances: ThreeWay(
        home: Rational(BigInt.one, BigInt.two),
        draw: Rational.zero,
        away: Rational(BigInt.one, BigInt.two),
      ),
    );
    expect(pick.valueMark, ValueMark.noModel);
    expect(pick.valueLine, Copy.valueNoModel);
  });
}
