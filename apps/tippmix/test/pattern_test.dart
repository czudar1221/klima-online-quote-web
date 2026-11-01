import 'package:flutter_test/flutter_test.dart';
import 'package:tippmix_kalkulator/data/models.dart';
import 'package:tippmix_kalkulator/data/pattern_book.dart';
import 'package:tippmix_kalkulator/data/squad.dart';
import 'package:tippmix_kalkulator/engine/rational.dart';
import 'package:tippmix_kalkulator/engine/strength.dart';

SportsMatch _nba({
  required String id,
  required String homeForm,
  required String awayForm,
  String homeOdds = '1,40',
  String awayOdds = '3,20',
}) {
  return SportsMatch(
    id: id,
    competition: 'NBA',
    home: 'H',
    away: 'A',
    kickoff: DateTime(2026, 11, 1),
    status: MatchStatus.upcoming,
    homeOdds: Rational.parseDecimal(homeOdds),
    awayOdds: Rational.parseDecimal(awayOdds),
    sport: 'basketball',
    sportLabel: 'Kosárlabda',
    homeTeamId: 'h',
    awayTeamId: 'a',
    homeFormCode: homeForm,
    awayFormCode: awayForm,
  );
}

void main() {
  test('form kód W/D/L, idegen betű kimarad', () {
    expect(parseFormCode('WLLDW'), [
      FormResult.win,
      FormResult.loss,
      FormResult.loss,
      FormResult.draw,
      FormResult.win,
    ]);
    expect(parseFormCode(''), isEmpty);
    expect(parseFormCode(null), isEmpty);
  });

  test('ha nincs forma, λ=0, csak szorzó, nem kitalált történelem', () {
    final match = _nba(id: '1', homeForm: '', awayForm: '');
    final snap = PatternBook().snapshot(match);
    expect(snap.canBlend, isFalse);
    expect(snap.signal, PatternSignal.oddsOnly);
    expect(snap.formLabel(true), contains('Nincs formaadat'));
    final blended = StrengthModel.blendSnapshot(match, snap);
    expect(blended.modelWeight, Rational.zero);
    expect(blended.blended.home, match.market.fair[0]);
    expect(blended.pattern, PatternSignal.oddsOnly);
  });

  test('élő forma: λ=2/5, P* a de-vigelt és a modell keveréke', () {
    final match = _nba(id: '1', homeForm: 'WWWWW', awayForm: 'LLLLL');
    final snap = PatternBook().snapshot(match);
    expect(snap.bothForm, isTrue);
    expect(snap.signal, PatternSignal.form);
    final blended = StrengthModel.blendSnapshot(match, snap);
    expect(blended.modelWeight, StrengthWeights.modelBlend);
    expect(blended.blended.sum, Rational.one);
    final rest = Rational.one - StrengthWeights.modelBlend;
    expect(
      blended.blended.home,
      rest * blended.market.fair[0] + StrengthWeights.modelBlend * blended.model!.home,
    );
    expect(blended.pattern, PatternSignal.form);
  });

  test('hiányzó csak akkor, ha a forrás a csapatot listázta', () {
    final match = _nba(id: '1', homeForm: 'WWW', awayForm: 'LLL');
    final book = PatternBook();
    final homeKey = PatternBook.teamKey(id: 'h', name: 'H', sport: 'basketball');
    book.injuryKnownTeams.add(homeKey);
    book.injuriesByTeam[homeKey] = [
      PlayerProfile(
        name: 'X',
        role: PlayerRole.forward,
        importance: Rational(BigInt.one, BigInt.from(10)),
        available: false,
      ),
    ];
    final snap = book.snapshot(match);
    expect(snap.homeAbsenceLive, isTrue);
    expect(snap.awayAbsenceLive, isFalse);
    expect(snap.absenceLabel(false), contains('nem közölt'));
    expect(snap.signal, PatternSignal.formAndAbsence);
  });
}
