# MiGasto

**MiGasto** registra tus gastos e ingresos en el teléfono. En Android lee las notificaciones de **Yape**, **Plin** y **Google Wallet** para anotar cada pago por ti y te deja confirmarlo; todo lo demás se registra a mano. Pensada para quien paga casi todo con el celular en Perú.

Todo se guarda solo en el teléfono, en una base de datos cifrada: no hay servidor ni cuenta.

## Qué hace

- **Gastos e ingresos.** Los ingresos nunca se guardan solos: esperan tu confirmación y, si los ignoras, quedan en "Por confirmar".
- **Detección en Android.** Un lector nativo (Kotlin) reconoce el pago, distingue si entra o sale dinero y muestra una ventana flotante. El gasto se guarda a los 4 segundos (puedes pausarla, editarla o descartarla); el ingreso espera tu confirmación.
- **Reglas compartidas.** Qué es un pago y de qué categoría es se define en `assets/reader_rules.json` y `assets/category_rules.json`, que leen Kotlin y Dart. Si un banco cambia su texto, se actualiza el JSON.
- **Sin duplicados.** Mismo monto y fuente dentro de 2 minutos cuenta una sola vez.
- **Categorías.** Por palabras clave (no es IA) y por lo que cambias a mano ("Aprendidas de tus cambios").
- **Resumen, Movimientos y Reportes.** Saldo del mes, presupuesto de gastos con estado en texto, filtros por tipo, fuente, categoría y monto, e ingresos frente a gastos por mes.
- **Ubicación opcional.** Se pide solo al tocar "Agregar ubicación" y con la app en uso. Muestra la dirección y un mapa de Google Maps; puedes quitarla de un movimiento o borrar todas.
- **Datos cifrados.** SQLite con cifrado (SQLite3MultipleCiphers). La clave se genera en el teléfono y vive en el almacén seguro del sistema (Keychain en iPhone, Keystore en Android).
- **Bloqueo.** Huella, rostro o PIN del teléfono.
- **Claro y oscuro** según el sistema. Tipografía Outfit.
- **Exportar a CSV** (sin ubicaciones).

## Lo que todavía no hace

- **iPhone:** la app compila y permite registrar a mano, pero no detecta pagos solos. Faltan la acción de Atajos para Apple Pay, la extensión para compartir capturas de Yape y Plin y el widget (fases 3 y 4 del plan).
- **Plin dentro de las apps de BBVA, Interbank y Scotiabank:** los nombres de paquete que se escuchan están sin validar con teléfonos reales, igual que el texto exacto de cada notificación (fase 0 del plan).
- **Ubicación automática al pagar** con Apple Pay (iPhone) y desde la ventana flotante de Android.

## Tecnologías

Flutter 3.47 (Dart 3.13), Riverpod, GoRouter, Drift (SQLite cifrado), fl_chart, google_maps_flutter, geolocator, geocoding, local_auth, flutter_svg. Capa nativa en Kotlin: `MyAccessibilityService` (lector), `OverlayService` (ventana flotante) y `NativeQueue` (cola que Flutter vacía para guardar en la base de datos).

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

- **Accesibilidad:** para leer las notificaciones y la pantalla de Yape, Plin y Google Wallet. Solo esas apps (`accessibility_service_config.xml`).
- **Mostrar sobre otras apps:** para la ventana flotante de confirmación. Es opcional: sin ella, los pagos quedan "Por confirmar" en la app.
- **Ubicación (solo en uso):** únicamente cuando tocas "Agregar ubicación".

La app explica qué lee y qué no antes de pedir cualquier permiso, y se puede usar solo con registro manual.

## Pruebas

```bash
flutter analyze
flutter test
```

Hay pruebas del cifrado de la base, del lector (gasto o ingreso, montos, textos que no son pagos), categorías, duplicados, migración de datos antiguos, cola nativa, ventana de pago, registro manual, ubicación y bloqueo.

## Contribuidores

- **Michael Anthony** - [@VMichael1999](https://github.com/VMichael1999)
