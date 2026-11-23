import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mi_gasto/data/datasource/local_database.dart';
import 'package:mi_gasto/data/repositories/expense_repository_impl.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';

class _NoDatabase implements LocalDatabase {
  @override
  Future<void> init() async {}
  @override
  Future<List<Movimiento>> getExpenses() async => [];
  @override
  Future<void> saveExpense(Movimiento expense) async {}
  @override
  Future<void> deleteExpense(String id) async {}
}

void main() {
  Future<Map<String, bool>> providersWith(Map<String, Object> stored) async {
    SharedPreferences.setMockInitialValues(stored);
    final prefs = await SharedPreferences.getInstance();
    return ExpenseRepositoryImpl(_NoDatabase(), prefs).getProviders();
  }

  test('de entrada se detectan Yape, Plin, Google Wallet y las tarjetas de bancos', () async {
    expect(await providersWith({}), {'yape': true, 'plin': true, 'googlePay': true, 'tarjeta': true});
  });

  test('lo guardado antes de las tarjetas se respeta y las tarjetas van encendidas', () async {
    final providers = await providersWith({
      'migasto_providers_enabled_v2': jsonEncode({'yape': true, 'plin': false, 'googlePay': true}),
    });
    expect(providers['plin'], isFalse);
    expect(providers['tarjeta'], isTrue);
  });
}
