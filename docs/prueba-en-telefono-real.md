# Prueba en un teléfono real (Android)

Lo que el emulador no puede comprobar: notificaciones de verdad de Yape y los bancos, Android 15
ocultando avisos, la batería y el «inicio automático» de cada marca. Cada caso dice qué hacer y qué
debería pasar. Anota el modelo del teléfono, la versión de Android (Ajustes > Acerca del teléfono) y
qué casos fallaron.

Antes de empezar, en MiGasto:

1. Ajustes > **Modo captura**: encendido. Así queda el texto exacto de cada aviso, con lo que entendió
   el lector, y se puede compartir con «Compartir textos guardados» si algo falla.
2. Ajustes > **Lectura de notificaciones**, **Lectura de pantalla**, **Avisos de pagos**, **Ventana
   flotante** y **Batería sin restricciones**: todo en «Activo».
3. Si aparece **Inicio automático** (Xiaomi, Huawei, Oppo, Vivo), ábrelo y permite MiGasto.

## 1. Instalación y permisos

| # | Qué hacer | Qué debería pasar |
|---|---|---|
| 1.1 | Instala el APK desde un archivo y toca «Lectura de pantalla». | Primero sale el aviso «MiGasto leerá la pantalla de tus apps de pago»; con «Ahora no» no pasa nada. |
| 1.2 | Toca «Aceptar y activar» y trata de encender MiGasto en Accesibilidad. | En Android 13 o más, si dice «Ajuste restringido»: la fila **Permitir ajustes restringidos** de Ajustes abre la ficha; ahí ⋮ > «Permitir ajustes restringidos» y se puede activar. |
| 1.3 | Repite con «Lectura de notificaciones». | Igual que 1.2. |

## 2. Pagos de Yape

| # | Qué hacer | Qué debería pasar |
|---|---|---|
| 2.1 | Con el teléfono desbloqueado y otra app abierta, pide que te yapeen S/ 1. | Sale la ventana flotante «Ingreso · S/ 1.00 · de …» y no se cierra sola. |
| 2.2 | Toca «Guardar ingreso». | Queda en Movimientos como confirmado, a la hora en que llegó. |
| 2.3 | Con el teléfono **bloqueado**, pide otro yape de S/ 1. | Notificación «Ingreso por confirmar» con Guardar e Ignorar; en la app queda en «Por confirmar». |
| 2.4 | Yapea S/ 1 a alguien y quédate en la constancia. | Ventana flotante «Gasto · S/ 1.00 · a …» (necesita «Lectura de pantalla»). |
| 2.5 | Al rato, abre esa misma constancia desde el historial de Yape. | No se registra otra vez. Una constancia de hace más de 15 minutos tampoco. |
| 2.6 | Pide dos yapes **del mismo monto** seguidos. | Se registran los dos. |
| 2.7 | Yapea S/ 1 a tu propio nombre (por ejemplo, a tu otra cuenta), con tu nombre completo en Perfil. | Queda «Entre mis cuentas» y no suma a gastos ni ingresos. |

## 3. Android 15 o más: avisos ocultos

Android puede ocultar a MiGasto los avisos que parecen traer un código (el yape recibido trae «cód. de
seguridad»). Este caso dice si pasa en tu teléfono.

| # | Qué hacer | Qué debería pasar |
|---|---|---|
| 3.1 | Con «Lectura de pantalla» **apagada** y el teléfono desbloqueado, pide un yape. | Si Android lo oculta: notificación «Android ocultó un aviso de Yape» y aviso en Resumen; el Modo captura anota «oculto por Android». Si no lo oculta, se registra normal. **Anota cuál de las dos pasó.** |
| 3.2 | Con «Lectura de pantalla» **encendida** y el teléfono desbloqueado, repite. | Se registra normal aunque Android lo oculte. |
| 3.3 | Con «Lectura de pantalla» encendida y el teléfono **bloqueado**, repite. | Si Android lo oculta, sale «Android ocultó un aviso de Yape» (con el teléfono bloqueado ni la Accesibilidad lo recibe). |

## 4. Bancos, tarjeta y dólares

| # | Qué hacer | Qué debería pasar |
|---|---|---|
| 4.1 | Plin desde tu banco (enviar y recibir). | Gasto o ingreso con la fuente Plin. |
| 4.2 | Una compra con tarjeta de débito o crédito que te avise el banco. | Gasto con fuente Tarjeta y el comercio. |
| 4.3 | Una compra en dólares (Netflix, Steam, Amazon). | Notificación «Gasto en dólares por confirmar: US$ …»; en la app, en soles al tipo de cambio del día y con el monto en dólares en el detalle. |
| 4.4 | Si te llega un aviso de compra rechazada, un código para confirmar una compra o un recordatorio de pago. | No se registra nada. |
| 4.5 | Transferencias, abonos de sueldo y constancias de tu banco. | Hoy todavía no se leen (falta escribir sus reglas): comparte los textos del Modo captura. |

## 5. Segundo plano

| # | Qué hacer | Qué debería pasar |
|---|---|---|
| 5.1 | Cierra MiGasto desde las apps recientes, espera 1 hora y pide un yape. | Se registra igual. |
| 5.2 | Reinicia el teléfono, no abras MiGasto y pide un yape. | Se registra igual. |
| 5.3 | Activa el ahorro de batería, espera 30 minutos y pide un yape. | Se registra; si el sistema había soltado el lector, al reconectarse lo recupera como «Por confirmar». |

## Qué enviar

- El modelo del teléfono y la versión de Android.
- Los números de los casos que fallaron y qué pasó.
- El archivo de **Compartir textos guardados** (Ajustes > Modo captura). Trae los textos de los avisos:
  revísalo antes de enviarlo, puede tener nombres y montos.
