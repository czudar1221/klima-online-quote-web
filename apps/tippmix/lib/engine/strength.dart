import '../data/models.dart';
import '../data/pattern_book.dart';
import '../data/squad.dart';
import 'probability.dart';
import 'rational.dart';

/// Documented 1X2 strength model with exact rationals.
///
/// Effective attack/defense:
///   formRate = points(last N) / (3N), empty form → 1/2
///   formMult = 1 + α (2 formRate − 1),  α = 1/5
///   att' = att · formMult · (1 − min(1/2, attackPenalty))
///   def' = def · formMult · (1 − min(1/2, defensePenalty))
///   attackPenalty = Σ importance of unavailable forwards + half of mids
///   defensePenalty = Σ importance of unavailable GK/defenders + half of mids
///
/// Relative scoring rates:
///   λ_H = att'_H · homeAdv / def'_A
///   λ_A = att'_A / def'_H
///   homeAdv = 6/5
///
/// Three-way (harmonic draw mass — no square roots, exact):
///   d = δ · 2 λ_H λ_A / (λ_H + λ_A),  δ = 4/5
///   Z = λ_H + λ_A + d
///   P_model(H)=λ_H/Z, P_model(A)=λ_A/Z, P_model(D)=d/Z
///
/// Blend with de-vigged odds (linear opinion pool):
///   P* = (1−λ) P_fair + λ P_model,  λ = 2/5 if both teams have live form
///   (or a real absence list on both sides) else 0. Never invent history.
///
/// Displayed % uses P*. Not a guaranteed outcome. Pattern is not a win claim.
abstract final class StrengthWeights {
  static final formAmplitude = Rational(BigInt.one, BigInt.from(5));
  static final modelBlend = Rational(BigInt.two, BigInt.from(5));
  static final homeAdvantage = Rational(BigInt.from(6), BigInt.from(5));
  static final drawScale = Rational(BigInt.from(4), BigInt.from(5));
  static final half = Rational(BigInt.one, BigInt.two);
}

class ThreeWay {
  final Rational home;
  final Rational draw;
  final Rational away;

  const ThreeWay({
    required this.home,
    required this.draw,
    required this.away,
  });

  Rational operator [](Outcome o) => switch (o) {
    Outcome.home => home,
    Outcome.draw => draw,
    Outcome.away => away,
  };

  Rational get sum => home + draw + away;

  List<Rational> get asList => [home, draw, away];

  @override
  bool operator ==(Object other) =>
      other is ThreeWay &&
      home == other.home &&
      draw == other.draw &&
      away == other.away;

  @override
  int get hashCode => Object.hash(home, draw, away);
}

class BlendedMatch {
  final MarketProbabilities market;
  final ThreeWay? model;
  final ThreeWay blended;
  final Rational modelWeight;
  final TeamProfile? homeProfile;
  final TeamProfile? awayProfile;
  final PatternSignal pattern;

  const BlendedMatch({
    required this.market,
    required this.model,
    required this.blended,
    required this.modelWeight,
    this.homeProfile,
    this.awayProfile,
    this.pattern = PatternSignal.oddsOnly,
  });

  bool get usedSquads => model != null && modelWeight > Rational.zero;
}

abstract final class StrengthModel {
  static Rational formMultiplier(TeamProfile team) {
    final form = team.recentForm;
    if (form.isEmpty) return Rational.one;
    var points = 0;
    for (final r in form) {
      points += switch (r) {
        FormResult.win => 3,
        FormResult.draw => 1,
        FormResult.loss => 0,
      };
    }
    final formRate = Rational(BigInt.from(points), BigInt.from(3 * form.length));
    return Rational.one +
        StrengthWeights.formAmplitude *
            (Rational.fromInt(2) * formRate - Rational.one);
  }

  static ({Rational attack, Rational defense}) playerPenalties(TeamProfile team) {
    var attack = Rational.zero;
    var defense = Rational.zero;
    for (final p in team.players) {
      if (p.available) continue;
      switch (p.role) {
        case PlayerRole.forward:
          attack += p.importance;
        case PlayerRole.goalkeeper:
        case PlayerRole.defender:
          defense += p.importance;
        case PlayerRole.midfielder:
          final half = p.importance * StrengthWeights.half;
          attack += half;
          defense += half;
      }
    }
    return (attack: _capHalf(attack), defense: _capHalf(defense));
  }

  static Rational _capHalf(Rational penalty) =>
      penalty > StrengthWeights.half ? StrengthWeights.half : penalty;

