import '../engine/rational.dart';
import 'match_feed.dart';
import 'models.dart';

/// Local sample schedule. Replace with an official feed via [MatchFeed].
class SampleMatchFeed implements MatchFeed {
  SampleMatchFeed({DateTime? now}) : _now = now ?? DateTime.now();

  final DateTime _now;

  @override
  Future<List<SportsMatch>> upcoming() async => _all
      .where((m) => m.status == MatchStatus.upcoming)
      .toList(growable: false);

  @override
  Future<List<SportsMatch>> live() async =>
      _all.where((m) => m.status == MatchStatus.live).toList(growable: false);

  List<SportsMatch> get _all {
    final day = DateTime(_now.year, _now.month, _now.day);
    Rational o(String s) => Rational.parseDecimal(s);
    return [
      SportsMatch(
        id: 'sample-live-1',
        competition: 'NB I',
        home: 'Ferencváros',
        away: 'Puskás Akadémia',
        kickoff: day.add(const Duration(hours: 16)),
        status: MatchStatus.live,
        minute: 64,
        homeScore: 1,
        awayScore: 1,
        homeOdds: o('1,85'),
        drawOdds: o('3,40'),
        awayOdds: o('4,20'),
      ),
      SportsMatch(
        id: 'sample-live-2',
        competition: 'NB I',
        home: 'Debrecen',
        away: 'Kisvárda',
        kickoff: day.add(const Duration(hours: 16, minutes: 30)),
        status: MatchStatus.live,
        minute: 21,
        homeScore: 0,
        awayScore: 0,
        homeOdds: o('2,15'),
        drawOdds: o('3,20'),
        awayOdds: o('3,35'),
      ),
      SportsMatch(
        id: 'sample-up-1',
        competition: 'NB I',
        home: 'Újpest',
        away: 'Diósgyőr',
        kickoff: day.add(const Duration(hours: 19, minutes: 30)),
        status: MatchStatus.upcoming,
        homeOdds: o('2,05'),
        drawOdds: o('3,30'),
        awayOdds: o('3,50'),
      ),
      SportsMatch(
        id: 'sample-up-2',
        competition: 'NB I',
        home: 'Zalaegerszeg',
        away: 'Paksi FC',
        kickoff: day.add(const Duration(days: 1, hours: 18)),
        status: MatchStatus.upcoming,
        homeOdds: o('2,70'),
        drawOdds: o('3,25'),
        awayOdds: o('2,55'),
      ),
      SportsMatch(
        id: 'sample-up-3',
        competition: 'Magyar Kupa',
        home: 'Honvéd',
        away: 'Fehérvár',
        kickoff: day.add(const Duration(days: 2, hours: 17, minutes: 45)),
        status: MatchStatus.upcoming,
        homeOdds: o('2,90'),
        drawOdds: o('3,15'),
        awayOdds: o('2,40'),
      ),
      SportsMatch(
        id: 'sample-up-4',
        competition: 'NB I',
        home: 'Nyíregyháza',
        away: 'MTK Budapest',
        kickoff: day.add(const Duration(days: 2, hours: 20)),
        status: MatchStatus.upcoming,
        homeOdds: o('3,10'),
        drawOdds: o('3,20'),
        awayOdds: o('2,25'),
      ),
    ];
  }
}
