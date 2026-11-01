import 'package:flutter_test/flutter_test.dart';
import 'package:tippmix_kalkulator/data/models.dart';
import 'package:tippmix_kalkulator/data/squad.dart';
import 'package:tippmix_kalkulator/engine/probability.dart';
import 'package:tippmix_kalkulator/engine/rational.dart';
import 'package:tippmix_kalkulator/engine/strategy.dart';
import 'package:tippmix_kalkulator/engine/strength.dart';

final _half = Rational(BigInt.one, BigInt.two);
final _empty = TeamDirectory([]);

SportsMatch _twoWay({
  required String id,
  required Rational homeOdds,
  required Rational awayOdds,
  MatchStatus status = MatchStatus.upcoming,
}) {
  return SportsMatch(
    id: id,
    competition: 'NBA',
    home: 'H$id',
    away: 'A$id',
    kickoff: DateTime(2026, 11, 1),
    status: status,
    homeOdds: homeOdds,
    awayOdds: awayOdds,
    sport: 'basketball',
    sportLabel: 'Kosárlabda',
  );
}

SportsMatch _soccer({
  required String id,
  required String homeOdds,
  required String drawOdds,
  required String awayOdds,
}) {
  return SportsMatch(
    id: id,
    competition: 'NB',
    home: 'A',
    away: 'B',
    kickoff: DateTime(2026, 11, 1),
    status: MatchStatus.upcoming,
    homeOdds: Rational.parseDecimal(homeOdds),
    drawOdds: Rational.parseDecimal(drawOdds),
    awayOdds: Rational.parseDecimal(awayOdds),
    sport: 'soccer',
  );
}

StrategyBoard _board(List<SportsMatch> matches, {Rational? stake}) =>
    buildStrategy(matches, (m) => StrengthModel.blend(m, _empty), stake: stake);

