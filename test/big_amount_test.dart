import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_gasto/core/theme/theme.dart';
import 'package:mi_gasto/shared/widgets/big_amount.dart';

Widget _wrap(Widget child) =>
    MaterialApp(theme: AppTheme.lightTheme, home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('oculto no muestra el monto', (tester) async {
    await tester.pumpWidget(_wrap(const BigAmount(1234.5, hidden: true)));
    expect(find.textContaining('••••', findRichText: true), findsOneWidget);
    expect(find.textContaining('1,234.50', findRichText: true), findsNothing);
  });

  testWidgets('al mostrarlo la cuenta sube desde 0 hasta el monto', (tester) async {
    await tester.pumpWidget(_wrap(const BigAmount(200, countUpFromZero: true)));
    expect(find.textContaining('0.00', findRichText: true), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    final mid = tester.widget<RichText>(find.byType(RichText).first).text.toPlainText();
    expect(mid, isNot(contains('200.00')));
    expect(mid, isNot(contains('S/ 0.00')));
    await tester.pumpAndSettle();
    expect(find.textContaining('200.00', findRichText: true), findsOneWidget);
  });

  testWidgets('sin animación muestra el monto directo', (tester) async {
    await tester.pumpWidget(_wrap(const BigAmount(75.25)));
    expect(find.textContaining('75.25', findRichText: true), findsOneWidget);
  });
}
