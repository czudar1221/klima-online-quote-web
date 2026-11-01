import 'rational.dart';

/// 1X2 (or any mutually exclusive) market from decimal odds.
class MarketProbabilities {
  final List<Rational> odds;
  final List<Rational> implied;
  final List<Rational> fair;
  final Rational overround;

  MarketProbabilities({
    required this.odds,
    required this.implied,
    required this.fair,
    required this.overround,
  });

  /// Implied \(1/o_i\), then fair probabilities \(p_i / \sum p_j\) (overround removed).
  factory MarketProbabilities.fromDecimalOdds(List<Rational> odds) {
    if (odds.isEmpty) {
      throw ArgumentError('odds must not be empty');
    }
    for (final o in odds) {
      if (o <= Rational.one) {
        throw ArgumentError('decimal odds must be greater than 1, got $o');
      }
    }
    final implied = [for (final o in odds) o.inverse];
    var overround = Rational.zero;
    for (final p in implied) {
      overround += p;
    }
    if (overround.isZero) {
      throw ArgumentError('overround is zero');
    }
    final fair = [for (final p in implied) p / overround];
    return MarketProbabilities(
      odds: List.unmodifiable(odds),
      implied: List.unmodifiable(implied),
      fair: List.unmodifiable(fair),
      overround: overround,
    );
  }

  Rational get margin => overround - Rational.one;
}

/// Independent Bernoulli events with possibly different success probabilities.
class IndependentEvents {
  final List<Rational> success;

  IndependentEvents(List<Rational> success)
    : success = List.unmodifiable(success) {
    for (final p in this.success) {
      if (p < Rational.zero || p > Rational.one) {
        throw ArgumentError('probability out of range: $p');
      }
    }
  }

  /// `dist[k] = P(exactly k successes)`. Sum is exactly 1.
  List<Rational> distributionExactlyK() {
    var dp = <Rational>[Rational.one];
    for (final p in success) {
      final q = Rational.one - p;
      final next = List<Rational>.generate(
        dp.length + 1,
        (_) => Rational.zero,
      );
      for (var k = 0; k < dp.length; k++) {
        next[k] += dp[k] * q;
        next[k + 1] += dp[k] * p;
      }
      dp = next;
    }
    return dp;
  }

  Rational probabilityExactly(int k) {
    final dist = distributionExactlyK();
    if (k < 0 || k >= dist.length) {
      return Rational.zero;
    }
    return dist[k];
  }

  Rational probabilityAtLeast(int k) {
    final dist = distributionExactlyK();
    if (k <= 0) return Rational.one;
    if (k >= dist.length) return Rational.zero;
    var sum = Rational.zero;
    for (var i = k; i < dist.length; i++) {
      sum += dist[i];
    }
    return sum;
  }

  /// Accumulator: every leg wins.
  Rational get accumulator => success.fold(Rational.one, (a, p) => a * p);
}

class CalculatorResult {
  final MarketProbabilities? singleMarket;
  final IndependentEvents? events;
  final Rational winChance;
  final int requiredHits;
  final bool isAccumulator;
  final List<String> labels;

  CalculatorResult({
    this.singleMarket,
    this.events,
    required this.winChance,
    required this.requiredHits,
    required this.isAccumulator,
    required this.labels,
  });
}
