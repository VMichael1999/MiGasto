# Notas para publicar

Lista de lo que piden las tiendas y qué responder según lo que la app hace hoy. Revísala contra la versión que subas.

## Antes de subir (pendientes que dependen de ti)

- **Identificador de la app.** Hoy es `com.example.mi_gasto` (Android) y `com.example.miGasto` (iPhone). Cámbialo por uno tuyo antes de publicar. Al hacerlo, actualiza también el App Group `group.<tu identificador>` (`ios/Runner/Runner.entitlements` y `SharedQueue.swift`).
- **Firma de Android.** El build de release usa las claves de debug (`android/app/build.gradle.kts`). Crea un keystore y configúralo.
- **Cuenta de Apple Developer** (US$ 99 al año) y una Mac con Xcode. El App Group y la acción de Atajos necesitan una cuenta con firma.
- **Política de privacidad publicada** en una dirección pública: usa `docs/politica-de-privacidad.md`.
- **Clave de Google Maps restringida** por app (ID del paquete y bundle ID) y limitada al SDK de Maps.

## Google Play

**Acceso a notificaciones y servicio de accesibilidad (declaración y video).** Play revisa ambos usos. La app lee las notificaciones con `NotificationListenerService` (vía principal, recibidos) y usa Accesibilidad solo para la constancia de Yape al enviar (opcional). Para cada uno hace falta un aviso destacado con consentimiento antes de pedirlo y, para Accesibilidad, el formulario de declaración y un video que muestre el uso. La app ya explica qué lee y qué no en la primera pantalla y en Ajustes. Si Play rechaza Accesibilidad, la app sigue funcionando con las notificaciones y el registro manual; solo se pierde la lectura de lo que envías.

**Seguridad de los datos (Data safety).**

- ¿Recopila o comparte datos? Los datos se procesan **solo en el dispositivo** y no se envían a ningún servidor propio. Google Maps recibe la zona mostrada para dibujar el mapa.
- Información financiera: movimientos (monto, comercio, fecha). Procesada en el dispositivo, no compartida, cifrada en reposo.
- Ubicación aproximada y precisa: opcional, solo en uso y a petición del usuario; no compartida.
- ¿Se puede pedir que se borren los datos? Sí, desde la app, o desinstalando.

**Permisos declarados:** acceso a notificaciones (lectura de pagos recibidos), accesibilidad (constancia de Yape al enviar, opcional), mostrar sobre otras apps (ventana de confirmación, opcional), vibración, ubicación en primer plano (a petición), biometría (bloqueo).

**Páginas de 16 KB.** Con Drift ya no se incluye `libisar.so`. Verifica el APK final con el comprobador de alineación antes de subir.

## App Store

**Etiquetas de privacidad.** Datos recopilados: ninguno enlazado a la identidad ni usado para seguimiento. Información financiera y ubicación se guardan en el dispositivo.

**Ficha.** Di claramente que en iPhone Yape y Plin **no se detectan solos** (iOS no lo permite): se registran con el botón + y, en pagos con Apple Pay en el POS, con la automatización de Atajos.

**Permisos:** ubicación mientras se usa la app (a petición), Face ID, notificaciones (aviso de qué se guardó).

## Prueba cerrada

Probar con 5 a 10 personas (prueba interna de Play y TestFlight). Medir cuántas completan la guía de Apple Pay en iPhone.
