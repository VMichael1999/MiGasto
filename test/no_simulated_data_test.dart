import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_gasto/core/theme/theme.dart';
import 'package:mi_gasto/core/widgets/register_sheet.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:mi_gasto/presentation/settings/widgets/connected_accounts_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('el menú + solo ofrece lo que existe: gasto e ingreso', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: RegisterSheet(onSelectExpense: () {}, onSelectIncome: () {}),
      ),
    ));

    expect(find.text('Gasto'), findsOneWidget);
    expect(find.text('Ingreso'), findsOneWidget);
    expect(find.text('Transferir entre espacios'), findsNothing);
    expect(find.text('Registro inteligente'), findsNothing);
  });

  testWidgets('pagos detectados: muestra los medios reales y el interruptor se guarda', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(body: ConnectedAccountsSheet()),
      ),
    ));

    expect(find.text('Yape'), findsOneWidget);
    expect(find.text('Plin'), findsOneWidget);
    expect(find.text('Google Wallet'), findsOneWidget);
    // Nada de bancos de ejemplo.
    expect(find.textContaining('BCP'), findsNothing);
    expect(find.textContaining('Interbank'), findsNothing);

    expect(container.read(providersEnabledProvider)['yape'], isTrue);
    await tester.tap(find.text('Yape'));
    await tester.pumpAndSettle();
    expect(container.read(providersEnabledProvider)['yape'], isFalse);
    expect(prefs.getString('migasto_providers_enabled_v2'), contains('"yape":false'));
  });
}
