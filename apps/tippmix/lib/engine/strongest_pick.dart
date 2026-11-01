import '../data/models.dart';
import 'rational.dart';
import 'strength.dart';

class StrongestPick {
  final Outcome outcome;
  final Rational chance;
  final ThreeWay chances;
  final bool twoWay;

  const StrongestPick({
    required this.outcome,
    required this.chance,
    required this.chances,
    required this.twoWay,
  });
}

/// Highest computed chance among 1 / X / 2 (X omitted on two-way markets).
/// Ties break 1, then X, then 2 — never inflate the number.
StrongestPick strongestPick(BlendedMatch blended, {required bool hasDraw}) {
  final c = blended.blended;
  var best = Outcome.home;
  var bestP = c.home;
  if (hasDraw && c.draw > bestP) {
    best = Outcome.draw;
    bestP = c.draw;
  }
  if (c.away > bestP) {
    best = Outcome.away;
    bestP = c.away;
  }
  return StrongestPick(
    outcome: best,
    chance: bestP,
    chances: c,
    twoWay: !hasDraw,
  );
}

String outcomeLabel(Outcome o) => switch (o) {
  Outcome.home => '1',
  Outcome.draw => 'X',
  Outcome.away => '2',
};
