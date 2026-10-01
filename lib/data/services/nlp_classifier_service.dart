import '../../domain/entities/movimiento.dart';

class NlpClassifierService {
  /// Categoría de un ingreso a partir del texto de la notificación.
  static Categoria classifyIncome(String text, String peerName) {
    final combined = '$text $peerName'.toLowerCase();
    if (RegExp(r'\b(sueldo|haberes|planilla|remuneraci[oó]n|pago de n[oó]mina)\b')
        .hasMatch(combined)) {
      return Categoria.sueldo;
    }
    if (RegExp(r'\b(venta|vendiste|cobro)\b').hasMatch(combined)) {
      return Categoria.venta;
    }
    return Categoria.transferenciaRecibida;
  }

  static Categoria classify(String text, String peerName) {
    final combined = '$text $peerName'.toLowerCase();

    // 1. Food keywords -> alimentacion
    if (combined.contains('rappi') ||
        combined.contains('didi food') ||
        combined.contains('pedidosya') ||
        combined.contains('starbucks') ||
        combined.contains('restaurante') ||
        combined.contains('rustica') ||
        combined.contains('pardos') ||
        combined.contains('chifa') ||
        combined.contains('kfc') ||
        combined.contains('burger') ||
        combined.contains('bembos') ||
        combined.contains('polleria') ||
        combined.contains('cafe') ||
        combined.contains('snack') ||
        combined.contains('sandwich')) {
      return Categoria.alimentacion;
    }

    // 2. Transport keywords -> transporte
    if (combined.contains('uber') ||
        combined.contains('cabify') ||
        combined.contains('indrive') ||
        combined.contains('yango') ||
        combined.contains('taxi') ||
        combined.contains('gasolinera') ||
        combined.contains('grifo') ||
        combined.contains('repsol') ||
        combined.contains('primax') ||
        combined.contains('pecsa') ||
        combined.contains('colectivo') ||
        combined.contains('peaje')) {
      return Categoria.transporte;
    }

    // 3. Entertainment keywords -> entretenimiento
    if (combined.contains('netflix') ||
        combined.contains('spotify') ||
        combined.contains('disney') ||
        combined.contains('cineplanet') ||
        combined.contains('cine') ||
        combined.contains('prime video') ||
        combined.contains('hbo') ||
        combined.contains('apple music') ||
        combined.contains('playstation') ||
        combined.contains('steam')) {
      return Categoria.entretenimiento;
    }

    // 4. Services & Bills keywords -> servicios
    if (combined.contains('luz') ||
        combined.contains('agua') ||
        combined.contains('enel') ||
        combined.contains('sedapal') ||
        combined.contains('movistar') ||
        combined.contains('claro') ||
        combined.contains('entel') ||
        combined.contains('google storage') ||
        combined.contains('cloud') ||
        combined.contains('directv') ||
        combined.contains('internet') ||
        combined.contains('recarga')) {
      return Categoria.servicios;
    }

    // 5. Groceries & Shopping keywords -> compras
    if (combined.contains('metro') ||
        combined.contains('tottus') ||
        combined.contains('plaza vea') ||
        combined.contains('wong') ||
        combined.contains('tambo') ||
        combined.contains('oxxo') ||
        combined.contains('mass') ||
        combined.contains('makro') ||
        combined.contains('supermercado') ||
        combined.contains('bodega') ||
        combined.contains('minimarket') ||
        combined.contains('inkafarma') ||
        combined.contains('mifarma') ||
        combined.contains('farmacia') ||
        combined.contains('botic') ||
        combined.contains('ripley') ||
        combined.contains('saga') ||
        combined.contains('falabella') ||
        combined.contains('linio') ||
        combined.contains('mercado libre') ||
        combined.contains('amazon') ||
        combined.contains('h&m') ||
        combined.contains('zara') ||
        combined.contains('mall') ||
        combined.contains('tienda') ||
        combined.contains('regalo') ||
        combined.contains('compra')) {
      return Categoria.compras;
    }

    return Categoria.otros;
  }
}
