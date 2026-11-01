import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tippmix_kalkulator/data/match_feed.dart';
import 'package:tippmix_kalkulator/data/models.dart';
import 'package:tippmix_kalkulator/engine/rational.dart';
import 'package:tippmix_kalkulator/engine/strategy.dart';
import 'package:tippmix_kalkulator/l10n/copy.dart';
import 'package:tippmix_kalkulator/main.dart';
import 'package:tippmix_kalkulator/state/app_controller.dart';

class _FakeFeed implements MatchFeed {
  @override
  Future<List<SportsMatch>> upcoming() async => [
    SportsMatch(
      id: 'b1',
      competition: 'NBA',
      home: 'Celtics',
      away: 'Nets',
      kickoff: DateTime(2026, 11, 1, 1),
      status: MatchStatus.upcoming,
      homeOdds: Rational.parseDecimal('1,40'),
      awayOdds: Rational.parseDecimal('3,20'),
      isSample: false,
      sport: 'basketball',
      sportLabel: 'Kosárlabda',
    ),
    SportsMatch(
      id: 'b2',
      competition: 'NBA',
      home: 'Lakers',
      away: 'Suns',
      kickoff: DateTime(2026, 11, 1, 2),
      status: MatchStatus.live,
      homeOdds: Rational.parseDecimal('1,85'),
      awayOdds: Rational.parseDecimal('2,05'),
      isSample: false,
      sport: 'basketball',
      sportLabel: 'Kosárlabda',
    ),
    SportsMatch(
      id: 's1',
      competition: 'EPL',
      home: 'Liverpool',
      away: 'Arsenal',
      kickoff: DateTime(2026, 11, 1, 3),
      status: MatchStatus.upcoming,
      homeOdds: Rational.parseDecimal('1,35'),
      drawOdds: Rational.parseDecimal('5,00'),
      awayOdds: Rational.parseDecimal('8,50'),
      isSample: false,
      sport: 'soccer',
      sportLabel: 'Labdarúgás',
    ),
  ];

  @override
  Future<List<SportsMatch>> live() async => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('stratégiai asztal: szelvény, figyelőlista, státusz', (
    tester,
  ) async {
    await initializeDateFormatting('hu');
    final controller = AppController(feed: _FakeFeed());
    await controller.load();
    await tester.pumpWidget(TippmixApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text(Copy.bestSlip), findsWidgets);
    expect(find.textContaining('3 meccs · 1 élő · 3 tipp 50% felett'), findsOneWidget);
    expect(find.byKey(const Key('stakeFt')), findsOneWidget);
    expect(controller.stake, defaultStrategyStake);
    expect(find.text('Minta meccs'), findsNothing);

    await tester.enterText(find.byKey(const Key('stakeFt')), '10000');
    await tester.pumpAndSettle();
    expect(controller.stake, Rational.fromInt(10000));
    expect(
      controller.board.watchlist.first.profitOn(controller.stake),
      Rational.fromInt(8500),
    );

    await tester.tap(find.text(Copy.watchlist));
    await tester.pumpAndSettle();
    expect(find.text(Copy.notABet), findsOneWidget);
    expect(find.textContaining('Lakers'), findsWidgets);
    expect(find.textContaining(formatHuf(Rational.fromInt(8500))), findsWidgets);
    expect(find.byKey(const Key('sport-all')), findsOneWidget);
    expect(find.byKey(const Key('sport-basketball')), findsOneWidget);
    expect(find.byKey(const Key('sport-soccer')), findsOneWidget);
    expect(find.textContaining('Liverpool'), findsWidgets);

    await tester.tap(find.byKey(const Key('sport-soccer')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Liverpool'), findsWidgets);
    expect(find.textContaining('Lakers'), findsNothing);
    expect(controller.board.watchlist.length, 3);

    await tester.tap(find.byKey(const Key('sport-all')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Lakers'), findsWidgets);
    expect(find.text(Copy.chartTitle), findsNothing);
    expect(find.byKey(const Key('matchChart')), findsNothing);

    await tester.tap(find.textContaining('Lakers'));
    await tester.pumpAndSettle();
    expect(find.text(Copy.chartTitle), findsOneWidget);
    expect(find.byKey(const Key('matchChart')), findsOneWidget);
    expect(find.text(Copy.outcomeHome), findsWidgets);

    await tester.tap(find.text(Copy.navChat));
    await tester.pumpAndSettle();
    expect(find.text(Copy.chatTitle), findsWidgets);
    await tester.enterText(find.byKey(const Key('chatInput')), 'Miért ez a szelvény?');
    await tester.tap(find.text(Copy.chatSend));
    await tester.pumpAndSettle();
    expect(find.text(Copy.chatNeedKey), findsOneWidget);
  });

  testWidgets('splash: logo és töltősáv amíg a meccsek jönnek', (tester) async {
    await initializeDateFormatting('hu');
    final feed = _GateFeed();
    final controller = AppController(feed: feed);
    final loading = controller.load();
    await tester.pumpWidget(TippmixApp(controller: controller));
    await tester.pump();
    expect(find.byKey(const Key('tippmixLogo')), findsOneWidget);
    expect(find.byKey(const Key('loadingBar')), findsOneWidget);
    expect(find.text(Copy.loadingMatches), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    feed.gate.complete();
    await loading;
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('loadingBar')), findsNothing);
    expect(find.text(Copy.bestSlip), findsWidgets);
  });
}

class _GateFeed implements MatchFeed {
  final Completer<void> gate = Completer<void>();

  @override
  Future<List<SportsMatch>> upcoming() async {
    await gate.future;
    return _FakeFeed().upcoming();
  }

  @override
  Future<List<SportsMatch>> live() async => const [];
}
