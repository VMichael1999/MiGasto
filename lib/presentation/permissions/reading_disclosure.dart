import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/confirm_sheet.dart';
import '../providers.dart';

/// Qué lectura automática se va a activar.
enum ReadingKind {
  /// Acceso a notificaciones (`PaymentNotificationListener`).
  notificaciones,

  /// Accesibilidad (`MyAccessibilityService`): «Lectura de pantalla».
  pantalla,
}

/// Se guardó que el usuario aceptó el aviso de esa lectura.
String consentKey(ReadingKind kind) => 'migasto_consent_${kind.name}';

/// Texto del aviso destacado que pide Google Play antes de activar cada lectura: qué se
/// lee, para qué y que no sale del teléfono. Tiene que verse en la app, no basta con la
/// descripción del servicio ni la política de privacidad.
String disclosureTitle(ReadingKind kind) => switch (kind) {
      ReadingKind.notificaciones => 'MiGasto leerá tus avisos de pago',
      ReadingKind.pantalla => 'MiGasto leerá la pantalla de tus apps de pago',
    };

String disclosureMessage(ReadingKind kind) => switch (kind) {
      ReadingKind.notificaciones =>
        'Para registrar tus gastos e ingresos sin escribirlos, MiGasto lee las notificaciones de '
            'Yape, Google Wallet y las apps de tu banco o billetera: el monto, a quién o de quién, '
            'y si el dinero entra o sale.\n\n'
            'No lee tus mensajes, fotos, contactos ni otras apps. Lo leído se guarda solo en este '
            'teléfono y no se envía a ningún servidor. Puedes apagarlo cuando quieras en los '
            'ajustes del teléfono.',
      ReadingKind.pantalla =>
        'MiGasto usará el servicio de Accesibilidad de Android para leer la pantalla de la '
            'constancia cuando pagas con Yape (Yape no avisa al que paga) y los avisos de tus apps '
            'de pago que Android oculta a las demás apps. Solo mira Yape, Google Wallet y las apps '
            'de tu banco o billetera, y solo toma el monto, el nombre, la fecha y el número de '
            'operación.\n\n'
            'No es una herramienta de accesibilidad: no toca ni cambia nada en tu teléfono, no lee '
            'otras apps, y lo leído se guarda solo en este teléfono, sin enviarse a ningún servidor. '
            'Puedes apagarlo cuando quieras en Ajustes > Accesibilidad.',
    };

/// Muestra el aviso (la primera vez) y, si el usuario acepta, abre los ajustes del sistema
/// para activar esa lectura. Devuelve si se abrieron.
Future<bool> openReadingWithDisclosure(BuildContext context, WidgetRef ref, ReadingKind kind) async {
  final prefs = ref.read(sharedPreferencesProvider);
  final permissions = ref.read(permissionsCheckerProvider);
  if (prefs.getBool(consentKey(kind)) != true) {
    final accepted = await ConfirmSheet.show(
      context,
      title: disclosureTitle(kind),
      message: disclosureMessage(kind),
      confirmLabel: 'Aceptar y activar',
      cancelLabel: 'Ahora no',
      isDestructive: false,
      icon: kind == ReadingKind.pantalla ? Icons.touch_app_outlined : Icons.notifications_active_outlined,
    );
    if (!accepted) return false;
    await prefs.setBool(consentKey(kind), true);
  }
  switch (kind) {
    case ReadingKind.notificaciones:
      await permissions.openNotificationListenerSettings();
    case ReadingKind.pantalla:
      await permissions.openAccessibilitySettings();
  }
  return true;
}
