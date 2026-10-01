// Nombres que el usuario le pone a una persona o comercio ("Michael" en vez de
// "MICHAEL ANTHONY VALDIVIEZO MAZA"). El movimiento conserva el nombre original:
// el alias solo cambia cómo se ve.

// Clave con la que se busca el alias: sin mayúsculas ni espacios de más.
String aliasKey(String name) => name.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

// El alias si lo hay; si no, el nombre original.
String displayName(String merchant, Map<String, String> aliases) {
  final alias = aliases[aliasKey(merchant)]?.trim();
  return (alias == null || alias.isEmpty) ? merchant : alias;
}
