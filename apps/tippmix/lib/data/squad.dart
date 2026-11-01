import '../engine/rational.dart';

enum FormResult { win, draw, loss }

enum PlayerRole { goalkeeper, defender, midfielder, forward }

class PlayerProfile {
  final String name;
  final PlayerRole role;
  final Rational importance;
  final bool available;

  const PlayerProfile({
    required this.name,
    required this.role,
    required this.importance,
    this.available = true,
  });
}

class TeamProfile {
  final String id;
  final String name;
  final List<String> aliases;
  final Rational attack;
  final Rational defense;
  final List<FormResult> recentForm;
  final List<PlayerProfile> players;

  /// Curated snapshot baked into the app — not a live injury/form feed.
  final bool curated;

  const TeamProfile({
    required this.id,
    required this.name,
    required this.attack,
    required this.defense,
    this.aliases = const [],
    this.recentForm = const [],
    this.players = const [],
    this.curated = true,
  });
}

class TeamDirectory {
  TeamDirectory(List<TeamProfile> teams)
    : _byId = {for (final t in teams) t.id: t},
      _byName = {
        for (final t in teams) t.name.toLowerCase(): t,
        for (final t in teams)
          for (final a in t.aliases) a.toLowerCase(): t,
      };

  final Map<String, TeamProfile> _byId;
  final Map<String, TeamProfile> _byName;

  Iterable<TeamProfile> get teams => _byId.values;

  TeamProfile? find({String? id, String? name}) {
    if (id != null) {
      final hit = _byId[id];
      if (hit != null) return hit;
    }
    if (name != null) {
      return _byName[name.trim().toLowerCase()];
    }
    return null;
  }
}
