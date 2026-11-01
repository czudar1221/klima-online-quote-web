import 'espn_feed.dart';
import 'feed_error.dart';
import 'match_feed.dart';
import 'models.dart';
import 'odds_api_config.dart';
import 'odds_api_feed.dart';
import 'pattern_book.dart';

/// Default live feed: ESPN scoreboards (no key) plus The Odds API when keyed.
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
    final merged = <String, SportsMatch>{};
    for (final m in espn) {
      merged['${m.sport}|${m.home}|${m.away}|${m.kickoff.toIso8601String()}'] =
          m;
    }
    for (final m in odds) {
      merged['${m.sport}|${m.home}|${m.away}|${m.kickoff.toIso8601String()}'] =
          m;
    }
    if (merged.isEmpty && (espnError != null || oddsError != null)) {
      throw FeedException('network');
    }
    final list = merged.values.toList()
      ..sort((a, b) {
        final live = (a.status == MatchStatus.live ? 0 : 1).compareTo(
          b.status == MatchStatus.live ? 0 : 1,
        );
        if (live != 0) return live;
        return a.kickoff.compareTo(b.kickoff);
      });
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
