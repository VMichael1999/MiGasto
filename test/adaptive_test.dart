import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mi_gasto/core/layout/adaptive.dart';
import 'package:mi_gasto/core/widgets/mg_tab_bar.dart';

import 'support/app_harness.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('es', null);
  });

  test('un teléfono girado es horizontal; un iPad o un teléfono vertical, no', () {
    expect(isLandscapePhoneSize(const Size(844, 390)), isTrue); // iPhone 14/15
    expect(isLandscapePhoneSize(const Size(932, 430)), isTrue); // iPhone Pro Max
    expect(isLandscapePhoneSize(const Size(390, 844)), isFalse);
    expect(isLandscapePhoneSize(const Size(1024, 768)), isFalse); // iPad girado
    expect(isLandscapePhoneSize(const Size(768, 1024)), isFalse);
  });

  // Un solo recorrido: varias pruebas de la app completa en un archivo se pisan.
  testWidgets('en horizontal la barra es baja, centrada y dentro de la pantalla', (tester) async {
    await withHome(
      tester,
      () async {
        final barFinder = find.byType(MgTabBar);
        final bar = tester.widget<MgTabBar>(barFinder);
        expect(bar.compact, isTrue);

        final rect = tester.getRect(barFinder);
        expect(rect.width, lessThanOrEqualTo(landscapeTabBarMaxWidth));
        expect(rect.bottom, lessThanOrEqualTo(390));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(844));
        // Baja: en vertical mide 62 + 32 de relleno; aquí 46 + 16.
        expect(rect.height, lessThanOrEqualTo(62));
      },
      size: const Size(844, 390),
    );
  });
}
