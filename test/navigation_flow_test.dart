import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mi_gasto/core/widgets/mg_tab_bar.dart';
import 'package:mi_gasto/shared/widgets/profile_avatar_button.dart';

import 'support/app_harness.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('es', null);
  });

  // Un solo recorrido: varias pruebas de la app completa en un mismo archivo
  // se pisan entre sí (estado global de la app), así que se encadenan aquí.
  testWidgets('navegación: barra con Buscar, avatar a Perfil y lupa a Buscar', (tester) async {
    await withHome(tester, () async {
      // Barra: Buscar en vez de Perfil.
      final labels = MgTabBar.defaultTabs.map((t) => t.label).toList();
      expect(labels, ['Inicio', 'Plan', 'MiGastoIA', 'Stats', 'Buscar']);
      expect(tester.widget<MgTabBar>(find.byType(MgTabBar)).selectedIndex, 0);

      // El avatar abre el Perfil, sin barra de pestañas, y se puede volver.
      await tester.tap(find.byType(ProfileAvatarButton).first);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Tu perfil'), findsWidgets);
      expect(find.byType(MgTabBar).hitTestable(), findsNothing);

      await tester.tap(find.byIcon(Icons.chevron_left_rounded).first);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Balance disponible'), findsOneWidget);

      // La lupa abre Buscar (no Stats) con el cursor en el buscador.
      await tester.tap(find.byIcon(Icons.search_rounded).first);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.widget<MgTabBar>(find.byType(MgTabBar)).selectedIndex, 4);
      final field = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'Buscar por nombre, categoría o nota',
      );
      expect(field, findsOneWidget);
      expect(tester.widget<TextField>(field).autofocus, isTrue);
    });
  });
}
