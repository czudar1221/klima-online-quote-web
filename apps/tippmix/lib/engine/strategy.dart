import '../data/models.dart';
import 'probability.dart';
import 'rational.dart';
import 'strength.dart';
import 'strongest_pick.dart';

final defaultStrategyStake = Rational.fromInt(50000);
final _half = Rational(BigInt.one, BigInt.two);

/// Digits-only forint amount. Spaces and "Ft" are ignored. Null if empty or ≤ 0.
Rational? parseStakeHuf(String raw) {
  final digits = StringBuffer();
  for (final unit in raw.runes) {
    if (unit >= 0x30 && unit <= 0x39) {
      digits.writeCharCode(unit);
    }
  }
  if (digits.isEmpty) return null;
  final n = BigInt.parse(digits.toString());
  if (n <= BigInt.zero) return null;
  return Rational(n);
}

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

  Rational payoutOn(Rational stake) => stake * odds;
  Rational profitOn(Rational stake) => stake * (odds - Rational.one);
}

class StrategyBoard {
  final List<StrategyPick> watchlist;
  final List<StrategyPick> slip;
  final Rational stake;
  final int liveMatchCount;
  final int matchCount;

  const StrategyBoard({
    required this.watchlist,
    required this.slip,
    required this.stake,
    required this.liveMatchCount,
    required this.matchCount,
  });

  StrategyPick? get bestSingle =>
      watchlist.isEmpty ? null : watchlist.first;

  /// Product of de-vigged (blended) leg chances — exact, never a rounded %.
  Rational get combinedChance => IndependentEvents(
    [for (final p in slip) p.chance],
  ).accumulator;

  Rational get combinedOdds =>
      slip.fold(Rational.one, (a, p) => a * p.odds);

  Rational get slipPayout => stake * combinedOdds;

  Rational get slipProfit => slipPayout - stake;
}

/// Picks with exact P* > 1/2, ranked by decimal odds (profit), not by %.
/// Filter and slip product compare [Rational] values — never [Rational.toPercentString]
/// or [Rational.toDouble]. Slip: greedy add while the product stays > 1/2, at most 4 legs.
StrategyBoard buildStrategy(
  List<SportsMatch> matches,
  BlendedMatch Function(SportsMatch) blend, {
  Rational? stake,
}) {
  final usedStake = (stake != null && stake > Rational.zero)
      ? stake
      : defaultStrategyStake;
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
    stake: usedStake,
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
