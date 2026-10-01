import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_gasto/shared/widgets/brand_mark.dart';

void main() {
  testWidgets('el logo se dibuja con su etiqueta accesible', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: BrandMark(size: 52)))),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('MiGasto'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
