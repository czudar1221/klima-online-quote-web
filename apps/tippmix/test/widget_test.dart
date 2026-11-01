import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tippmix_kalkulator/data/match_feed.dart';
import 'package:tippmix_kalkulator/data/models.dart';
import 'package:tippmix_kalkulator/engine/rational.dart';
import 'package:tippmix_kalkulator/l10n/copy.dart';
import 'package:tippmix_kalkulator/main.dart';
import 'package:tippmix_kalkulator/state/app_controller.dart';

class _FakeFeed implements MatchFeed {
  @override
  Future<List<SportsMatch>> upcoming() async => [
    SportsMatch(
      id: 'live-1',
      competition: 'Premier League',
      home: 'Liverpool',
      away: 'Arsenal',
      kickoff: DateTime(2026, 11, 1, 17, 30),
      status: MatchStatus.upcoming,
      homeOdds: Rational.parseDecimal('2,20'),
      drawOdds: Rational.parseDecimal('3,20'),
      awayOdds: Rational.parseDecimal('3,40'),
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

  testWidgets('egy magyar lista: meccs, 1/X/2, tipp, esély', (tester) async {
    await initializeDateFormatting('hu');
    final controller = AppController(feed: _FakeFeed());
    await controller.load();
    await tester.pumpWidget(TippmixApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text(Copy.homeTitle), findsOneWidget);
    expect(find.textContaining('Liverpool'), findsOneWidget);
    expect(find.textContaining('Arsenal'), findsOneWidget);
    expect(find.text(Copy.outcomeHome), findsWidgets);
    expect(find.text(Copy.outcomeDraw), findsWidgets);
    expect(find.text(Copy.outcomeAway), findsWidgets);
    expect(find.textContaining(Copy.tipp), findsWidgets);
    expect(find.text(Copy.eselyFromOdds), findsWidgets);
    expect(find.text('Minta meccs'), findsNothing);
    expect(find.text('You have pushed the button'), findsNothing);
  });
}
