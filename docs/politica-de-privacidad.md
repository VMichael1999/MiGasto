# Política de privacidad de MiGasto

Última actualización: 1 de octubre de 2026 (lectura de notificaciones y de la constancia de Yape)

MiGasto registra tus gastos e ingresos. Esta política explica qué datos usa la app, para qué y dónde quedan. Está escrita para que se entienda; si algo no queda claro, escríbenos al contacto del final.

## Resumen

- Tus datos se guardan **solo en tu teléfono**, en una base de datos cifrada. MiGasto no tiene servidor ni cuentas.
- La app **no envía** tus movimientos a nadie, no usa publicidad y no vende datos.
- La ubicación es **opcional** y solo se toma cuando tú tocas "Agregar ubicación".

## Qué datos usa

| Dato | Para qué | Dónde queda |
| --- | --- | --- |
| Monto, comercio o persona, fuente (Yape, Plin, tarjeta, efectivo), fecha, categoría y notas de cada movimiento | Mostrar tu balance, reportes y presupuesto | En tu teléfono, cifrados |
| Texto de la notificación o de la constancia de pago (solo de Yape, Plin y Google Wallet) | Detectar el monto, el comercio y si el dinero entra o sale; se guarda como "texto original" en el movimiento | En tu teléfono, cifrado |
| Nombre de la tarjeta de Wallet (iPhone) | Mostrar con qué tarjeta pagaste | En tu teléfono, cifrado |
| Ubicación (latitud, longitud, precisión y dirección) | Mostrar dónde hiciste un pago, solo si la agregas | En tu teléfono, cifrada |
| Presupuesto y ajustes | Funcionamiento de la app | En tu teléfono |

## Android: lectura de pagos

Para detectar pagos solos, MiGasto usa dos permisos de Android. Los dos son opcionales: sin ellos la app funciona con registro manual.

- **Acceso a notificaciones.** Lee las notificaciones de **Yape**, **Plin** (dentro de las apps de los bancos) y **Google Wallet**, para detectar el monto, la persona o el comercio y si el dinero entra o sale. Las notificaciones de cualquier otra app se ignoran en el momento: no se leen, no se guardan.
- **Servicio de accesibilidad.** Solo escucha las apps de Yape, Plin y Google Wallet. Lee el texto de la pantalla de **constancia** de Yape cuando tú envías o pagas, porque Yape no manda notificación al que paga. No toca nada en la pantalla ni escribe por ti.

En ambos casos **no lee** tus mensajes, fotos, contactos, contraseñas ni otras apps, y lo leído se procesa en tu teléfono sin enviarse a ningún servidor. Del texto leído se guarda solo lo necesario para el movimiento (incluido el "texto original"). Puedes apagar cualquiera de los dos permisos cuando quieras en Ajustes del teléfono.

Cuando MiGasto detecta un pago muestra una **ventana flotante** (si diste el permiso "Mostrar sobre otras apps") con el monto, el comercio y la categoría para que lo confirmes, lo edites o lo descartes. Un gasto se guarda solo a los 4 segundos si no lo detienes. Un ingreso espera tu confirmación, salvo que actives en Ajustes **Guardar ingresos automáticamente**; esa opción viene apagada.

## iPhone

iOS no permite leer las notificaciones de otras apps. En iPhone, MiGasto recibe los datos de un pago con Apple Pay desde la acción "Registrar movimiento" de Atajos, que tú configuras. Los datos pasan solo entre Atajos y MiGasto, dentro de tu teléfono.

## Ubicación

Se pide solo mientras usas la app y solo cuando tocas "Agregar ubicación". Nunca se pide en segundo plano. La dirección se obtiene en tu teléfono a partir de las coordenadas. Puedes quitar la ubicación de un movimiento o borrar todas desde Ajustes. El mapa de un movimiento se carga desde Google Maps, que recibe la zona que se muestra para dibujar el mapa.

## Seguridad

La base de datos está cifrada. La clave se genera en tu teléfono y se guarda en el almacén seguro del sistema (Keychain en iPhone, Keystore en Android). Puedes activar un bloqueo con la huella, el rostro o el PIN de tu teléfono.

## Respaldo cifrado

Puedes crear un respaldo de tus datos desde Ajustes. Es un archivo que se cifra en tu teléfono con una contraseña que tú eliges; MiGasto no guarda esa contraseña ni el archivo. Incluye tus movimientos (con la ubicación y el texto original, si los hay), el presupuesto y las categorías aprendidas. El archivo solo sale del teléfono hacia donde tú lo compartas (por ejemplo Drive o correo) y solo se abre con tu contraseña: si la olvidas, nadie, tampoco nosotros, podrá recuperarlo. Restaurar un respaldo agrega los movimientos que faltan y no borra los que ya tienes.

## Exportar y borrar

Puedes exportar tus movimientos a CSV desde Ajustes (sin ubicaciones). Para borrar tus datos, elimina los movimientos desde la app o desinstálala: al desinstalar se borra todo lo guardado.

## Menores

MiGasto no está dirigida a menores de 13 años.

## Cambios

Si esta política cambia, se actualizará la fecha de arriba y se avisará en la app.

## Contacto

Michael Anthony, [@VMichael1999](https://github.com/VMichael1999).
