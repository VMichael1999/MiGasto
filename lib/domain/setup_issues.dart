/// Lo que impide que MiGasto lea los pagos solo.
enum SetupIssue {
  /// El acceso a notificaciones está apagado: no se ve ningún pago.
  lecturaApagada,

  /// Las notificaciones de MiGasto están apagadas: con la pantalla bloqueada no se entera de ningún pago.
  avisosApagados,

  /// La batería de la app está restringida: el teléfono puede dormir la lectura.
  bateriaRestringida,
}

/// Cuánto tiempo se esconde el aviso de batería después de tocar "Ahora no".
const batteryBannerSnooze = Duration(days: 7);

/// Problemas a avisar, el más importante primero. Solo aplica a Android.
List<SetupIssue> computeSetupIssues({
  required bool isAndroid,
  required bool notificationsOn,
  required bool batteryUnrestricted,
  bool alertsOn = true,
  DateTime? alertsDismissedAt,
  DateTime? batteryDismissedAt,
  DateTime? now,
}) {
  if (!isAndroid) return const [];
  final issues = <SetupIssue>[];
  final clock = now ?? DateTime.now();
  bool snoozed(DateTime? at) => at != null && clock.difference(at) < batteryBannerSnooze;

  if (!notificationsOn) issues.add(SetupIssue.lecturaApagada);
  // Sin permiso de leer, avisar de las notificaciones propias no tiene sentido todavía.
  if (notificationsOn && !alertsOn && !snoozed(alertsDismissedAt)) {
    issues.add(SetupIssue.avisosApagados);
  }
  if (!batteryUnrestricted && !snoozed(batteryDismissedAt)) issues.add(SetupIssue.bateriaRestringida);
  return issues;
}
