import 'espn_feed.dart';
import 'feed_error.dart';
import 'match_feed.dart';
import 'models.dart';
import 'odds_api_config.dart';
import 'odds_api_feed.dart';
import 'pattern_book.dart';
import 'team_names.dart';

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
  if (odds.isEmpty) {
    return espn.where((m) => m.hasValidOdds && !m.isSample).toList();
  }
  final usedEspn = <int>{};
  final out = <SportsMatch>[];
  for (final o in odds) {
    var merged = o;
    for (var i = 0; i < espn.length; i++) {
      if (usedEspn.contains(i)) continue;
      final e = espn[i];
      final link = fixtureNameLink(e, o);
      if (link == FixtureLink.none) continue;
      usedEspn.add(i);
      merged = _attachEspnForm(o, e, reversed: link == FixtureLink.reversed);
      break;
    }
    out.add(merged);
  }
  for (var i = 0; i < espn.length; i++) {
    if (usedEspn.contains(i) || !espn[i].hasValidOdds) continue;
    out.add(espn[i]);
  }
  return out.where((m) => m.hasValidOdds && !m.isSample).toList();
}

enum FixtureLink { none, same, reversed }

FixtureLink fixtureNameLink(SportsMatch espn, SportsMatch odds) {
  if (!fixturesLooselyMatch(
    sportA: espn.sport,
    homeA: espn.home,
    awayA: espn.away,
    kickoffA: espn.kickoff,
    sportB: odds.sport,
    homeB: odds.home,
    awayB: odds.away,
    kickoffB: odds.kickoff,
  )) {
    return FixtureLink.none;
  }
  final same =
      namesLooselyEqual(espn.home, odds.home) &&
      namesLooselyEqual(espn.away, odds.away);
  return same ? FixtureLink.same : FixtureLink.reversed;
}

SportsMatch _attachEspnForm(
  SportsMatch odds,
  SportsMatch espn, {
  required bool reversed,
}) {
  return odds.copyWith(
    status: espn.status,
    minute: espn.minute,
    homeScore: reversed ? espn.awayScore : espn.homeScore,
    awayScore: reversed ? espn.homeScore : espn.awayScore,
    homeTeamId: reversed ? espn.awayTeamId : espn.homeTeamId,
    awayTeamId: reversed ? espn.homeTeamId : espn.awayTeamId,
    leagueKey: espn.leagueKey,
    homeFormCode: reversed ? espn.awayFormCode : espn.homeFormCode,
    awayFormCode: reversed ? espn.homeFormCode : espn.awayFormCode,
  );
}
