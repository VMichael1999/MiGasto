# Notas para publicar

Lista de lo que piden las tiendas y qué responder según lo que la app hace hoy. Revísala contra la versión que subas.

## Antes de subir (pendientes que dependen de ti)

- **Identificador de la app.** Hoy es `com.example.mi_gasto` (Android) y `com.example.miGasto` (iPhone). Cámbialo por uno tuyo antes de publicar. Al hacerlo, actualiza también el App Group `group.<tu identificador>` (`ios/Runner/Runner.entitlements` y `SharedQueue.swift`).
- **Firma de Android.** El build de release usa las claves de debug (`android/app/build.gradle.kts`). Crea un keystore y configúralo.
- **Cuenta de Apple Developer** (US$ 99 al año) y una Mac con Xcode. El App Group y la acción de Atajos necesitan una cuenta con firma.
- **Política de privacidad publicada** en una dirección pública: usa `docs/politica-de-privacidad.md`.
- **Clave de Google Maps restringida** por app (ID del paquete y bundle ID) y limitada al SDK de Maps.

## Google Play

**Servicio de accesibilidad (declaración y video).** Play exige un formulario de declaración, un aviso destacado con consentimiento antes de pedirlo y un video que muestre el uso. La app ya muestra el aviso en la primera pantalla ("Qué lee la app y qué no"). Alternativa a evaluar si Play lo rechaza: `NotificationListenerService` (fase 2 del plan), que se confirma en la fase 0 con notificaciones reales.

**Seguridad de los datos (Data safety).**

- ¿Recopila o comparte datos? Los datos se procesan **solo en el dispositivo** y no se envían a ningún servidor propio. Google Maps recibe la zona mostrada para dibujar el mapa.
- Información financiera: movimientos (monto, comercio, fecha). Procesada en el dispositivo, no compartida, cifrada en reposo.
- Ubicación aproximada y precisa: opcional, solo en uso y a petición del usuario; no compartida.
- ¿Se puede pedir que se borren los datos? Sí, desde la app, o desinstalando.

**Permisos declarados:** accesibilidad (lectura de pagos), mostrar sobre otras apps (ventana de confirmación, opcional), ubicación en primer plano (a petición), biometría (bloqueo).

**Páginas de 16 KB.** Con Drift ya no se incluye `libisar.so`. Verifica el APK final con el comprobador de alineación antes de subir.

## App Store

**Etiquetas de privacidad.** Datos recopilados: ninguno enlazado a la identidad ni usado para seguimiento. Información financiera y ubicación se guardan en el dispositivo.

**Ficha.** Di claramente que en iPhone Yape y Plin **no se detectan solos** (iOS no lo permite): se registran con el botón + y, en pagos con Apple Pay en el POS, con la automatización de Atajos.

**Permisos:** ubicación mientras se usa la app (a petición), Face ID, notificaciones (aviso de qué se guardó).

## Prueba cerrada

Probar con 5 a 10 personas (prueba interna de Play y TestFlight). Medir cuántas completan la guía de Apple Pay en iPhone.
