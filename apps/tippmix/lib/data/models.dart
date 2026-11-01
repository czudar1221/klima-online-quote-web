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
  });

  bool get hasDraw => drawOdds != null;

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
