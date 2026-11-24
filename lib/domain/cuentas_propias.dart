/// Reconoce si el nombre de un pago es el del propio usuario: un yape o un plin que se manda
/// a sí mismo es una transferencia entre sus cuentas, no un gasto ni un ingreso.
///
/// Los bancos y billeteras escriben el nombre completo o recortado («MICHAEL ANTHONY
/// VALDIVIEZO MAZA», «Michael Valdiviezo M*»), y el perfil puede tener menos palabras. Se pide
/// que coincidan el primer nombre del pago y al menos otra palabra completa: con un perfil de
/// una sola palabra («Michael») no se adivina nada.
bool esMismoTitular(String nombreDelPago, String miNombre) {
  final mio = _palabras(miNombre).toSet();
  if (mio.length < 2) return false;
  final delPago = _palabras(nombreDelPago);
  if (delPago.length < 2 || !mio.contains(delPago.first)) return false;
  final iguales = delPago.where((p) => p.length >= 3 && mio.contains(p)).toSet();
  return iguales.length >= 2;
}

/// Palabras en minúsculas, sin tildes ni asteriscos («M*» -> «m»).
List<String> _palabras(String texto) {
  const tildes = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n'};
  final limpio = texto.toLowerCase().split('').map((c) => tildes[c] ?? c).join();
  return limpio
      .split(RegExp(r'[^a-z]+'))
      .where((p) => p.isNotEmpty)
      .toList();
}
