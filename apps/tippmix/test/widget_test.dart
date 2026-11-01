import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tippmix_kalkulator/data/local_store.dart';
import 'package:tippmix_kalkulator/data/sample_feed.dart';
import 'package:tippmix_kalkulator/l10n/copy.dart';
import 'package:tippmix_kalkulator/main.dart';
import 'package:tippmix_kalkulator/state/app_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('magyar kezdőképernyő a meccsekkel', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('hu');
    final controller = AppController(
      feed: SampleMatchFeed(now: DateTime(2026, 11, 1, 12)),
      store: LocalStore(),
    );
    await controller.load();
    await tester.pumpWidget(TippmixApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text(Copy.navMatches), findsWidgets);
    expect(find.text(Copy.navLive), findsOneWidget);
    expect(find.text(Copy.navCalculator), findsOneWidget);
    expect(find.text(Copy.navHistory), findsOneWidget);
    expect(find.text('Ferencváros  –  Puskás Akadémia'), findsNothing);
    expect(find.textContaining('Újpest'), findsWidgets);
    expect(find.text('You have pushed the button'), findsNothing);
    expect(find.text('Increment'), findsNothing);
  });
}
