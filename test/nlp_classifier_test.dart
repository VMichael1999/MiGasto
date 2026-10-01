import 'package:flutter_test/flutter_test.dart';
import 'package:mi_gasto/data/services/nlp_classifier_service.dart';
import 'package:mi_gasto/domain/entities/movimiento.dart';

void main() {
  group('NLP Classifier Service Tests (Clean Architecture)', () {
    test('Classifies food categories correctly', () {
      expect(
        NlpClassifierService.classify('Yapeaste S/ 15.50 a Rappi', 'Rappi Peru'),
        Categoria.alimentacion,
      );
      expect(
        NlpClassifierService.classify('Plin: Enviaste S/ 35.00 a Restaurante Rustica', 'Rustica'),
        Categoria.alimentacion,
      );
    });

    test('Classifies groceries categories correctly', () {
      expect(
        NlpClassifierService.classify('Compra Google Pay S/ 120.90 en Metro', 'Metro S.A.'),
        Categoria.compras,
      );
      expect(
        NlpClassifierService.classify('Yapeaste S/ 18.00 a Tambo', 'Tambo Miraflores'),
        Categoria.compras,
      );
    });

    test('Classifies transport categories correctly', () {
      expect(
        NlpClassifierService.classify('Plin: Pago de S/ 25.00 a Taxi Uber', 'Uber'),
        Categoria.transporte,
      );
      expect(
        NlpClassifierService.classify('Compra S/ 85.00 en Repsol', 'Grifo Repsol'),
        Categoria.transporte,
      );
    });

    test('Classifies services categories correctly', () {
      expect(
        NlpClassifierService.classify('Cargo S/ 44.90 Netflix', 'Netflix Peru'),
        Categoria.entretenimiento, // Netflix is now entertainment
      );
      expect(
        NlpClassifierService.classify('Pago Enel Luz', 'Enel Distribucion'),
        Categoria.servicios,
      );
    });

    test('Classifies shopping categories correctly', () {
      expect(
        NlpClassifierService.classify('Compra de medicina en Inkafarma', 'Inkafarma'),
        Categoria.compras,
      );
    });
  });
}
