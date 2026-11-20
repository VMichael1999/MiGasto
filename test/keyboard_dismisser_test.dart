import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_gasto/core/widgets/keyboard_dismisser.dart';

void main() {
  Future<FocusNode> pump(WidgetTester tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => KeyboardDismisser(child: child!),
      home: Scaffold(
        body: Column(
          children: [
            TextField(focusNode: node),
            const Expanded(child: SizedBox.expand()),
          ],
        ),
      ),
    ));
    return node;
  }

  testWidgets('tocar un espacio vacío baja el teclado', (tester) async {
    final node = await pump(tester);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(node.hasFocus, isTrue);

    await tester.tapAt(const Offset(400, 400));
    await tester.pump();
    expect(node.hasFocus, isFalse);
  });

  testWidgets('tocar el propio campo no lo cierra', (tester) async {
    final node = await pump(tester);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(node.hasFocus, isTrue);
  });

  testWidgets('con el teclado abierto aparece el botón para ocultarlo', (tester) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    final node = await pump(tester);
    node.requestFocus();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.bySemanticsLabel('Ocultar teclado'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Ocultar teclado'));
    await tester.pump();
    expect(node.hasFocus, isFalse);
  });
}
