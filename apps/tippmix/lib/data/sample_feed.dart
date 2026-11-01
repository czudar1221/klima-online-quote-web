import '../engine/rational.dart';
import 'match_feed.dart';
import 'models.dart';

/// Local sample schedule. Replace with an official feed via [MatchFeed].
/// Scores/minutes and odds here are **minta**, not a live Tippmix feed.
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
    SportsMatch m({
      required String id,
      required String competition,
      required String home,
      required String away,
      required String homeId,
      required String awayId,
      required Duration offset,
      required MatchStatus status,
      required String h,
      required String d,
      required String a,
      int? minute,
      int? homeScore,
      int? awayScore,
    }) {
      return SportsMatch(
        id: id,
        competition: competition,
        home: home,
        away: away,
        homeTeamId: homeId,
        awayTeamId: awayId,
        kickoff: day.add(offset),
        status: status,
        minute: minute,
        homeScore: homeScore,
        awayScore: awayScore,
        homeOdds: o(h),
        drawOdds: o(d),
        awayOdds: o(a),
      );
    }

    return [
      m(
        id: 'sample-live-1',
        competition: 'NB I',
        home: 'Ferencváros',
        away: 'Puskás Akadémia',
        homeId: 'ferencvaros',
        awayId: 'puskas',
        offset: const Duration(hours: 16),
        status: MatchStatus.live,
        minute: 64,
        homeScore: 1,
        awayScore: 1,
        h: '1,85',
        d: '3,40',
        a: '4,20',
      ),
      m(
        id: 'sample-live-2',
        competition: 'NB I',
        home: 'Debrecen',
        away: 'Kisvárda',
        homeId: 'debrecen',
        awayId: 'kisvarda',
        offset: const Duration(hours: 16, minutes: 30),
        status: MatchStatus.live,
        minute: 21,
        homeScore: 0,
        awayScore: 0,
        h: '2,15',
        d: '3,20',
        a: '3,35',
      ),
      m(
        id: 'sample-up-1',
        competition: 'NB I',
        home: 'Újpest',
        away: 'Diósgyőr',
        homeId: 'ujpest',
        awayId: 'diosgyor',
        offset: const Duration(hours: 19, minutes: 30),
        status: MatchStatus.upcoming,
        h: '2,05',
        d: '3,30',
        a: '3,50',
      ),
      m(
        id: 'sample-up-2',
        competition: 'NB I',
        home: 'Zalaegerszeg',
        away: 'Paksi FC',
        homeId: 'zalaegerszeg',
        awayId: 'paks',
        offset: const Duration(days: 1, hours: 18),
        status: MatchStatus.upcoming,
        h: '2,70',
        d: '3,25',
        a: '2,55',
      ),
      m(
        id: 'sample-up-3',
        competition: 'Magyar Kupa',
        home: 'Honvéd',
        away: 'Fehérvár',
        homeId: 'honved',
        awayId: 'fehervar',
        offset: const Duration(days: 2, hours: 17, minutes: 45),
        status: MatchStatus.upcoming,
        h: '2,90',
        d: '3,15',
        a: '2,40',
      ),
      m(
        id: 'sample-up-4',
        competition: 'NB I',
        home: 'Nyíregyháza',
        away: 'MTK Budapest',
        homeId: 'nyiregyhaza',
        awayId: 'mtk',
        offset: const Duration(days: 2, hours: 20),
        status: MatchStatus.upcoming,
        h: '3,10',
        d: '3,20',
        a: '2,25',
      ),
    ];
  }
}
