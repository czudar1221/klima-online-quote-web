import '../engine/rational.dart';
import '../l10n/copy.dart';
import 'models.dart';
import 'squad.dart';

enum PatternSignal { oddsOnly, form, absence, formAndAbsence }

String patternLineOf(PatternSignal signal) => switch (signal) {
  PatternSignal.oddsOnly => Copy.patternOddsOnly,
  PatternSignal.form => Copy.patternForm,
  PatternSignal.absence => Copy.patternAbsence,
  PatternSignal.formAndAbsence => Copy.patternFormAbsence,
};

/// W/D/L from ESPN `form` strings such as `WLLDW`. Unknown letters skipped.
List<FormResult> parseFormCode(String? code) {
  if (code == null || code.isEmpty) return const [];
  final out = <FormResult>[];
  for (final unit in code.toUpperCase().codeUnits) {
    switch (String.fromCharCode(unit)) {
      case 'W':
        out.add(FormResult.win);
      case 'D':
        out.add(FormResult.draw);
      case 'L':
        out.add(FormResult.loss);
    }
  }
  return List.unmodifiable(out);
}

class FinishedResult {
  final String homeId;
  final String awayId;
  final String homeName;
  final String awayName;
  final int homeScore;
  final int awayScore;
  final DateTime kickoff;
  final bool allowsDraw;

  const FinishedResult({
    required this.homeId,
    required this.awayId,
    required this.homeName,
    required this.awayName,
    required this.homeScore,
    required this.awayScore,
    required this.kickoff,
    required this.allowsDraw,
  });

  FormResult resultFor(String teamId) {
    final home = teamId == homeId;
    if (homeScore == awayScore) {
      return allowsDraw ? FormResult.draw : FormResult.loss;
    }
    final won = home ? homeScore > awayScore : awayScore > homeScore;
    return won ? FormResult.win : FormResult.loss;
  }
}

class PatternSnapshot {
  final TeamProfile? home;
  final TeamProfile? away;
  final bool homeFormLive;
  final bool awayFormLive;
  final bool homeAbsenceLive;
  final bool awayAbsenceLive;

  const PatternSnapshot({
    this.home,
    this.away,
    required this.homeFormLive,
    required this.awayFormLive,
    required this.homeAbsenceLive,
    required this.awayAbsenceLive,
  });

  bool get bothForm => homeFormLive && awayFormLive;
  bool get anyAbsence =>
      (homeAbsenceLive && (home?.players.isNotEmpty ?? false)) ||
      (awayAbsenceLive && (away?.players.isNotEmpty ?? false));

  bool get canBlend =>
      bothForm || (homeAbsenceLive && awayAbsenceLive && anyAbsence);

  PatternSignal get signal {
    if (bothForm && anyAbsence) return PatternSignal.formAndAbsence;
    if (bothForm) return PatternSignal.form;
    if (anyAbsence && homeAbsenceLive && awayAbsenceLive) {
      return PatternSignal.absence;
    }
    return PatternSignal.oddsOnly;
  }

  String formLabel(bool homeSide) {
    final live = homeSide ? homeFormLive : awayFormLive;
    final team = homeSide ? home : away;
    if (!live || team == null || team.recentForm.isEmpty) {
      return Copy.patternNoForm;
    }
    return team.recentForm
        .map(
          (r) => switch (r) {
            FormResult.win => 'W',
            FormResult.draw => 'D',
            FormResult.loss => 'L',
          },
        )
        .join();
  }

  String absenceLabel(bool homeSide) {
    final live = homeSide ? homeAbsenceLive : awayAbsenceLive;
    if (!live) return Copy.patternNoAbsence;
    final team = homeSide ? home : away;
    final names = [
      for (final p in team?.players ?? const <PlayerProfile>[])
        if (!p.available) p.name,
    ];
    if (names.isEmpty) return Copy.patternNoListedAbsence;
    return names.join(', ');
  }
}

class PatternBook {
  PatternBook({
    Map<String, List<FormResult>>? formByTeam,
    Map<String, List<PlayerProfile>>? injuriesByTeam,
    Set<String>? injuryKnownTeams,
  }) : formByTeam = formByTeam ?? {},
       injuriesByTeam = injuriesByTeam ?? {},
       injuryKnownTeams = injuryKnownTeams ?? {};

  final Map<String, List<FormResult>> formByTeam;
  final Map<String, List<PlayerProfile>> injuriesByTeam;
  final Set<String> injuryKnownTeams;

  static String teamKey({String? id, required String name, required String sport}) {
    if (id != null && id.isNotEmpty) return '$sport#$id';
    return '$sport#${name.trim().toLowerCase()}';
  }

  void addForm(String key, List<FormResult> form) {
    if (form.isEmpty) return;
    final trimmed = form.length <= 5 ? form : form.sublist(form.length - 5);
    formByTeam[key] = List.unmodifiable(trimmed);
  }

  void addFinished(String sport, FinishedResult game) {
    void apply(String id, String name) {
      final key = teamKey(id: id, name: name, sport: sport);
      final next = [
        ...?formByTeam[key],
        game.resultFor(id),
      ];
      addForm(key, next);
    }

    apply(game.homeId, game.homeName);
    apply(game.awayId, game.awayName);
  }

  PatternSnapshot snapshot(SportsMatch match) {
    final homeKey = teamKey(
      id: match.homeTeamId,
      name: match.home,
      sport: match.sport,
    );
    final awayKey = teamKey(
      id: match.awayTeamId,
      name: match.away,
      sport: match.sport,
    );
    var homeForm = parseFormCode(match.homeFormCode);
    var awayForm = parseFormCode(match.awayFormCode);
    if (homeForm.isEmpty) homeForm = formByTeam[homeKey] ?? const [];
    if (awayForm.isEmpty) awayForm = formByTeam[awayKey] ?? const [];
    final homeKnown = injuryKnownTeams.contains(homeKey);
    final awayKnown = injuryKnownTeams.contains(awayKey);
    final homeInj = injuriesByTeam[homeKey] ?? const <PlayerProfile>[];
    final awayInj = injuriesByTeam[awayKey] ?? const <PlayerProfile>[];
    TeamProfile? profile({
      required String id,
      required String name,
      required List<FormResult> form,
      required List<PlayerProfile> players,
    }) {
      if (form.isEmpty && players.isEmpty) return null;
      return TeamProfile(
        id: id,
        name: name,
        attack: Rational.one,
        defense: Rational.one,
        recentForm: form,
        players: players,
        curated: false,
      );
    }

    return PatternSnapshot(
      home: profile(
        id: match.homeTeamId ?? homeKey,
        name: match.home,
        form: homeForm,
        players: homeInj,
      ),
      away: profile(
        id: match.awayTeamId ?? awayKey,
        name: match.away,
        form: awayForm,
        players: awayInj,
      ),
      homeFormLive: homeForm.isNotEmpty,
      awayFormLive: awayForm.isNotEmpty,
      homeAbsenceLive: homeKnown,
      awayAbsenceLive: awayKnown,
    );
  }
}
