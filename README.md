# MiGasto

**MiGasto** registra tus gastos e ingresos en el teléfono. En Android lee las notificaciones de **Yape**, **Plin** y **Google Wallet** (lo que recibes) y la constancia de Yape (lo que envías o pagas) para anotar cada pago por ti; todo lo demás se registra a mano. Pensada para quien paga casi todo con el celular en Perú.

Todo se guarda solo en el teléfono, en una base de datos cifrada: no hay servidor ni cuenta.

## Qué hace

- **Gastos e ingresos.** Los gastos se guardan solos. Los ingresos esperan tu confirmación y, si los ignoras, quedan en "Por confirmar". En Ajustes puedes activar **Guardar ingresos automáticamente** (apagado por defecto).
- **Detección en Android.** Dos fuentes, ambas nativas (Kotlin):
  - **Acceso a notificaciones** (`PaymentNotificationListener`): lo que recibes (por ejemplo, "te envió un pago por S/ 5"). Es la vía principal.
  - **Accesibilidad** (`MyAccessibilityService`): la constancia de Yape cuando envías o pagas ("¡Yapeaste!"), porque Yape no avisa al que paga. Es opcional; se activa en Ajustes > "Pagos que envías".
  Ambas pasan por el mismo lector de reglas y la misma protección contra duplicados.
- **Notificación de cada pago.** Cuando la ventana flotante no se puede ver (pantalla apagada o bloqueada, o sin el permiso «Mostrar sobre otras apps») MiGasto guarda el pago según las reglas de siempre y te avisa con una notificación local (no hay servidor ni *push*): un gasto queda guardado y avisa en silencio («Gasto guardado: S/ 3.00 · a Michael · Yape»); un ingreso que espera confirmación avisa con sonido. En la pantalla bloqueada solo dice «Pago detectado», salvo que actives Ajustes > «Monto en pantalla bloqueada». Con el teléfono en uso y desbloqueado sigue saliendo la ventana flotante, sin duplicar el aviso. Android 13 o más pide el permiso de notificaciones.
- **Avisos de permisos y batería.** Un aviso en Resumen cuando el acceso a notificaciones está apagado (no se ve ningún pago) y otro cuando la batería de la app está restringida (el teléfono puede dormir la lectura; en Samsung se elige «No restringido»). El de batería se puede posponer 7 días. Ajustes tiene su fila de estado y el onboarding un paso. Al abrir la app se le pide al sistema que reconecte el lector de notificaciones si lo soltó.
- **Ventana flotante.** Aparece sobre cualquier app con el monto, el comercio, la fuente y la categoría. El botón **Guardar** es la cuenta regresiva: se vacía de color fuerte a tenue en 4 segundos y guarda al terminar; tocar la ventana la pausa; deslizarla hacia arriba la descarta. Un ingreso espera tu confirmación, salvo que hayas activado el guardado automático.
- **Reglas compartidas.** Qué es un pago y de qué categoría es se define en `assets/reader_rules.json` y `assets/category_rules.json`, que leen Kotlin y Dart. Si un banco cambia su texto, se actualiza el JSON.
- **Sin duplicados.** Mismo monto y fuente dentro de 2 minutos cuenta una sola vez. Además, una notificación ya leída no se vuelve a procesar aunque el sistema la reenvíe al reiniciar el servicio o reinstalar la app.
- **Nombres (alias).** En un movimiento, toca «De» o «Para» para ponerle un nombre corto a esa persona o comercio («Michael» en vez de «MICHAEL ANTHONY VALDIVIEZO MAZA»). Se aplica a todos los movimientos de ese nombre, en Resumen, Movimientos, el detalle, el mapa y la ventana flotante, y la búsqueda encuentra por el nombre nuevo o por el original. El pago guarda siempre el nombre original; el alias solo cambia cómo se ve. Se administran en Ajustes > Nombres guardados y viajan en el respaldo cifrado.
- **Categorías.** Por palabras clave (no es IA) y por lo que cambias a mano ("Aprendidas de tus cambios").
- **Resumen, Movimientos y Reportes.** Saldo del mes, presupuesto de gastos con estado en texto, filtros por tipo, fuente, categoría y monto, e ingresos frente a gastos por mes.
- **Ubicación opcional.** Se pide solo al tocar "Agregar ubicación" y con la app en uso. Muestra la dirección y un mapa de Google Maps; puedes quitarla de un movimiento o borrar todas.
- **iPhone.** Acción de Atajos "Registrar movimiento" para Apple Pay y extensión para compartir capturas de Yape y Plin, con lectura de texto en el teléfono (Vision).
- **Datos cifrados.** SQLite con cifrado (SQLite3MultipleCiphers). La clave se genera en el teléfono y vive en el almacén seguro del sistema (Keychain en iPhone, Keystore en Android).
- **Bloqueo.** Huella, rostro o PIN del teléfono.
- **Claro y oscuro** según el sistema. Tipografía Outfit.
- **Respaldo cifrado.** Ajustes > Respaldo cifrado crea un archivo `.mgb` con tus movimientos (con ubicaciones y texto original), tu presupuesto y las categorías aprendidas, cifrado con **AES-256-GCM** y una clave derivada de tu contraseña con PBKDF2-SHA256 (210 000 vueltas). Lo compartes donde quieras (Drive, correo, tu computadora). MiGasto no guarda la contraseña: si la olvidas, el respaldo no se puede abrir. Ajustes > Restaurar un respaldo lo abre y **agrega lo que falta sin borrar nada** (los movimientos que ya están, por id, no se duplican). Una contraseña equivocada o un archivo alterado se detectan.
- **Exportar a CSV** (sin ubicaciones).

