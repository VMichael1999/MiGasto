import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_gasto/core/widgets/category_icon.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';
import 'package:mi_gasto/presentation/providers.dart';
import 'package:mi_gasto/shared/merchant_domains.dart';
import 'package:mi_gasto/shared/widgets/merchant_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('reconoce comercios conocidos aunque el nombre venga distinto', () {
    expect(merchantDomain('Spotify'), 'spotify.com');
    expect(merchantDomain('UBER *TRIP 123'), 'uber.com');
    expect(merchantDomain('Uber Eats'), 'ubereats.com');
    expect(merchantDomain('iCloud'), 'icloud.com');
    expect(merchantDomain('RAPPI Prime'), 'rappi.com');
    expect(merchantDomain('  Netflix.com  '), 'netflix.com');
    expect(merchantDomain('Plaza Vea San Miguel'), 'plazavea.com.pe');
    expect(merchantDomain('Claro Móvil'), 'claro.com.pe');
  });

  test('no inventa logos: comercios desconocidos o palabras parecidas no coinciden', () {
    expect(merchantDomain('Bodega de la esquina'), isNull);
    expect(merchantDomain('Metropolitano'), isNull);
    expect(merchantDomain('Maximo Fresh'), isNull);
    expect(merchantDomain(''), isNull);
    expect(merchantDomain('   '), isNull);
  });

  Future<void> pumpIcon(WidgetTester tester, String merchant, {bool? logos}) async {
    SharedPreferences.setMockInitialValues({if (logos != null) merchantLogosKey: logos});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        home: Scaffold(
          body: MerchantIcon(merchant: merchant, category: Categoria.entretenimiento),
        ),
      ),
    ));
  }

  testWidgets('con los logos apagados (o en pruebas) se ve el ícono de la categoría', (tester) async {
    await pumpIcon(tester, 'Spotify');
    expect(find.byType(CategoryIcon), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('un comercio desconocido usa el ícono de la categoría aunque los logos estén activos',
      (tester) async {
    await pumpIcon(tester, 'Bodega de la esquina', logos: true);
    expect(find.byType(CategoryIcon), findsOneWidget);
  });

  Future<void> pumpMovement(WidgetTester tester, Categoria category, PaymentSource source) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        home: Scaffold(
          body: MerchantIcon(merchant: 'Ana Pérez', category: category, source: source),
        ),
      ),
    ));
  }

  String? assetShown(WidgetTester tester) {
    final images = tester.widgetList<Image>(find.byType(Image));
    if (images.isEmpty) return null;
    final provider = images.single.image;
    return provider is AssetImage ? provider.assetName : null;
  }

  testWidgets('una transferencia recibida por Plin o Yape muestra la billetera, no las flechas',
      (tester) async {
    await pumpMovement(tester, Categoria.transferenciaRecibida, PaymentSource.plin);
    expect(assetShown(tester), 'assets/wallets/plin.png');
    expect(find.byType(CategoryIcon), findsNothing);

    await pumpMovement(tester, Categoria.transferenciaRecibida, PaymentSource.yape);
    expect(assetShown(tester), 'assets/wallets/yape.png');
    expect(find.bySemanticsLabel('Yape'), findsOneWidget);
  });

  testWidgets('si el nombre es la billetera («Yape a Juan»), se ve su ícono aunque la categoría tenga uno',
      (tester) async {
    SharedPreferences.setMockInitialValues({merchantLogosKey: true});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MaterialApp(
        home: Scaffold(
          body: MerchantIcon(merchant: 'Yape a Juan Pérez', category: Categoria.alimentacion),
        ),
      ),
    ));
    expect(assetShown(tester), 'assets/wallets/yape.png');
  });

  testWidgets('en «Otros» también se ve la billetera (Lemon)', (tester) async {
    await pumpMovement(tester, Categoria.otros, PaymentSource.lemon);
    expect(assetShown(tester), 'assets/wallets/lemon.png');
  });

  testWidgets('una categoría con ícono propio lo conserva aunque se pague con Yape', (tester) async {
    await pumpMovement(tester, Categoria.alimentacion, PaymentSource.yape);
    expect(find.byType(CategoryIcon), findsOneWidget);
    expect(assetShown(tester), isNull);
  });

  testWidgets('sin billetera (efectivo, tarjeta) quedan las flechas', (tester) async {
    await pumpMovement(tester, Categoria.transferenciaRecibida, PaymentSource.efectivo);
    expect(find.byType(CategoryIcon), findsOneWidget);
  });

  test('el pedido de logo envía solo el dominio', () {
    final url = MerchantIcon.logoUrl('spotify.com');
    expect(Uri.parse(url).queryParameters.keys, containsAll(['domain', 'sz']));
    expect(url, contains('domain=spotify.com'));
    expect(url, isNot(contains('S/')));
  });
}
