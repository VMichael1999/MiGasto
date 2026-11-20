import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/movimiento.dart';

/// Clave en preferencias para encender o apagar los datos de ejemplo (solo debug).
const keyDebugMockData = 'migasto_debug_mock_data';

/// Prefijo de los ids de los movimientos de ejemplo.
const debugMockIdPrefix = 'debug-mock-';

bool isDebugMockId(String id) => id.startsWith(debugMockIdPrefix);

/// ¿Hay que mostrar los datos de ejemplo? Solo en compilaciones de desarrollo
/// (`kDebugMode`), nunca en las pruebas automáticas (que parten de cero) y
/// mientras el interruptor de Perfil no los haya apagado.
///
/// En una compilación de producción `kDebugMode` es falso y el compilador quita
/// todo este camino: los datos de ejemplo no llegan al usuario.
bool debugMockEnabled(SharedPreferences prefs, {bool? runningUnderTest}) {
  if (!kDebugMode) return false;
  final underTest = runningUnderTest ?? _isFlutterTest();
  if (underTest) return false;
  return prefs.getBool(keyDebugMockData) ?? true;
}

bool _isFlutterTest() {
  try {
    return Platform.environment.containsKey('FLUTTER_TEST');
  } catch (_) {
    return false;
  }
}

class _Item {
  const _Item(this.merchant, this.amount, this.category, this.source);
  final String merchant;
  final double amount;
  final Categoria category;
  final PaymentSource source;
}

const _thisMonthExpenses = <_Item>[
  _Item('Alquiler departamento', 2200.00, Categoria.servicios, PaymentSource.manual),
  _Item('Cuota tarjeta BBVA', 1450.00, Categoria.otros, PaymentSource.tarjeta),
  _Item('Saga Falabella', 640.00, Categoria.compras, PaymentSource.tarjeta),
  _Item('Wong Supermercados', 486.30, Categoria.alimentacion, PaymentSource.tarjeta),
  _Item('Seguro médico Pacífico', 420.00, Categoria.otros, PaymentSource.tarjeta),
  _Item('Yape a Juan Pérez', 350.00, Categoria.otros, PaymentSource.yape),
  _Item('Tottus', 312.80, Categoria.alimentacion, PaymentSource.tarjeta),
  _Item('Amazon', 289.90, Categoria.compras, PaymentSource.tarjeta),
  _Item('Plin a Carla Ríos', 200.00, Categoria.otros, PaymentSource.plin),
  _Item('Primax gasolina', 180.00, Categoria.transporte, PaymentSource.tarjeta),
  _Item('Luz del Sur', 168.40, Categoria.servicios, PaymentSource.manual),
  _Item('Movistar', 119.00, Categoria.servicios, PaymentSource.tarjeta),
  _Item('Inkafarma', 96.80, Categoria.otros, PaymentSource.tarjeta),
  _Item('Rappi', 94.50, Categoria.alimentacion, PaymentSource.tarjeta),
  _Item('ChatGPT Plus', 78.00, Categoria.servicios, PaymentSource.tarjeta),
  _Item('Claude Pro', 78.00, Categoria.servicios, PaymentSource.tarjeta),
  _Item('Sedapal', 72.10, Categoria.servicios, PaymentSource.manual),
  _Item('Rappi', 67.90, Categoria.alimentacion, PaymentSource.tarjeta),
  _Item('Netflix', 44.90, Categoria.entretenimiento, PaymentSource.tarjeta),
  _Item('Uber', 38.20, Categoria.transporte, PaymentSource.tarjeta),
  _Item('Uber', 38.20, Categoria.transporte, PaymentSource.tarjeta),
  _Item('Uber', 38.20, Categoria.transporte, PaymentSource.tarjeta),
  _Item('Spotify', 19.90, Categoria.entretenimiento, PaymentSource.tarjeta),
  _Item('iCloud', 12.90, Categoria.servicios, PaymentSource.tarjeta),
];

