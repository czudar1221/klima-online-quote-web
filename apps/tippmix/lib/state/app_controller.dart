import 'package:flutter/foundation.dart';

import '../data/curated_squads.dart';
import '../data/feed_error.dart';
import '../data/live_feed.dart';
import '../data/match_feed.dart';
import '../data/models.dart';
import '../data/squad.dart';
import '../engine/rational.dart';
import '../engine/strategy.dart';
import '../engine/strength.dart';
import '../engine/strongest_pick.dart';
import '../l10n/copy.dart';

class AppController extends ChangeNotifier {
  AppController({
    required MatchFeed feed,
    TeamDirectory? squads,
  }) : _feed = feed,
       squads = squads ?? curatedHungarianSquads();

  final MatchFeed _feed;
  final TeamDirectory squads;

  List<SportsMatch> matches = [];
  bool loading = true;
  String? error;
  Rational stake = defaultStrategyStake;

  void setStakeInput(String raw) {
    final parsed = parseStakeHuf(raw);
    if (parsed == null || parsed == stake) return;
    stake = parsed;
    notifyListeners();
  }

  BlendedMatch blendedFor(SportsMatch match) =>
      StrengthModel.blend(match, squads);

  StrongestPick pickFor(SportsMatch match) =>
      strongestPick(blendedFor(match), hasDraw: match.hasDraw);

  StrategyBoard get board =>
      buildStrategy(matches, blendedFor, stake: stake);

  String whyFor(SportsMatch match) {
    final pick = pickFor(match);
    final chances = <Rational>[
      pick.chances.home,
      if (match.hasDraw) pick.chances.draw,
      pick.chances.away,
    ]..sort((a, b) => b.compareTo(a));
    if (chances.length >= 2) {
      final gap = chances[0] - chances[1];
      if (gap <= Rational(BigInt.one, BigInt.from(10))) {
        return Copy.closeMatch;
      }
    }
    return switch (pick.outcome) {
      Outcome.home => Copy.favoriteHome,
      Outcome.draw => Copy.favoriteDraw,
      Outcome.away => Copy.favoriteAway,
    };
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final feed = _feed;
      final list = feed is LiveSportsFeed
          ? await feed.fetch()
          : [
              ...await feed.upcoming(),
              ...await feed.live(),
            ];
      final seen = <String>{};
      matches = [
        for (final m in list)
          if (seen.add(m.id) && !m.isSample) m,
      ];
    } on FeedException {
      matches = [];
      error = Copy.errorNetwork;
    } catch (_) {
      matches = [];
      error = Copy.errorNetwork;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
