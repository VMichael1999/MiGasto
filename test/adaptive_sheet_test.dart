import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mi_gasto/core/theme/theme.dart';
import 'package:mi_gasto/core/widgets/adaptive_sheet.dart';
import 'package:mi_gasto/core/widgets/confirm_sheet.dart';
import 'package:mi_gasto/core/widgets/register_sheet.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> host(WidgetTester tester, Size size, VoidCallback Function(BuildContext) onOpen) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(onPressed: onOpen(context), child: const Text('abrir')),
          ),
        ),
      ),
    ));
  }

  const landscape = Size(844, 390);

  // La tarjeta de la hoja: el primer Material dentro del contenedor horizontal.
  final _card = find.descendant(of: find.byType(LandscapeSheet), matching: find.byType(Material)).first;

  testWidgets('horizontal: la hoja es un panel pegado a la derecha, de todo el alto', (tester) async {
    await host(tester, landscape, (context) => () {
          showAdaptiveSheet<void>(
            context: context,
            builder: (_) => const Padding(padding: EdgeInsets.all(20), child: Text('contenido del panel')),
          );
        });
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    final rect = tester.getRect(_card);
    expect(rect.right, 844);
    expect(rect.height, 390);
    expect(rect.width, inInclusiveRange(340, 440));
    expect(find.text('contenido del panel'), findsOneWidget);
  });

  testWidgets('horizontal: deslizar hacia la derecha cierra el panel', (tester) async {
    await host(tester, landscape, (context) => () {
          showAdaptiveSheet<void>(context: context, builder: (_) => const Text('panel'));
        });
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('panel'), findsOneWidget);

    await tester.fling(find.text('panel'), const Offset(300, 0), 1200);
    await tester.pumpAndSettle();
    expect(find.text('panel'), findsNothing);
  });

  testWidgets('horizontal: el menú «+» es compacto, con Gasto e Ingreso lado a lado', (tester) async {
    await host(tester, landscape, (context) => () {
          RegisterSheet.show(context: context, onSelectExpense: () {}, onSelectIncome: () {});
        });
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    final gasto = tester.getRect(find.text('Gasto'));
    final ingreso = tester.getRect(find.text('Ingreso'));
    expect((gasto.center.dy - ingreso.center.dy).abs(), lessThan(6)); // misma fila
    expect(ingreso.left, greaterThan(gasto.right));
    final card = tester.getRect(_card);
    expect(card.height, lessThan(140)); // compacto (con la tipografía de prueba, más ancha, el subtítulo baja a 2 líneas)
    expect(card.bottom, lessThan(390));
  });

  testWidgets('horizontal: la confirmación es un diálogo centrado', (tester) async {
    await host(tester, landscape, (context) => () {
          ConfirmSheet.show(context, title: '¿Eliminar?', message: 'No se puede deshacer.');
        });
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    final card = tester.getRect(_card);
    expect(card.width, lessThanOrEqualTo(400));
    expect((card.center.dx - 422).abs(), lessThan(2));
    expect(find.text('¿Eliminar?'), findsOneWidget);
  });

  testWidgets('vertical: sigue siendo la hoja inferior de siempre', (tester) async {
    await host(tester, const Size(420, 900), (context) => () {
          showAdaptiveSheet<void>(context: context, builder: (_) => const SizedBox(height: 120, child: Text('hoja')));
        });
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.text('hoja'));
    expect(rect.bottom, greaterThan(700)); // abajo, no a un costado
    expect(rect.width, lessThan(421));
  });
}
