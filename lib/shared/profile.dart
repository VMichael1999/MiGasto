/// Iniciales del nombre del usuario ("Michael Dev" -> "MD"). Vacío si aún no
/// hay nombre guardado: quien lo muestre debe usar un ícono de respaldo.
String initialsOf(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  return words.take(2).map((w) => w[0].toUpperCase()).join();
}
