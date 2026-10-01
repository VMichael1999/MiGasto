/// Gasto (sale dinero) o ingreso (entra dinero).
enum TipoMovimiento { gasto, ingreso }

/// Los ingresos quedan pendientes hasta que el usuario los confirma.
enum EstadoMovimiento { pendiente, confirmado }

/// Cómo entró el movimiento a la app.
enum CanalMovimiento { notificacion, wallet, captura, manual }

enum Categoria {
  // Gastos
  alimentacion, // Alimentación
  transporte, // Transporte
  compras, // Compras
  servicios, // Servicios (luz, agua, internet)
  entretenimiento, // Entretenimiento (Netflix, cine)
  otros, // Otros
  // Ingresos
  sueldo, // Sueldo
  transferenciaRecibida, // Transferencia recibida
  venta, // Venta
  otrosIngresos; // Otros

  static const List<Categoria> gastos = [
    alimentacion,
    transporte,
    compras,
    servicios,
    entretenimiento,
    otros,
  ];

  static const List<Categoria> ingresos = [
    sueldo,
    transferenciaRecibida,
    venta,
    otrosIngresos,
  ];

  bool get esDeIngreso => ingresos.contains(this);

  /// Categorías que se pueden elegir para un tipo de movimiento.
  static List<Categoria> paraTipo(TipoMovimiento tipo) =>
      tipo == TipoMovimiento.ingreso ? ingresos : gastos;
}

enum PaymentSource {
  yape,
  plin,
  googlePay, // Tarjeta con Google Wallet (Android)
  manual,
  tarjeta, // Tarjeta con Apple Pay u otra
  efectivo,
  otro,
}

class Movimiento {
  final String id;
  final double amount;

  /// Comercio en gastos; persona o empresa en ingresos.
  final String merchant;
  final Categoria category;
  final PaymentSource source;
  final DateTime date;
  final String notes;

  final TipoMovimiento tipo;
  final CanalMovimiento canal;
  final EstadoMovimiento estado;

  /// Nombre de la tarjeta que informa Wallet (opcional).
  final String? tarjeta;

  /// Dónde se hizo el pago (opcionales).
  final double? latitud;
  final double? longitud;
  final double? precision; // en metros
  final String? lugar;

  /// La notificación o el texto leído de la captura.
  final String textoOriginal;

  /// Id de la categoría propia del usuario, si eligió una (ver `CategoriaPropia`).
  /// [category] sigue siendo la de siempre (Otros / Otros ingresos) para los totales.
  final String? categoriaPropia;

  Movimiento({
    required this.id,
    required this.amount,
    required this.merchant,
    required this.category,
    required this.source,
    required this.date,
    this.notes = '',
    this.tipo = TipoMovimiento.gasto,
    this.canal = CanalMovimiento.manual,
    this.estado = EstadoMovimiento.pendiente,
    this.tarjeta,
    this.latitud,
    this.longitud,
    this.precision,
    this.lugar,
    this.textoOriginal = '',
    this.categoriaPropia,
  });

  bool get isConfirmed => estado == EstadoMovimiento.confirmado;
  bool get esIngreso => tipo == TipoMovimiento.ingreso;
  bool get esGasto => tipo == TipoMovimiento.gasto;
  bool get tieneUbicacion => latitud != null && longitud != null;

  Movimiento copyWith({
    String? id,
    double? amount,
    String? merchant,
    Categoria? category,
    PaymentSource? source,
    DateTime? date,
    String? notes,
    TipoMovimiento? tipo,
    CanalMovimiento? canal,
    EstadoMovimiento? estado,
    String? tarjeta,
    double? latitud,
    double? longitud,
    double? precision,
    String? lugar,
    String? textoOriginal,
    bool quitarUbicacion = false,
    String? categoriaPropia,
  }) {
    return Movimiento(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      category: category ?? this.category,
      source: source ?? this.source,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      tipo: tipo ?? this.tipo,
      canal: canal ?? this.canal,
      estado: estado ?? this.estado,
      tarjeta: tarjeta ?? this.tarjeta,
      latitud: quitarUbicacion ? null : (latitud ?? this.latitud),
      longitud: quitarUbicacion ? null : (longitud ?? this.longitud),
      precision: quitarUbicacion ? null : (precision ?? this.precision),
      lugar: quitarUbicacion ? null : (lugar ?? this.lugar),
      textoOriginal: textoOriginal ?? this.textoOriginal,
      // Elegir una categoría de siempre quita la propia; elegir una propia la pone.
      categoriaPropia: categoriaPropia ?? (category != null ? null : this.categoriaPropia),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Movimiento && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Movimiento(id: $id, ${tipo.name}, amount: $amount, merchant: $merchant)';
}

/// Cómo se guarda la categoría de un movimiento en una sola columna de texto:
/// `otros` o, con categoría propia, `otros|<id>`. Una versión anterior de la app
/// ve solo `otros|…`, no la reconoce y la trata como Otros.
String categoriaAlmacenada(Categoria categoria, String? propia) =>
    propia == null ? categoria.name : '${categoria.name}|$propia';

/// Inversa de [categoriaAlmacenada]; si el nombre no se reconoce usa [fallback].
({Categoria categoria, String? propia}) leerCategoriaAlmacenada(String? raw, Categoria fallback) {
  if (raw == null || raw.isEmpty) return (categoria: fallback, propia: null);
  final cut = raw.indexOf('|');
  final name = cut < 0 ? raw : raw.substring(0, cut);
  final propia = cut < 0 || cut == raw.length - 1 ? null : raw.substring(cut + 1);
  for (final c in Categoria.values) {
    if (c.name == name) return (categoria: c, propia: propia);
  }
  return (categoria: fallback, propia: propia);
}