## Lo que todavía no hace

- **iPhone:** Yape y Plin no se detectan solos (iOS no lo permite). Se registran compartiendo la captura de la constancia a MiGasto (el texto se lee en el teléfono) o con el botón +. Los pagos con Apple Pay en el POS se registran con la automatización Transacción de Atajos. Hay un widget y un control del Centro de control que abren el registro (`migasto://new`).
- **Validado con un teléfono real (Samsung, Yape):** pago recibido (notificación) y yape enviado (constancia). **Sin validar:** el pago de servicios con Yape, Google Wallet y Plin dentro de las apps de BBVA, Interbank y Scotiabank; los nombres de paquete de esos bancos son suposiciones y el texto exacto de cada notificación falta confirmarlo (fase 0 del plan).
- **Android:** en algunos teléfonos Samsung el servicio de Accesibilidad no recibe los avisos de notificación; por eso se usa el acceso a notificaciones. Android puede marcar "Configuración restringida" al instalar fuera de Play Store: se permite desde Ajustes > Aplicaciones > MiGasto.
- **Respaldo:** es manual; no hay copia automática ni en la nube. Hay que acordarse de crearlo.
- **Ubicación automática al pagar** con Apple Pay (iPhone) y desde la ventana flotante de Android.

## Tecnologías

Flutter 3.47 (Dart 3.13), Riverpod, GoRouter, Drift (SQLite cifrado), fl_chart, google_maps_flutter, geolocator, geocoding, local_auth, flutter_svg, cryptography (respaldo), share_plus y file_picker. Capa nativa en Kotlin: `PaymentNotificationListener` (notificaciones), `MyAccessibilityService` (pantalla de constancia), `OverlayService` (ventana flotante) y `NativeQueue` (cola que Flutter vacía para guardar en la base de datos).

## Configuración

1. Instala Flutter 3.47 o superior (con `fvm`: `fvm install 3.47.5`).
2. Copia `.env.example` a `.env` y completa tu clave de Google Maps. El `.env` no se sube al repositorio.

   ```bash
   cp .env.example .env
   ```

3. Instala dependencias y corre las pruebas:

   ```bash
   flutter pub get
   flutter test
   ```

4. Ejecuta pasando el `.env` (el mapa solo aparece si la clave está presente):

   ```bash
   flutter run --dart-define-from-file=.env
   ```

La clave también la leen Android (al compilar, desde `.env`) e iOS (por `xcconfig`). En Google Cloud conviene restringirla por app (ID de paquete y bundle ID) y a la API de Maps SDK.

## Permisos en Android

- **Acceso a notificaciones:** para leer los avisos de Yape, Plin y Google Wallet. Solo esas apps (lista en `PaymentNotificationListener`); el resto se ignora.
- **Accesibilidad (opcional):** para leer la constancia de Yape cuando envías o pagas. Solo escucha esas apps (`accessibility_service_config.xml`).
- **Mostrar sobre otras apps (opcional):** para la ventana flotante. Sin ella, los pagos quedan "Por confirmar" en la app.
- **Estado de la batería** (sin permiso extra): solo se consulta si la app está restringida y se abre su ficha de ajustes para que tú lo cambies.
- **Notificaciones (Android 13 o más):** para avisarte de cada pago detectado cuando la ventana flotante no se puede ver.
- **Vibración:** una vibración corta cuando aparece la ventana.
- **Ubicación (solo en uso):** únicamente cuando tocas "Agregar ubicación".

La app explica qué lee y qué no antes de pedir cualquier permiso, y se puede usar solo con registro manual.

## Pruebas

```bash
flutter analyze
flutter test
```

Hay pruebas del cifrado de la base, del lector (gasto o ingreso, montos, textos que no son pagos, y los textos reales de la notificación y la constancia de Yape), categorías, duplicados, migración de datos antiguos, cola nativa, ventana de pago, guardado automático de ingresos, registro manual, ubicación y bloqueo. Las pruebas no cubren el código nativo de Android (se verificó a mano en un teléfono y un emulador).

## Contribuidores

- **Michael Anthony** - [@VMichael1999](https://github.com/VMichael1999)
