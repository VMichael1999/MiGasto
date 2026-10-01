import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mi_gasto/data/services/nlp_classifier_service.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';

void main() {
  setUpAll(() {
    NlpClassifierService.configure(
        File('assets/category_rules.json').readAsStringSync());
  });

  group('Clasificador de gastos', () {
    test('alimentación', () {
      expect(NlpClassifierService.classify('Yapeaste S/ 15.50 a Rappi', 'Rappi Peru'),
          Categoria.alimentacion);
      expect(
          NlpClassifierService.classify(
              'Plin: Enviaste S/ 35.00 a Restaurante Rustica', 'Rustica'),
          Categoria.alimentacion);
    });

    test('un servicio pagado con Yape cae en Servicios', () {
      expect(
        NlpClassifierService.classify(
          '¡Yapeaste el servicio! S/ 134.85 BanBif Servicio: Pago de Cuotas Prestamos',
          'BanBif',
        ),
        Categoria.servicios,
      );
    });

    test('compras', () {
      expect(
          NlpClassifierService.classify('Compra Google Pay S/ 120.90 en Metro', 'Metro S.A.'),
          Categoria.compras);
      expect(NlpClassifierService.classify('Yapeaste S/ 18.00 a Tambo', 'Tambo Miraflores'),
          Categoria.compras);
      expect(NlpClassifierService.classify('Compra de medicina en Inkafarma', 'Inkafarma'),
          Categoria.compras);
    });

    test('transporte', () {
      expect(NlpClassifierService.classify('Plin: Pago de S/ 25.00 a Taxi Uber', 'Uber'),
          Categoria.transporte);
      expect(NlpClassifierService.classify('Compra S/ 85.00 en Repsol', 'Grifo Repsol'),
          Categoria.transporte);
    });

    test('servicios y entretenimiento', () {
      expect(NlpClassifierService.classify('Cargo S/ 44.90 Netflix', 'Netflix Peru'),
          Categoria.entretenimiento);
      expect(NlpClassifierService.classify('Pago Enel Luz', 'Enel Distribucion'),
          Categoria.servicios);
    });

    test('no confunde nombres de personas ni lugares parecidos', () {
      expect(NlpClassifierService.classify('Yapeaste S/ 20.00 a Luz María', 'Luz María'),
          Categoria.otros);
      expect(NlpClassifierService.classify('Yapeaste S/ 5.00 a Metropolitano', 'Metropolitano'),
          Categoria.otros);
    });

    test('"Compra por" solo no decide la categoría', () {
      expect(NlpClassifierService.classify('Compra por S/ 30.00', 'Bazar Lucía'),
          Categoria.otros);
    });
  });

  group('Clasificador de ingresos', () {
    test('sueldo, venta y transferencia', () {
      expect(NlpClassifierService.classifyIncome('Abono de sueldo S/ 3,200.00', 'Mi Empresa'),
          Categoria.sueldo);
      expect(NlpClassifierService.classifyIncome('Pago por venta S/ 180.00', 'Ana'),
          Categoria.venta);
      expect(NlpClassifierService.classifyIncome('Juan te yapeó S/ 15.00', 'Juan Pérez'),
          Categoria.transferenciaRecibida);
    });
  });
}
