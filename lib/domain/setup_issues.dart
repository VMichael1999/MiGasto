/// Lo que impide que MiGasto lea los pagos solo.
enum SetupIssue {
  /// El acceso a notificaciones está apagado: no se ve ningún pago.
  lecturaApagada,

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
  DateTime? batteryDismissedAt,
  DateTime? now,
}) {
  if (!isAndroid) return const [];
  final issues = <SetupIssue>[];
  if (!notificationsOn) issues.add(SetupIssue.lecturaApagada);
  final snoozed = batteryDismissedAt != null &&
      (now ?? DateTime.now()).difference(batteryDismissedAt) < batteryBannerSnooze;
  if (!batteryUnrestricted && !snoozed) issues.add(SetupIssue.bateriaRestringida);
  return issues;
}
