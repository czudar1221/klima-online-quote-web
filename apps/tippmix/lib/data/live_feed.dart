import 'espn_feed.dart';
import 'feed_error.dart';
import 'match_feed.dart';
import 'models.dart';
import 'odds_api_config.dart';
import 'odds_api_feed.dart';
import 'pattern_book.dart';

/// Default live feed: ESPN scoreboards (form / results) plus The Odds API prices.
class LiveSportsFeed implements MatchFeed {
  LiveSportsFeed({EspnLiveFeed? espn, OddsApiFeed? odds})
    : _espn = espn ?? EspnLiveFeed(),
      _odds = odds ?? OddsApiFeed();

  final EspnLiveFeed _espn;
  final OddsApiFeed _odds;

  @override
  Future<List<SportsMatch>> upcoming() async => fetch();

  @override
  Future<List<SportsMatch>> live() async =>
      (await fetch()).where((m) => m.status == MatchStatus.live).toList();

  Future<List<SportsMatch>> fetch() async {
    Object? espnError;
    Object? oddsError;
    var espn = <SportsMatch>[];
    var odds = <SportsMatch>[];
    try {
      espn = await _espn.fetch();
    } catch (e) {
      espnError = e;
    }
    if (OddsApiConfig.isConfigured) {
      try {
        odds = await _odds.fetch();
      } catch (e) {
        oddsError = e;
      }
    }
    final list = mergeEspnFormWithOdds(espn, odds)
      ..sort((a, b) {
        final live = (a.status == MatchStatus.live ? 0 : 1).compareTo(
          b.status == MatchStatus.live ? 0 : 1,
        );
        if (live != 0) return live;
        return a.kickoff.compareTo(b.kickoff);
      });
    if (list.isEmpty && (espnError != null || oddsError != null)) {
      throw FeedException('network');
    }
    return list;
  }

  Future<({List<SportsMatch> matches, PatternBook patterns})> fetchBundle() async {
    final matches = await fetch();
    PatternBook patterns = PatternBook();
    try {
      patterns = await _espn.fetchPatterns(matches);
    } catch (_) {
      patterns = PatternBook();
    }
    return (matches: matches, patterns: patterns);
  }
}

/// Odds API is the price source. ESPN keeps form, team ids, score, status.
List<SportsMatch> mergeEspnFormWithOdds(
  List<SportsMatch> espn,
  List<SportsMatch> odds,
) {
  final usedOdds = <int>{};
  final out = <SportsMatch>[];
  for (final e in espn) {
    var merged = e;
    for (var i = 0; i < odds.length; i++) {
      if (usedOdds.contains(i)) continue;
      if (!_sameFixture(e, odds[i])) continue;
      usedOdds.add(i);
      final o = odds[i];
      merged = e.copyWith(
        homeOdds: o.homeOdds,
        awayOdds: o.awayOdds,
        drawOdds: o.drawOdds,
        clearDrawOdds: o.drawOdds == null,
      );
      break;
    }
    out.add(merged);
  }
  for (var i = 0; i < odds.length; i++) {
    if (!usedOdds.contains(i)) out.add(odds[i]);
  }
  return out.where((m) => m.hasValidOdds && !m.isSample).toList();
}

bool _sameFixture(SportsMatch a, SportsMatch b) {
  if (a.sport != b.sport) return false;
  if (_fold(a.home) != _fold(b.home) || _fold(a.away) != _fold(b.away)) {
    return false;
  }
  return a.kickoff.difference(b.kickoff).abs() <= const Duration(hours: 18);
}

String _fold(String name) =>
    name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
