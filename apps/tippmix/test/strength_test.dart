import 'package:flutter_test/flutter_test.dart';
import 'package:tippmix_kalkulator/data/curated_squads.dart';
import 'package:tippmix_kalkulator/data/models.dart';
import 'package:tippmix_kalkulator/data/squad.dart';
import 'package:tippmix_kalkulator/engine/probability.dart';
import 'package:tippmix_kalkulator/engine/rational.dart';
import 'package:tippmix_kalkulator/engine/strength.dart';

TeamProfile _team({
  required String id,
  required Rational attack,
  required Rational defense,
  List<FormResult> form = const [],
  List<PlayerProfile> players = const [],
}) {
  return TeamProfile(
    id: id,
    name: id,
    attack: attack,
    defense: defense,
    recentForm: form,
    players: players,
  );
}

SportsMatch _match({
  required String home,
  required String away,
  String homeOdds = '2,00',
  String drawOdds = '3,50',
  String awayOdds = '3,80',
  String? homeId,
  String? awayId,
}) {
  return SportsMatch(
    id: 't',
    competition: 'NB I',
    home: home,
    away: away,
    homeTeamId: homeId,
    awayTeamId: awayId,
    kickoff: DateTime(2026, 11, 1),
    status: MatchStatus.upcoming,
    homeOdds: Rational.parseDecimal(homeOdds),
    drawOdds: Rational.parseDecimal(drawOdds),
    awayOdds: Rational.parseDecimal(awayOdds),
  );
}

void main() {
  final one = Rational.one;
  final star = PlayerProfile(
    name: 'Csillag',
    role: PlayerRole.forward,
    importance: Rational(BigInt.one, BigInt.from(4)),
  );

  group('1X2 csapatmodell', () {
    test('azonos csapatoknál a hazai előny P(1) > P(2), összeg pontosan 1', () {
      final t = _team(id: 'a', attack: one, defense: one);
      final p = StrengthModel.model1x2(home: t, away: t);
      expect(p.sum, Rational.one);
      expect(p.home > p.away, isTrue);
      expect(p.draw > Rational.zero, isTrue);
    });

    test('jobb forma növeli a hazai győzelem esélyét', () {
      final weakForm = _team(
        id: 'h',
        attack: one,
        defense: one,
        form: List.filled(5, FormResult.loss),
      );
      final strongForm = _team(
        id: 'h',
        attack: one,
        defense: one,
        form: List.filled(5, FormResult.win),
      );
      final away = _team(id: 'a', attack: one, defense: one);
      final low = StrengthModel.model1x2(home: weakForm, away: away);
      final high = StrengthModel.model1x2(home: strongForm, away: away);
      expect(high.home > low.home, isTrue);
      expect(high.sum, Rational.one);
      expect(low.sum, Rational.one);
    });

    test('hiányzó gólvágó csökkenti a hazai győzelem esélyét', () {
      final full = _team(id: 'h', attack: one, defense: one, players: [star]);
      final missing = _team(
        id: 'h',
        attack: one,
        defense: one,
        players: [
          PlayerProfile(
            name: star.name,
            role: star.role,
            importance: star.importance,
            available: false,
          ),
        ],
      );
      final away = _team(id: 'a', attack: one, defense: one);
      final withStar = StrengthModel.model1x2(home: full, away: away);
      final without = StrengthModel.model1x2(home: missing, away: away);
      expect(without.home < withStar.home, isTrue);
      expect(without.away > withStar.away, isTrue);
      expect(without.sum, Rational.one);
    });
  });

  group('piac–modell keverék', () {
    final market = ThreeWay(
      home: Rational(BigInt.one, BigInt.two),
      draw: Rational(BigInt.one, BigInt.from(4)),
      away: Rational(BigInt.one, BigInt.from(4)),
    );
    final model = ThreeWay(
      home: Rational(BigInt.from(2), BigInt.from(5)),
      draw: Rational(BigInt.from(2), BigInt.from(5)),
      away: Rational(BigInt.one, BigInt.from(5)),
    );

    test('λ=0 a piacot adja, λ=1 a modellt', () {
      expect(
        StrengthModel.linearPool(market, model, Rational.zero),
        market,
      );
      expect(
        StrengthModel.linearPool(market, model, Rational.one),
        model,
      );
    });

    test('λ=2/5 konvex kombináció, összeg pontosan 1', () {
      final blended = StrengthModel.linearPool(
        market,
        model,
        StrengthWeights.modelBlend,
      );
      final rest = Rational.one - StrengthWeights.modelBlend;
      expect(
        blended.home,
        rest * market.home + StrengthWeights.modelBlend * model.home,
      );
      expect(blended.sum, Rational.one);
    });

    test('keret nélkül a keverék a de-vigelt piac', () {
      final match = _match(home: 'Ismeretlen A', away: 'Ismeretlen B');
      final blended = StrengthModel.blend(match, TeamDirectory([]));
      expect(blended.usedSquads, isFalse);
      expect(blended.modelWeight, Rational.zero);
      expect(blended.blended.home, match.market.fair[0]);
      expect(blended.blended.sum, Rational.one);
    });

    test('kurált kerettel λ=2/5 és a keverék a két vektor között van', () {
      final dir = curatedHungarianSquads();
      final match = _match(
        home: 'Ferencváros',
        away: 'Puskás Akadémia',
        homeId: 'ferencvaros',
        awayId: 'puskas',
      );
      final b = StrengthModel.blend(match, dir);
      expect(b.usedSquads, isTrue);
      expect(b.modelWeight, StrengthWeights.modelBlend);
      expect(b.model, isNotNull);
      expect(b.blended.sum, Rational.one);
      expect(b.model!.sum, Rational.one);
      final rest = Rational.one - StrengthWeights.modelBlend;
      expect(
        b.blended.home,
        rest * b.market.fair[0] + StrengthWeights.modelBlend * b.model!.home,
      );
    });
  });

  group('szelvény a kevert valószínűséggel', () {
    test('akkumulátor a kevert lábak szorzata', () {
      final dir = curatedHungarianSquads();
      final a = StrengthModel.blend(
        _match(
          home: 'Ferencváros',
          away: 'Újpest',
          homeId: 'ferencvaros',
          awayId: 'ujpest',
        ),
        dir,
      );
      final b = StrengthModel.blend(
        _match(
          home: 'Paksi FC',
          away: 'Debrecen',
          homeId: 'paks',
          awayId: 'debrecen',
        ),
        dir,
      );
      final events = IndependentEvents([a.blended.home, b.blended.home]);
      expect(events.accumulator, a.blended.home * b.blended.home);
      var sum = Rational.zero;
      for (final p in events.distributionExactlyK()) {
        sum += p;
      }
      expect(sum, Rational.one);
    });
  });
}