// Meses anteriores: un sueldo y gastos parecidos, para que las gráficas de
// varios meses tengan con qué dibujarse.
const _previousMonthExpenses = <List<_Item>>[
  [
    _Item('Alquiler departamento', 2200.00, Categoria.servicios, PaymentSource.manual),
    _Item('Cuota tarjeta BBVA', 1450.00, Categoria.otros, PaymentSource.tarjeta),
    _Item('Wong Supermercados', 910.40, Categoria.alimentacion, PaymentSource.tarjeta),
    _Item('Servicios del hogar', 380.00, Categoria.servicios, PaymentSource.manual),
    _Item('Salidas y ocio', 1120.00, Categoria.entretenimiento, PaymentSource.tarjeta),
    _Item('Transporte', 310.00, Categoria.transporte, PaymentSource.tarjeta),
  ],
  [
    _Item('Alquiler departamento', 2200.00, Categoria.servicios, PaymentSource.manual),
    _Item('Cuota tarjeta BBVA', 1450.00, Categoria.otros, PaymentSource.tarjeta),
    _Item('Wong Supermercados', 860.00, Categoria.alimentacion, PaymentSource.tarjeta),
    _Item('Servicios del hogar', 402.50, Categoria.servicios, PaymentSource.manual),
    _Item('Compras', 1380.00, Categoria.compras, PaymentSource.tarjeta),
    _Item('Transporte', 285.00, Categoria.transporte, PaymentSource.tarjeta),
  ],
  [
    _Item('Alquiler departamento', 2200.00, Categoria.servicios, PaymentSource.manual),
    _Item('Cuota tarjeta BBVA', 1450.00, Categoria.otros, PaymentSource.tarjeta),
    _Item('Wong Supermercados', 795.60, Categoria.alimentacion, PaymentSource.tarjeta),
    _Item('Servicios del hogar', 355.00, Categoria.servicios, PaymentSource.manual),
    _Item('Viaje fin de semana', 940.00, Categoria.entretenimiento, PaymentSource.tarjeta),
    _Item('Transporte', 262.00, Categoria.transporte, PaymentSource.tarjeta),
  ],
];

CanalMovimiento _canalFor(PaymentSource s) {
  switch (s) {
    case PaymentSource.yape:
    case PaymentSource.plin:
      return CanalMovimiento.notificacion;
    case PaymentSource.tarjeta:
      return CanalMovimiento.wallet;
    default:
      return CanalMovimiento.manual;
  }
}

/// Movimientos de ejemplo para ver la app con datos **solo en compilaciones de
/// desarrollo** (la app los pide únicamente si `kDebugMode` es verdadero).
///
/// El mes en curso trae un sueldo de S/ 15,000 y unos S/ 7,500 en gastos
/// (suscripciones, transferencias, supermercado, servicios…). Todos quedan en
/// el pasado respecto de [now] para que cuenten como confirmados de hoy hacia
/// atrás. No se guardan en la base de datos.
List<Movimiento> buildDebugMockMovements(DateTime now) {
  final out = <Movimiento>[];
  var n = 0;
  Movimiento make(_Item i, DateTime at, {bool ingreso = false}) => Movimiento(
        id: '$debugMockIdPrefix${n++}',
        amount: i.amount,
        merchant: i.merchant,
        category: i.category,
        source: i.source,
        date: at,
        tipo: ingreso ? TipoMovimiento.ingreso : TipoMovimiento.gasto,
        canal: _canalFor(i.source),
        estado: EstadoMovimiento.confirmado,
        tarjeta: i.source == PaymentSource.tarjeta ? 'Visa BBVA ···4821' : null,
      );

  // Mes en curso: el sueldo al inicio y los gastos repartidos hasta hoy.
  final monthStart = DateTime(now.year, now.month, 1);
  final latest = now.subtract(const Duration(minutes: 1));
  final span = latest.difference(monthStart);
  DateTime at(double fraction) => monthStart.add(span * fraction);

  out.add(make(
    const _Item('Sueldo', 15000.00, Categoria.sueldo, PaymentSource.otro),
    at(0.02),
    ingreso: true,
  ));
  for (var i = 0; i < _thisMonthExpenses.length; i++) {
    out.add(make(_thisMonthExpenses[i], at(0.05 + 0.94 * (i / (_thisMonthExpenses.length - 1)))));
  }

  // Tres meses anteriores.
  for (var back = 1; back <= _previousMonthExpenses.length; back++) {
    final start = DateTime(now.year, now.month - back, 1);
    final end = DateTime(now.year, now.month - back + 1, 0, 20);
    final items = _previousMonthExpenses[back - 1];
    final pspan = end.difference(start);
    out.add(make(
      const _Item('Sueldo', 15000.00, Categoria.sueldo, PaymentSource.otro),
      start.add(pspan * 0.03),
      ingreso: true,
    ));
    for (var i = 0; i < items.length; i++) {
      out.add(make(items[i], start.add(pspan * (0.08 + 0.85 * (i / (items.length - 1))))));
    }
  }
  return out;
}