void main() {
  test('szűrő: csak pontos P* > 1/2, a 2,00/2,00 (pontosan 1/2) kiesik', () {
    final favorite = _twoWay(
      id: 'fav',
      homeOdds: Rational(BigInt.from(5), BigInt.from(4)),
      awayOdds: Rational.fromInt(5),
    );
    final coin = _twoWay(
      id: 'coin',
      homeOdds: Rational.fromInt(2),
      awayOdds: Rational.fromInt(2),
    );
    final board = _board([favorite, coin]);
    expect(board.watchlist.length, 1);
    expect(board.watchlist.single.match.id, 'fav');
    expect(board.watchlist.single.chance, Rational(BigInt.from(4), BigInt.from(5)));
    expect(board.watchlist.single.chance > _half, isTrue);
    expect(
      StrengthModel.blend(coin, _empty).blended.home,
      _half,
    );
  });

  test('rangsor: nagyobb szorzó (profit) előre, nem a nagyobb %', () {
    final shortPrice = _twoWay(
      id: 'short',
      homeOdds: Rational(BigInt.from(5), BigInt.from(4)),
      awayOdds: Rational.fromInt(5),
    );
    final longPrice = _twoWay(
      id: 'long',
      homeOdds: Rational(BigInt.from(5), BigInt.from(3)),
      awayOdds: Rational(BigInt.from(5), BigInt.from(2)),
    );
    final board = _board([shortPrice, longPrice]);
    expect(board.watchlist.map((p) => p.match.id).toList(), ['long', 'short']);
    expect(board.watchlist[0].odds, Rational(BigInt.from(5), BigInt.from(3)));
    expect(board.watchlist[0].chance, Rational(BigInt.from(3), BigInt.from(5)));
    expect(board.watchlist[1].odds, Rational(BigInt.from(5), BigInt.from(4)));
    expect(board.watchlist[1].chance, Rational(BigInt.from(4), BigInt.from(5)));
    expect(board.watchlist[0].odds > board.watchlist[1].odds, isTrue);
    expect(board.watchlist[0].chance < board.watchlist[1].chance, isTrue);
    expect(
      board.watchlist[0].chance * board.watchlist[1].chance < _half,
      isTrue,
    );
    expect(board.slip.length, 1);
    expect(board.slip.single.match.id, 'long');
  });

  test('szelvény megáll, mielőtt a szorzat 1/2-re vagy alá esne', () {
    final twoThirds = _twoWay(
      id: 'a',
      homeOdds: Rational(BigInt.from(3), BigInt.from(2)),
      awayOdds: Rational.fromInt(3),
    );
    final threeQuarters = _twoWay(
      id: 'b',
      homeOdds: Rational(BigInt.from(4), BigInt.from(3)),
      awayOdds: Rational.fromInt(4),
    );
    final board = _board([threeQuarters, twoThirds]);
    expect(board.watchlist.first.match.id, 'a');
    expect(board.watchlist.first.chance, Rational(BigInt.from(2), BigInt.from(3)));
    expect(board.watchlist.last.chance, Rational(BigInt.from(3), BigInt.from(4)));
    expect(board.watchlist.first.chance * board.watchlist.last.chance, _half);
    expect(board.slip.length, 1);
    expect(board.slip.single.match.id, 'a');
    expect(board.combinedChance, Rational(BigInt.from(2), BigInt.from(3)));
    expect(board.combinedChance > _half, isTrue);
  });

  test('három 4/5-ös láb: szorzat 64/125 > 1/2, a negyedik (256/625) kimarad', () {
    final matches = [
      for (var i = 0; i < 4; i++)
        _twoWay(
          id: '$i',
          homeOdds: Rational(BigInt.from(5), BigInt.from(4)),
          awayOdds: Rational.fromInt(5),
        ),
    ];
    final board = _board(matches);
    expect(board.watchlist.length, 4);
    expect(board.slip.length, 3);
    expect(
      board.combinedChance,
      Rational(BigInt.from(64), BigInt.from(125)),
    );
    expect(board.combinedChance > _half, isTrue);
    final fourLegs =
        Rational(BigInt.from(256), BigInt.from(625));
    expect(fourLegs <= _half, isTrue);
    expect(
      board.combinedChance,
      IndependentEvents([
        for (final p in board.slip) p.chance,
      ]).accumulator,
    );
    expect(
      board.combinedOdds,
      Rational(BigInt.from(125), BigInt.from(64)),
    );
    expect(board.slipPayout, defaultStrategyStake * board.combinedOdds);
    expect(board.slipProfit, board.slipPayout - defaultStrategyStake);
    expect(board.stake, defaultStrategyStake);

    final doubled = _board(matches, stake: Rational.fromInt(100000));
    expect(doubled.slip.length, board.slip.length);
    expect(doubled.slipPayout, Rational.fromInt(2) * board.slipPayout);
    expect(doubled.slipProfit, Rational.fromInt(2) * board.slipProfit);
    expect(
      doubled.watchlist.first.profitOn(doubled.stake),
      Rational.fromInt(2) *
          board.watchlist.first.profitOn(board.stake),
    );
    expect(board.bestSingle, board.watchlist.first);
  });

  test('1X2 45% körüli max nem kerül a listára és nem inflálódik', () {
    final tight = _soccer(
      id: 'tight',
      homeOdds: '2,20',
      drawOdds: '3,20',
      awayOdds: '3,40',
    );
    final market = tight.market;
    expect(market.fair.reduce((a, b) => a > b ? a : b) < _half, isTrue);
    final board = _board([tight]);
    expect(board.watchlist, isEmpty);
    expect(board.slip, isEmpty);
    final top = market.fair[0];
    expect(top < _half, isTrue);
    expect(top.toPercentString().startsWith('50'), isFalse);
  });

  test('esély a de-vigelt tört, nem kerekített százalék', () {
    final match = _twoWay(
      id: 'exact',
      homeOdds: Rational.parseDecimal('1,80'),
      awayOdds: Rational.parseDecimal('2,10'),
    );
    final board = _board([match]);
    final fairHome = match.market.fair[0];
    expect(board.watchlist.single.chance, fairHome);
    expect(board.watchlist.single.chance, isNot(Rational.parseDecimal('0.56')));
    expect(fairHome.n * BigInt.two > fairHome.d, isTrue);
  });

  test('tét beolvasás: szóköz és Ft, üres/0 érvénytelen', () {
    expect(parseStakeHuf('50000'), defaultStrategyStake);
    expect(parseStakeHuf('50 000 Ft'), defaultStrategyStake);
    expect(parseStakeHuf('10\u00a0000'), Rational.fromInt(10000));
    expect(parseStakeHuf(''), isNull);
    expect(parseStakeHuf('0'), isNull);
    expect(parseStakeHuf('abc'), isNull);
  });

  test('élő számláló', () {
    final board = _board([
      _twoWay(
        id: '1',
        homeOdds: Rational(BigInt.from(5), BigInt.from(4)),
        awayOdds: Rational.fromInt(5),
        status: MatchStatus.live,
      ),
      _twoWay(
        id: '2',
        homeOdds: Rational(BigInt.from(5), BigInt.from(4)),
        awayOdds: Rational.fromInt(5),
      ),
    ]);
    expect(board.liveMatchCount, 1);
    expect(board.matchCount, 2);
  });
}
