import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_gasto/core/widgets/money_text.dart';

void main() {
  Future<String> render(WidgetTester tester, MoneyText w) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: w)));
    final rich = tester.widget<RichText>(find.byType(RichText).first);
    return rich.text.toPlainText();
  }

  testWidgets('un balance negativo conserva el signo aunque showSign sea falso', (tester) async {
    final text = await render(tester, const MoneyText(amount: -25.5, showSign: false));
    expect(text, contains('−'));
    expect(text, contains('25.50'));
  });

  testWidgets('un monto positivo sin signos no lleva ninguno', (tester) async {
    final text = await render(tester, const MoneyText(amount: 25.5, showSign: false));
    expect(text, isNot(contains('−')));
    expect(text, isNot(contains('+')));
    expect(text, contains('25.50'));
  });

  testWidgets('los montos usan punto decimal y coma de miles', (tester) async {
    final text = await render(tester, const MoneyText(amount: 1234.5, showSign: false));
    expect(text, contains('1,234.50'));
  });
}
