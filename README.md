# MiGasto 🪙

**MiGasto** es una aplicación móvil desarrollada en Flutter diseñada para automatizar el registro, categorización y control de tus finanzas personales. Pensada especialmente para el mercado peruano, la aplicación detecta transacciones en tiempo real a través de las notificaciones del sistema de servicios como **Yape**, **Plin** y **Google Pay**.

---

## 🚀 Características Principales

*   **Detección Automática**: Lector nativo en Kotlin que utiliza el Servicio de Accesibilidad de Android para procesar notificaciones en tiempo real sin requerir registros manuales.
*   **Categorización Inteligente**: Clasificación automática de comercios mediante un sistema híbrido de reglas predefinidas y preferencias aprendidas (IA de anulación de categorías).
*   **Diseño Premium**: Interfaz moderna de alta calidad con tema oscuro (*Dark Slate* con acentos *Neon Green*).
*   **Seguridad y Privacidad**: Base de datos local encriptada con Isar DB. Los datos de tus transacciones no salen de tu dispositivo.
*   **Presupuesto Dinámico**: Indicador visual del límite mensual establecido con código de colores según el nivel de consumo (Verde, Ámbar, Rojo).
*   **Búsqueda y Filtros Avanzados**: Filtrado preciso por proveedor, categorías y rango de montos.
*   **Herramientas de Depuración**: Simulador integrado de transacciones y de OCR (solo visible en entornos de desarrollo).
*   **Exportación de Datos**: Generación y exportación de historiales completos a formato CSV.

---

## 🛠️ Arquitectura y Tecnologías

El proyecto sigue las mejores prácticas de desarrollo móvil y está estructurado bajo principios de arquitectura limpia:

*   **Framework**: [Flutter](https://flutter.dev) (v3.29.1) & [Dart](https://dart.dev).
*   **Gestión de Estado**: [Flutter Riverpod](https://riverpod.dev) para un manejo reactivo y desacoplado del estado.
*   **Base de Datos**: [Isar Database](https://isar.dev) como motor de almacenamiento NoSQL local de alto rendimiento.
*   **Enrutamiento**: [GoRouter](https://pub.dev/packages/go_router) para la navegación declarativa.
*   **Capa Nativa**: Servicios en Kotlin (`AccessibilityService` y `OverlayService` de Android) para la escucha de notificaciones y renderizado de ventanas emergentes interactivas.

---

## 📦 Instalación y Configuración

### Prerrequisitos

*   Flutter SDK (^3.29.1)
*   Android SDK (API Level 21+)
*   Un dispositivo Android físico o emulador con servicios de Google Play.

### Pasos para iniciar el proyecto

1.  Clona este repositorio:
    ```bash
    git clone https://github.com/VMichael1999/MiGasto.git
    cd MiGasto
    ```

2.  Instala las dependencias de Flutter:
    ```bash
    flutter pub get
    ```

3.  Ejecuta las pruebas unitarias y de widget para verificar que todo esté en orden:
    ```bash
    flutter test
    ```

4.  Compila y ejecuta la aplicación:
    ```bash
    flutter run
    ```

---

## 🔒 Permisos Requeridos (Android)

Para que el registro automático funcione, debes conceder los siguientes permisos dentro de la aplicación:

1.  **Servicio de Accesibilidad**: Requerido por `MyAccessibilityService` para leer el contenido de las notificaciones entrantes de Yape, Plin y Google Pay.
2.  **Mostrar sobre otras aplicaciones (Overlay)**: Requerido por `OverlayService` para mostrar la ventana flotante de confirmación inmediata al detectar un pago.

---

## 👥 Contribuidores

*   **Víctor Michael** - [@VMichael1999](https://github.com/VMichael1999)
