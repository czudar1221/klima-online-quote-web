import 'package:flutter_test/flutter_test.dart';
import 'package:tippmix_kalkulator/data/models.dart';
import 'package:tippmix_kalkulator/data/squad.dart';
import 'package:tippmix_kalkulator/engine/rational.dart';
import 'package:tippmix_kalkulator/engine/strategy.dart';
import 'package:tippmix_kalkulator/engine/strength.dart';

SportsMatch _m({
  required String id,
  required String homeOdds,
  required String awayOdds,
  MatchStatus status = MatchStatus.upcoming,
}) {
  return SportsMatch(
    id: id,
    competition: 'NBA',
    home: 'H$id',
    away: 'A$id',
    kickoff: DateTime(2026, 11, 1),
    status: status,
    homeOdds: Rational.parseDecimal(homeOdds),
    awayOdds: Rational.parseDecimal(awayOdds),
    sport: 'basketball',
    sportLabel: 'Kosárlabda',
  );
}

void main() {
  final empty = TeamDirectory([]);

  test('csak 50% felett, rangsor szorzó szerint nem % szerint', () {
    final longOdds = _m(id: 'a', homeOdds: '1,90', awayOdds: '2,00');
    final shortOdds = _m(id: 'b', homeOdds: '1,40', awayOdds: '3,20');
    final underHalf = _m(id: 'c', homeOdds: '2,00', awayOdds: '2,00');
    final board = buildStrategy(
      [shortOdds, longOdds, underHalf],
      (m) => StrengthModel.blend(m, empty),
    );
    expect(board.watchlist.length, 2);
    expect(board.watchlist.first.match.id, 'a');
    expect(board.watchlist.last.match.id, 'b');
    expect(
      board.watchlist.first.odds > board.watchlist.last.odds,
      isTrue,
    );
    expect(
      board.watchlist.first.chance < board.watchlist.last.chance,
      isTrue,
    );
  });

  test('szelvény: termék > 50%, max 4, tét 50 000 Ft', () {
    final matches = [
      _m(id: '1', homeOdds: '1,18', awayOdds: '6,50'),
      _m(id: '2', homeOdds: '1,16', awayOdds: '6,80'),
      _m(id: '3', homeOdds: '1,14', awayOdds: '7,20'),
      _m(id: '4', homeOdds: '1,12', awayOdds: '8,00'),
      _m(id: '5', homeOdds: '1,10', awayOdds: '9,00'),
    ];
    final board = buildStrategy(
      matches,
      (m) => StrengthModel.blend(m, empty),
    );
    expect(board.slip.length, inInclusiveRange(1, 4));
    expect(board.combinedChance > Rational(BigInt.one, BigInt.two), isTrue);
    expect(board.slipPayout, strategyStake * board.combinedOdds);
    expect(board.slipProfit, board.slipPayout - strategyStake);
    expect(board.bestSingle, board.watchlist.first);
  });

  test('ha a következő láb 50% alá vinné, megáll', () {
    final a = _m(id: 'hi', homeOdds: '1,80', awayOdds: '2,10');
    final b = _m(id: 'lo', homeOdds: '1,85', awayOdds: '2,05');
    final board = buildStrategy([a, b], (m) => StrengthModel.blend(m, empty));
    for (final p in board.watchlist) {
      expect(p.chance > Rational(BigInt.one, BigInt.two), isTrue);
    }
    if (board.watchlist.length >= 2) {
      final productIfTwo =
          board.watchlist[0].chance * board.watchlist[1].chance;
      if (productIfTwo <= Rational(BigInt.one, BigInt.two)) {
        expect(board.slip.length, 1);
      }
    }
  });

  test('élő számláló', () {
    final board = buildStrategy(
      [
        _m(id: '1', homeOdds: '1,40', awayOdds: '3,20', status: MatchStatus.live),
        _m(id: '2', homeOdds: '1,40', awayOdds: '3,20'),
      ],
      (m) => StrengthModel.blend(m, empty),
    );
    expect(board.liveMatchCount, 1);
    expect(board.matchCount, 2);
  });
}