  static ({Rational attack, Rational defense}) effectiveRatings(TeamProfile team) {
    final form = formMultiplier(team);
    final pen = playerPenalties(team);
    return (
      attack: team.attack * form * (Rational.one - pen.attack),
      defense: team.defense * form * (Rational.one - pen.defense),
    );
  }

  static ThreeWay model1x2({
    required TeamProfile home,
    required TeamProfile away,
  }) {
    final h = effectiveRatings(home);
    final a = effectiveRatings(away);
    if (a.defense.isZero || h.defense.isZero) {
      throw ArgumentError('defense rating must be positive');
    }
    final lambdaH = h.attack * StrengthWeights.homeAdvantage / a.defense;
    final lambdaA = a.attack / h.defense;
    final denom = lambdaH + lambdaA;
    if (denom.isZero) {
      throw ArgumentError('scoring rates are zero');
    }
    final drawMass =
        StrengthWeights.drawScale *
        Rational.fromInt(2) *
        lambdaH *
        lambdaA /
        denom;
    final z = lambdaH + lambdaA + drawMass;
    return ThreeWay(
      home: lambdaH / z,
      draw: drawMass / z,
      away: lambdaA / z,
    );
  }

  static ThreeWay linearPool(ThreeWay market, ThreeWay model, Rational lambda) {
    if (lambda < Rational.zero || lambda > Rational.one) {
      throw ArgumentError('blend weight out of range');
    }
    final rest = Rational.one - lambda;
    return ThreeWay(
      home: rest * market.home + lambda * model.home,
      draw: rest * market.draw + lambda * model.draw,
      away: rest * market.away + lambda * model.away,
    );
  }

  static ThreeWay modelTwoWay({
    required TeamProfile home,
    required TeamProfile away,
  }) {
    final h = effectiveRatings(home);
    final a = effectiveRatings(away);
    if (a.defense.isZero || h.defense.isZero) {
      throw ArgumentError('defense rating must be positive');
    }
    final lambdaH = h.attack * StrengthWeights.homeAdvantage / a.defense;
    final lambdaA = a.attack / h.defense;
    final z = lambdaH + lambdaA;
    if (z.isZero) {
      throw ArgumentError('scoring rates are zero');
    }
    return ThreeWay(
      home: lambdaH / z,
      draw: Rational.zero,
      away: lambdaA / z,
    );
  }

  static ThreeWay threeWayFromMarket(SportsMatch match) {
    final fair = match.market.fair;
    if (!match.hasDraw) {
      return ThreeWay(
        home: fair[0],
        draw: Rational.zero,
        away: fair[1],
      );
    }
    return ThreeWay(home: fair[0], draw: fair[1], away: fair[2]);
  }

  static BlendedMatch blend(SportsMatch match, TeamDirectory directory) {
    final marketP = match.market;
    final market = threeWayFromMarket(match);
    final soccer = match.sport == 'soccer' && match.hasDraw;
    final home = soccer
        ? directory.find(id: match.homeTeamId, name: match.home)
        : null;
    final away = soccer
        ? directory.find(id: match.awayTeamId, name: match.away)
        : null;
    if (!soccer || home == null || away == null) {
      return BlendedMatch(
        market: marketP,
        model: null,
        blended: market,
        modelWeight: Rational.zero,
        homeProfile: home,
        awayProfile: away,
      );
    }
    final model = model1x2(home: home, away: away);
    final lambda = StrengthWeights.modelBlend;
    return BlendedMatch(
      market: marketP,
      model: model,
      blended: linearPool(market, model, lambda),
      modelWeight: lambda,
      homeProfile: home,
      awayProfile: away,
      pattern: PatternSignal.form,
    );
  }

  /// Live ESPN form / listed absences. λ = 2/5 only when [snap.canBlend].
  static BlendedMatch blendSnapshot(SportsMatch match, PatternSnapshot snap) {
    final marketP = match.market;
    final market = threeWayFromMarket(match);
    if (!snap.canBlend || snap.home == null || snap.away == null) {
      return BlendedMatch(
        market: marketP,
        model: null,
        blended: market,
        modelWeight: Rational.zero,
        homeProfile: snap.home,
        awayProfile: snap.away,
        pattern: PatternSignal.oddsOnly,
      );
    }
    final model = match.hasDraw
        ? model1x2(home: snap.home!, away: snap.away!)
        : modelTwoWay(home: snap.home!, away: snap.away!);
    final lambda = StrengthWeights.modelBlend;
    return BlendedMatch(
      market: marketP,
      model: model,
      blended: linearPool(market, model, lambda),
      modelWeight: lambda,
      homeProfile: snap.home,
      awayProfile: snap.away,
      pattern: snap.signal,
    );
  }
}
