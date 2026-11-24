# Google Play: Accesibilidad y acceso a notificaciones

Requisitos de Google Play para publicar MiGasto con su servicio de Accesibilidad, y los textos
listos para Play Console. Fuente: [Use of the AccessibilityService API](https://support.google.com/googleplay/android-developer/answer/10964491)
y la política de Datos del usuario (aviso destacado y consentimiento). Revisa la página oficial antes de
enviar: Google la actualiza.

## Qué pide Google y cómo lo cumple la app

| Requisito | En MiGasto |
|---|---|
| Solo las herramientas para personas con discapacidad pueden declarar `isAccessibilityTool`. | MiGasto no lo es: `accessibility_service_config.xml` declara `android:isAccessibilityTool="false"`. |
| Aviso destacado **dentro de la app**, antes de pedir el permiso, con consentimiento explícito. No vale la descripción del servicio ni la política de privacidad. | `lib/presentation/permissions/reading_disclosure.dart`: la primera vez que se toca «Lectura de pantalla» (o «Lectura de notificaciones» fuera de la bienvenida) sale una hoja con qué se lee, para qué y que no sale del teléfono; solo «Aceptar y activar» abre los ajustes. La bienvenida es el aviso de las notificaciones. |
| Declarar el uso en Play Console (formulario de Accesibilidad). | Texto abajo. |
| Mencionar el uso en la ficha de Play. | Texto abajo. |
| No cambiar ajustes, no saltar controles de seguridad, no actuar por el usuario. | El servicio solo lee texto: `canPerformGestures` no está declarado y no hace ninguna acción. |
| Usar APIs más específicas cuando existan. | Lo que se puede, se lee con el acceso a notificaciones (`NotificationListenerService`); la Accesibilidad queda para la constancia de Yape al pagar (Yape no avisa al que paga) y los avisos que Android 15 oculta. |

Además Google suele pedir un **video** que muestre el aviso destacado y el uso de la función.

## Texto para el formulario de Play Console

**Función que usa la API de Accesibilidad:**

> MiGasto registra automáticamente los gastos e ingresos del usuario. Yape, la billetera más usada en
> Perú, no envía ninguna notificación a quien paga: el monto y el destinatario solo aparecen en la
> pantalla de la constancia. El servicio de Accesibilidad lee el texto de esa constancia (monto, nombre,
> fecha y número de operación) y de las notificaciones de las apps de pago, solo en Yape, Google Wallet y
> las apps de bancos y billeteras peruanas listadas en `android:packageNames`. No realiza ninguna acción
> en el teléfono, no lee otras apps y lo leído se guarda solo en el dispositivo, cifrado, sin enviarse a
> ningún servidor. El usuario lo activa voluntariamente después de un aviso dentro de la app y puede
> registrar sus pagos sin él.

**¿Es una herramienta de accesibilidad?** No.

## Texto para la ficha de Google Play

> Lectura automática: con tu permiso, MiGasto usa el servicio de Accesibilidad de Android para leer la
> constancia de Yape cuando pagas (Yape no avisa al que paga) y el acceso a notificaciones para leer los
> avisos de pago de Yape, Plin, Google Wallet y tu banco. Solo toma el monto, el nombre y la fecha;
> todo se queda en tu teléfono.

## Guion del video (30 a 60 s)

1. Abrir MiGasto > Ajustes > «Lectura de pantalla».
2. Mostrar el aviso «MiGasto leerá la pantalla de tus apps de pago» y tocar «Aceptar y activar».
3. Activar MiGasto en Ajustes > Accesibilidad.
4. Yapear S/ 1 y mostrar la ventana flotante con el gasto leído de la constancia.
5. Mostrar el movimiento en MiGasto.

## Fuera de Google Play

Si se distribuye el APK (sin Play), Android 13 o más bloquea la Accesibilidad y el acceso a
notificaciones de las apps instaladas desde un archivo hasta que el usuario toca, en la ficha de la app,
⋮ > «Permitir ajustes restringidos». Ajustes muestra la fila **Permitir ajustes restringidos** en ese
caso.
