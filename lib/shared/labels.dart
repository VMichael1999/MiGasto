import '../domain/entities/movimiento.dart';

/// Nombre visible de cada fuente de pago.
String sourceLabel(PaymentSource source) {
  switch (source) {
    case PaymentSource.yape:
      return 'Yape';
    case PaymentSource.plin:
      return 'Plin';
    case PaymentSource.googlePay:
      return 'Google Wallet';
    case PaymentSource.tarjeta:
      return 'Tarjeta';
    case PaymentSource.efectivo:
      return 'Efectivo';
    case PaymentSource.manual:
    case PaymentSource.otro:
      return 'Manual';
  }
}

/// Nombre visible de cada categoría.
String categoryLabel(Categoria category) {
  switch (category) {
    case Categoria.alimentacion:
      return 'Alimentación';
    case Categoria.transporte:
      return 'Transporte';
    case Categoria.compras:
      return 'Compras';
    case Categoria.servicios:
      return 'Servicios';
    case Categoria.entretenimiento:
      return 'Entretenimiento';
    case Categoria.otros:
    case Categoria.otrosIngresos:
      return 'Otros';
    case Categoria.sueldo:
      return 'Sueldo';
    case Categoria.transferenciaRecibida:
      return 'Transferencia recibida';
    case Categoria.venta:
      return 'Venta';
  }
}
