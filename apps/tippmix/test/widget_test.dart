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

    expect(find.text(Copy.homeTitle), findsOneWidget);
    expect(find.text(Copy.bestSlip), findsOneWidget);
    expect(find.textContaining('2 meccs · 1 élő · 2 tipp 50% felett'), findsOneWidget);
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

    await tester.drag(find.byKey(const Key('boardList')), const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(find.text(Copy.watchlist), findsOneWidget);
    expect(find.text(Copy.notABet), findsOneWidget);
    expect(find.textContaining('Lakers'), findsWidgets);
    expect(find.textContaining(formatHuf(Rational.fromInt(8500))), findsWidgets);
  });
}
