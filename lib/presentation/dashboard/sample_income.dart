/// TEMPORAL: datos de ejemplo de ingresos para el Resumen del rediseño.
///
/// El modelo actual (`Movimiento`) solo guarda gastos. Cuando exista `Movimiento`
/// con tipo ingreso/gasto y estado pendiente (fase 1 del plan), este archivo se
/// elimina y el Resumen lee los ingresos reales.
class SampleIncome {
  const SampleIncome._();

  /// Ingresos confirmados del mes.
  static const double confirmedTotal = 3465.00;

  /// Ingreso detectado que espera confirmación del usuario.
  static const double pendingAmount = 15.00;
  static const int pendingCount = 1;
  static const String pendingPeer = 'Juan Pérez';
  static const String pendingSource = 'yape';
  static const String pendingSourceLabel = 'Yape';
  static const String pendingTime = '11:10';
}
