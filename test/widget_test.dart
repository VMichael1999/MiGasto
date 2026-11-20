import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/app_harness.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('es', null);
  });

  testWidgets('App loads dashboard correctly', (WidgetTester tester) async {
    await withHome(tester, () async {
      // Inicio sin datos: no hay cifras inventadas (antes salía S/ 1,120 de "saldo anterior").
      expect(find.text('Balance disponible'), findsOneWidget);
      expect(find.text('Seguro para gastar'), findsOneWidget);
      expect(find.text('Define tu presupuesto en Ajustes para verlo ›'), findsOneWidget);
      expect(find.textContaining('1,120'), findsNothing);
      expect(find.textContaining('3,000'), findsNothing);
    });
  });
}
