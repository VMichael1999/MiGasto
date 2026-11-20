import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mi_gasto/core/widgets/mg_tab_bar.dart';

import 'support/app_harness.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('es', null);
  });

  testWidgets('con el teclado abierto la barra de navegación se oculta y vuelve al cerrarlo', (tester) async {
    await withHome(tester, () async {
      bool tabBarIgnored() {
        final f = find.ancestor(of: find.byType(MgTabBar), matching: find.byType(IgnorePointer)).first;
        return tester.widget<IgnorePointer>(f).ignoring;
      }

      expect(tabBarIgnored(), isFalse);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pump(const Duration(milliseconds: 400));
      expect(tabBarIgnored(), isTrue);

      tester.view.resetViewInsets();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tabBarIgnored(), isFalse);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 6));
    });
  });
}
