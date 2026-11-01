import '../engine/probability.dart';
import '../engine/rational.dart';

enum MatchStatus { upcoming, live, finished }

enum Outcome { home, draw, away }

class SportsMatch {
  final String id;
  final String competition;
  final String home;
  final String away;
  final DateTime kickoff;
  final MatchStatus status;
  final int? minute;
  final int? homeScore;
  final int? awayScore;
  final Rational homeOdds;
  final Rational? drawOdds;
  final Rational awayOdds;
  final bool isSample;
  final String? homeTeamId;
  final String? awayTeamId;
  final String sport;
  final String sportLabel;
  final String? leagueKey;
  final String? homeFormCode;
  final String? awayFormCode;

  const SportsMatch({
    required this.id,
    required this.competition,
    required this.home,
    required this.away,
    required this.kickoff,
    required this.status,
    required this.homeOdds,
    required this.awayOdds,
    this.drawOdds,
    this.minute,
    this.homeScore,
    this.awayScore,
    this.isSample = false,
    this.homeTeamId,
    this.awayTeamId,
    this.sport = 'soccer',
    this.sportLabel = 'Labdarúgás',
    this.leagueKey,
    this.homeFormCode,
    this.awayFormCode,
  });

  bool get hasDraw => drawOdds != null;

  bool get hasValidOdds =>
      homeOdds > Rational.one &&
      awayOdds > Rational.one &&
      (drawOdds == null || drawOdds! > Rational.one);

  Rational oddsFor(Outcome o) => switch (o) {
    Outcome.home => homeOdds,
    Outcome.draw => drawOdds ?? Rational.one,
    Outcome.away => awayOdds,
  };

  SportsMatch copyWith({
    String? id,
    String? competition,
    String? home,
    String? away,
    DateTime? kickoff,
    MatchStatus? status,
    int? minute,
    int? homeScore,
    int? awayScore,
    Rational? homeOdds,
    Rational? drawOdds,
    Rational? awayOdds,
    bool? isSample,
    String? homeTeamId,
    String? awayTeamId,
    String? sport,
    String? sportLabel,
    String? leagueKey,
    String? homeFormCode,
    String? awayFormCode,
    bool clearDrawOdds = false,
  }) {
    return SportsMatch(
      id: id ?? this.id,
      competition: competition ?? this.competition,
      home: home ?? this.home,
      away: away ?? this.away,
      kickoff: kickoff ?? this.kickoff,
      status: status ?? this.status,
      minute: minute ?? this.minute,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      homeOdds: homeOdds ?? this.homeOdds,
      drawOdds: clearDrawOdds ? drawOdds : (drawOdds ?? this.drawOdds),
      awayOdds: awayOdds ?? this.awayOdds,
      isSample: isSample ?? this.isSample,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      sport: sport ?? this.sport,
      sportLabel: sportLabel ?? this.sportLabel,
      leagueKey: leagueKey ?? this.leagueKey,
      homeFormCode: homeFormCode ?? this.homeFormCode,
      awayFormCode: awayFormCode ?? this.awayFormCode,
    );
  }

  MarketProbabilities get market => MarketProbabilities.fromDecimalOdds([
    homeOdds,
    if (drawOdds != null) drawOdds!,
    awayOdds,
  ]);

  Map<String, dynamic> toJson() => {
    'id': id,
    'competition': competition,
    'home': home,
    'away': away,
    'kickoff': kickoff.toIso8601String(),
    'status': status.name,
    'minute': minute,
    'homeScore': homeScore,
    'awayScore': awayScore,
    'homeOdds': homeOdds.toString(),
    'drawOdds': drawOdds?.toString(),
    'awayOdds': awayOdds.toString(),
    'isSample': isSample,
    'homeTeamId': homeTeamId,
    'awayTeamId': awayTeamId,
    'sport': sport,
    'sportLabel': sportLabel,
    'leagueKey': leagueKey,
    'homeFormCode': homeFormCode,
    'awayFormCode': awayFormCode,
  };

  factory SportsMatch.fromJson(Map<String, dynamic> json) {
    return SportsMatch(
      id: json['id'] as String,
      competition: json['competition'] as String,
      home: json['home'] as String,
      away: json['away'] as String,
      kickoff: DateTime.parse(json['kickoff'] as String),
      status: MatchStatus.values.byName(json['status'] as String),
      minute: json['minute'] as int?,
      homeScore: json['homeScore'] as int?,
      awayScore: json['awayScore'] as int?,
      homeOdds: _parseStored(json['homeOdds'] as String),
      drawOdds: json['drawOdds'] == null
          ? null
          : _parseStored(json['drawOdds'] as String),
      awayOdds: _parseStored(json['awayOdds'] as String),
      isSample: json['isSample'] as bool? ?? false,
      homeTeamId: json['homeTeamId'] as String?,
      awayTeamId: json['awayTeamId'] as String?,
      sport: json['sport'] as String? ?? 'soccer',
      sportLabel: json['sportLabel'] as String? ?? 'Labdarúgás',
      leagueKey: json['leagueKey'] as String?,
      homeFormCode: json['homeFormCode'] as String?,
      awayFormCode: json['awayFormCode'] as String?,
    );
  }

  static Rational _parseStored(String raw) {
    if (raw.contains('/')) {
      final p = raw.split('/');
      return Rational(BigInt.parse(p[0]), BigInt.parse(p[1]));
    }
    return Rational.parseDecimal(raw);
  }
}

class SlipLeg {
  final SportsMatch match;
  final Outcome pick;

  const SlipLeg({required this.match, required this.pick});
}

class HistoryEntry {
  final String id;
  final DateTime createdAt;
  final String summary;
  final String percent;
  final String mode;
  final int requiredHits;

  const HistoryEntry({
    required this.id,
    required this.createdAt,
    required this.summary,
    required this.percent,
    required this.mode,
    required this.requiredHits,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'summary': summary,
    'percent': percent,
    'mode': mode,
    'requiredHits': requiredHits,
  };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
    id: json['id'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    summary: json['summary'] as String,
    percent: json['percent'] as String,
    mode: json['mode'] as String,
    requiredHits: json['requiredHits'] as int,
  );
}
