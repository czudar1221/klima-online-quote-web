import '../data/models.dart';
import 'rational.dart';
import 'strength.dart';
import 'strongest_pick.dart';

final strategyStake = Rational.fromInt(50000);
final _half = Rational(BigInt.one, BigInt.two);

class StrategyPick {
  final SportsMatch match;
  final Outcome outcome;
  final Rational chance;
  final Rational odds;

  const StrategyPick({
    required this.match,
    required this.outcome,
    required this.chance,
    required this.odds,
  });

  Rational get payout => strategyStake * odds;
  Rational get profit => strategyStake * (odds - Rational.one);
}

class StrategyBoard {
  final List<StrategyPick> watchlist;
  final List<StrategyPick> slip;
  final int liveMatchCount;
  final int matchCount;

  const StrategyBoard({
    required this.watchlist,
    required this.slip,
    required this.liveMatchCount,
    required this.matchCount,
  });

  StrategyPick? get bestSingle =>
      watchlist.isEmpty ? null : watchlist.first;

  Rational get combinedChance =>
      slip.fold(Rational.one, (a, p) => a * p.chance);

  Rational get combinedOdds =>
      slip.fold(Rational.one, (a, p) => a * p.odds);

  Rational get slipPayout => strategyStake * combinedOdds;

  Rational get slipProfit => slipPayout - strategyStake;
}

/// Picks with P* > 50%, ranked by decimal odds (profit), not by %.
/// Slip: greedy add while combined chance stays > 50%, at most 4 legs.
StrategyBoard buildStrategy(
  List<SportsMatch> matches,
  BlendedMatch Function(SportsMatch) blend,
) {
  final candidates = <StrategyPick>[];
  for (final match in matches) {
    if (match.isSample) continue;
    final blended = blend(match);
    final pick = strongestPick(blended, hasDraw: match.hasDraw);
    if (pick.chance <= _half) continue;
    candidates.add(
      StrategyPick(
        match: match,
        outcome: pick.outcome,
        chance: pick.chance,
        odds: match.oddsFor(pick.outcome),
      ),
    );
  }
  candidates.sort((a, b) {
    final byOdds = b.odds.compareTo(a.odds);
    if (byOdds != 0) return byOdds;
    return b.chance.compareTo(a.chance);
  });

  final slip = <StrategyPick>[];
  var product = Rational.one;
  for (final pick in candidates) {
    if (slip.length >= 4) break;
    final next = product * pick.chance;
    if (next <= _half) break;
    slip.add(pick);
    product = next;
  }

  return StrategyBoard(
    watchlist: List.unmodifiable(candidates),
    slip: List.unmodifiable(slip),
    liveMatchCount: matches.where((m) => m.status == MatchStatus.live).length,
    matchCount: matches.length,
  );
}

String formatHuf(Rational value) {
  final scaled = value; // already forint
  final whole = scaled.n ~/ scaled.d;
  final rem = scaled.n % scaled.d;
  var rounded = whole;
  if (rem * BigInt.two >= scaled.d) {
    rounded += BigInt.one;
  }
  final s = rounded.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final fromEnd = s.length - i;
    if (i > 0 && fromEnd % 3 == 0) buf.write('\u00a0');
    buf.write(s[i]);
  }
  return '${buf.toString()} Ft';
}
