import 'package:flutter_test/flutter_test.dart';
import 'package:mi_gasto/data/services/exchange_rate_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  var day = DateTime(2026, 11, 24, 10);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    day = DateTime(2026, 11, 24, 10);
  });

  ExchangeRateService service(Future<double?> Function() fetch) =>
      ExchangeRateService(prefs, fetcher: fetch, clock: () => day);

  test('descarga una vez al día y lo guarda', () async {
    var calls = 0;
    final s = service(() async {
      calls++;
      return 3.762;
    });
    expect(await s.usdToPen(), 3.762);
    expect(await s.usdToPen(), 3.762);
    expect(calls, 1);
    day = day.add(const Duration(days: 1));
    await s.usdToPen();
    expect(calls, 2);
  });

  test('sin internet usa el último conocido; si nunca hubo, null', () async {
    expect(await service(() async => throw Exception('sin red')).usdToPen(), isNull);
    await service(() async => 3.75).usdToPen();
    day = day.add(const Duration(days: 3));
    expect(await service(() async => null).usdToPen(), 3.75);
  });

  test('un valor absurdo de una respuesta rota no se usa', () async {
    expect(await service(() async => 0.0).usdToPen(), isNull);
    expect(await service(() async => 3750).usdToPen(), isNull);
  });

  test('lee el formato de la fuente pública', () {
    expect(ExchangeRateService.parseRate('{"date":"2026-11-24","usd":{"eur":0.86,"pen":3.7621}}'), 3.7621);
    expect(ExchangeRateService.parseRate('<html>error</html>'), isNull);
    expect(ExchangeRateService.parseRate('{"usd":{}}'), isNull);
  });
}
