# Investigación: notificaciones de pago de bancos y billeteras en Perú

Fecha: 23 de noviembre de 2026. Para la lectura de pagos de MiGasto en Android (`PaymentNotificationListener` + `assets/reader_rules.json`).

## 1. Resumen

1. **Dos paquetes de la lista están mal.**
   - `com.bbva.bbvacontigo` es *BBVA España*. La app de BBVA Perú es `com.bbva.nxt_peru`.
   - `com.banbif.plin` no existe en Google Play.
   - Hoy MiGasto **no recibe** las notificaciones de BBVA Perú ni las de BanBif.
2. **Falta la app del BCP** (`com.bcp.bank.bcp`), además de Ligo, Lemon, Bim, Banco de la Nación y las cajas.
3. **El lector decide el origen del pago por palabras del texto, no por el paquete de la app.**
   - Si el texto no dice «yape», «plin» o «google wallet», se descarta.
   - Por eso se pierden casos reales:
     - el yape recibido con código de seguridad;
     - todo lo de Interbank;
     - el «Cobro con QR» de BBVA;
     - los consumos de Google Wallet (`PEN35.00 …`).
4. **Plin no es una app.** Es una función dentro de las apps de BBVA, Interbank, Scotiabank, BanBif, Caja Arequipa, Caja Ica, Caja Huancayo, Alfin y Ligo. Las notificaciones llegan con el paquete del banco.
5. **No hay fuentes públicas oficiales con los textos de las notificaciones.** Los textos reales salen de proyectos abiertos que los capturaron en teléfonos (sección 4). Para BCP, Scotiabank, BanBif, BN, Ligo, Lemon y Bim no se encontró ninguna muestra real.

## 2. Paquetes de Android confirmados en Google Play (gl=PE)

| Entidad | Paquete | ¿En MiGasto hoy? |
|---|---|---|
| Yape | `com.bcp.innovacxion.yapeapp` | Sí |
| Banca Móvil BCP | `com.bcp.bank.bcp` | **No** |
| iO (BCP) | `pe.io` | No |
| BBVA Perú | `com.bbva.nxt_peru` | **No** (está el de España) |
| Interbank | `pe.com.interbank.mobilebanking` | Sí |
| Interbank Negocios (antes Tunki) | `pe.com.interbank.mpay.customer` | No |
| Scotiabank Perú | `pe.com.scotiabank.blpm.android.client` | Sí |
| BanBif (Nueva BanBif App) | `pe.com.banbif.pnappmobile` | **No** (está `com.banbif.plin`, que no existe) |
| Banco de la Nación | `pe.com.bn.app.bancodelanacion` | No |
| Ligo | `pe.com.tarjetasperuanasprepago.tppapp` | No |
| Lemon | `com.applemoncash` | No |
| Bim | `com.pdp.bim` | No |
| Mercado Pago | `com.mercadopago.wallet` | No |
| Google Wallet | `com.google.android.apps.walletnfcrel` | Sí |
| Caja Arequipa | `com.cmac.cajamovilaqp` | No |
| Caja Huancayo | `com.cajahuancayo.cajahuancayo.appcajahuancayo` | No |
| Caja Ica | `com.cmacica.prd` | No |
| Caja Piura (absorbió a Caja Sullana en 2024) | `pe.cajapiura.bancamovil` | No |
| Alfin Banco | `com.alfinbanco.appclientes` | No |
| Coopac Norandino WalletOn (billetera DALE) | `com.wdt.banking.norandino` | No |

**Sobre «DALE»:**
- Es la billetera de Coopac Norandino y vive dentro de su app WalletOn.
- GMoney usa el mismo nombre para una solución B2B de interoperabilidad, que no es una app para usuarios.
- No hay una app «DALE» aparte.

**Sobre Lemon:** es argentina. Opera en Perú a través de Lanin Pay S.A.C., registrada ante el BCRP. Es interoperable con Yape y Plin, por número de celular, CCI y QR.

## 3. Quién está en Plin y cómo interoperan

- **Plin:** empezó con BBVA, Interbank y Scotiabank. Después se sumaron:
  - BanBif;
  - Caja Arequipa, Caja Sullana (hoy Caja Piura), Caja Ica y Caja Huancayo;
  - Alfin;
  - Ligo.
- **Interoperabilidad del BCRP (Circular 0024-2022-BCRP):**
  - Yape ↔ Plin desde el 31 de marzo de 2023.
  - En la fase 3 entraron las emisoras de dinero electrónico (EEDE, como Ligo) y Bim.
  - La fase 4 abre la puerta a las fintech (Lemon y GMoney/DALE).
  - Consecuencia: un yape puede llegar a una app de banco como un «Plin», y al revés.

## 4. Textos reales de notificación (capturados en teléfonos)

Leyenda: **real** = el proyecto lo declara capturado en un teléfono; **sin marcar** = parece real, pero el proyecto no lo dice.

### Yape (`com.bcp.innovacxion.yapeapp`)

| Tipo | Título | Texto | Origen |
|---|---|---|---|
| Ingreso | `Confirmación de Pago` | `Yape! ADRIAN MAMANI te envió un pago por S/ 1` | real (S-kkipie/cuadre, 2026-10) |
| Ingreso | `Confirmación de Pago` | `Sasha Sal* te envió un pago por S/ 5.5. El cód. de seguridad es: 667` | real (Sirveme/pagoOK) |
| Ingreso | — | `ANA LUCIA PEREZ GOMEZ te envió un pago por S/ 1.50`, con el prefijo `Yape!` y sin código (pagó desde un banco) | real (adria9s/yape-listener-prueba) |
| Publicidad | `¡Suerte asegurada!🍀` | `Gana hasta S/3,000 afiliándote a Dinero Más Seguro…` | real (pagoOK) |
| Publicidad | `Tu dinero seguro a S/ 4.99 al mes💜` | `Protege tus cuentas Yape y BCP y participa por S/5,000. T&C.` | real (pagoOK) |
| Gasto | — | **Yape no notifica al que paga** (0 «Yapeaste» en 142 avisos reales de pagoOK). Por eso MiGasto lee la constancia con Accesibilidad. | — |

**Detalles del formato:**
- El nombre viene enmascarado con `*`, por ejemplo `Sal*` o `De-*`.
- El monto va sin decimales de relleno (`S/ 1`, `S/ 2.5`).
- El código de seguridad tiene 3 dígitos y puede empezar con 0. No aparece si el pagador usó una app de banco.

### BBVA Perú (`com.bbva.nxt_peru`)

| Tipo | Título | Texto | Origen |
|---|---|---|---|
| Plin recibido | `¡Recibiste un Plin! 💸` | `ADRIAN ISSAC MAMANI te plineó S/1 .` | real (cuadre) |
| Plin enviado | `¡Enviaste un Plin!` | `Plineaste S/1 a Adrian I Mamani Q .` | real (cuadre) |
| Cobro con QR | `Cobro con QR` | `VICTOR RAUL MAMANI QUEA te hizo un pago de S/ 20.0` | real (Powerwid/Listener, con la app BBVA Empresas) |

### Interbank (`pe.com.interbank.mobilebanking`)

| Tipo | Título | Texto | Origen |
|---|---|---|---|
| Plin recibido | `Interbank` | `Te plinearon S/ 1.00` | real (pagoOK) |
| Plin recibido | `Interbank` | `Persona Ejemplo te ha plineado\nS/ 1.00` (a veces hay un salto de línea después de `S/`) | real (Reve7339/lyape, PaulGuillen/PagoControl) |
| Plin enviado | `Interbank` | `Plineaste S/ 1.00 a Ana R Torres P` | real (pagoOK) |
| Consumo con tarjeta | `Interbank` | `Realizaste un consumo de S/.50.00 en COMPA#IA OPERADORA DE L con tu Tarjeta de Crédito.` | real (pagoOK) |
| Cargo recurrente | `Interbank` | `Se realizó un pago recurrente de $26.19 en HOSTINGER* HOSTINGER.C con tu Tarjeta de Débito.` | real (pagoOK) |
| Transferencia enviada | (sin título) | `TRAN S/ 10.00\nA ****534\n(25/10 08:48:33)` | real (pagoOK) |

### Google Wallet (`com.google.android.apps.walletnfcrel`)

| Título (comercio y ciudad) | Texto | Origen |
|---|---|---|
| `OPENPAY*XIN FU        LIM` | `PEN35.00 con Visa Clasica BCP Qore ••0771` | real (Lume03/Kipu) |
| `COLONIAL C31 CERCADO` | `PEN1.50 con Visa Clasica BCP Qore ••0771` | real (Kipu) |

**Sin ninguna muestra real:** BCP (push), Scotiabank, BanBif, Banco de la Nación, Ligo, Lemon, Bim, DALE, Mercado Pago y las cajas. Del BCP solo hay correos («Realizaste un consumo de S/ 25.78 con tu Tarjeta de Débito BCP en …»).

## 5. Qué lee hoy el lector de MiGasto

Pasé estas muestras por `PaymentReader` (Dart). Las reglas son las mismas de `reader_rules.json` que usa Kotlin. La prueba fue temporal y se borró.

| Muestra | Resultado |
|---|---|
| Yape `Yape! … te envió un pago por S/ 1` | ✅ ingreso 1.00, «ADRIAN MAMANI» |
| Yape con código `… te envió un pago por S/ 5.5. El cód. …` | ❌ no la lee (el texto no dice «yape») |
| Publicidad de Yape | ✅ la ignora |
| BBVA `¡Recibiste un Plin! … te plineó S/1 .` | ⚠️ ingreso 1.00, pero el nombre sale «un ! ADRIAN ISSAC MAMANI» |
| BBVA `Plineaste S/1 a …` | ✅ gasto 1.00 |
| BBVA `Cobro con QR … te hizo un pago de S/ 20.0` | ❌ |
| Interbank `Te plinearon`, `te ha plineado`, `Plineaste` | ❌ («plinearon» y «plineaste» no pasan el filtro de palabra completa «plin», y el título es «Interbank») |
| Interbank `Realizaste un consumo de S/.50.00` | ❌ (sin palabra de proveedor) |
| Interbank `$26.19` | ❌ (no hay regla para montos en dólares) |
| Interbank `TRAN S/ 10.00` | ❌ |
| Google Wallet `PEN35.00 con Visa…` | ❌ (no dice «google wallet» y el monto va como `PEN`) |

## 6. Recomendaciones para MiGasto

> **Aplicado en la rama `fix/lector-paquetes-bancos`:** puntos 1, 2 y 3 (salvo los montos en dólares y el `TRAN` de Interbank), el freno de duplicados entre Google Wallet y el banco, y el interruptor «Tarjetas de bancos». Siguen pendientes los puntos 4 a 7. Con esos cambios, el lector lee todas las muestras de la sección 5, menos `$26.19` y `TRAN`.

1. **Corregir la lista de paquetes.**
   - Cambiar `com.bbva.bbvacontigo` → `com.bbva.nxt_peru`.
   - Cambiar `com.banbif.plin` → `pe.com.banbif.pnappmobile`.
   - Agregar BCP, Ligo, Lemon, Bim, BN y las cajas.
   - Mover la lista a `reader_rules.json`, para que Kotlin y Dart compartan una sola fuente.
2. **Decidir el proveedor por el paquete y no por el texto.** Pasar `sbn.packageName` al lector y mapear paquete → fuente (Yape, BCP, BBVA, Interbank…). El texto solo decide si es ingreso o gasto. Para no perder información, una notificación de banco con «plin» puede guardarse como fuente «Plin» y banco «BBVA».
3. **Ampliar las reglas** con los textos reales:
   - **Ingreso:** `te plinearon`, `te ha plineado`, `te hizo un pago`.
   - **Gasto:** `realizaste un consumo`, `se realizó un pago`, `^TRAN`.
   - **Montos:** `PEN`, `US$` y `$`, guardados con su moneda y sin convertirlos.
   - **Limpieza del nombre:** quitar `¡recibiste un plin!` y `cobro con qr`.
4. **Publicidad:** mantener la regla de «sin verbo de pago, no es pago», y sumar una lista negra («participa», «gana hasta», «afíliate», «T&C»).
5. **Extras de la notificación:**
   - Seguir leyendo `EXTRA_BIG_TEXT` (trae el código de Yape cuando `EXTRA_TEXT` viene cortado).
   - Agregar `EXTRA_TEXT_LINES`.
   - Ignorar las notificaciones con `FLAG_GROUP_SUMMARY` (el resumen de un grupo).
   - Leer los extras dentro de un try/catch, porque algunas apps de banco meten objetos propios.
6. **Código de seguridad de Yape:** guardarlo como texto (puede empezar con 0). Sirve como identificador para evitar duplicados.
7. **Fase 0 del plan: muestras propias.**
   - Agregar un modo de depuración que guarde `paquete | título | texto | bigText | textLines` de las apps vigiladas.
   - Hacer un pago de S/ 1 por cada banco o billetera que se use, y convertir lo capturado en pruebas de `payment_reader_test.dart`.
   - Es la única forma de cubrir BCP, Scotiabank, BanBif, Ligo y Lemon.

## 6b. Textos reales de BCP, Interbank, BBVA y Yape (24 de noviembre de 2026)

Salen de proyectos abiertos que capturaron avisos reales de usuarios en Perú (el más confiable es [pagoOK](https://github.com/Sirveme/pagoOK), una app en producción; también [NotiPago](https://github.com/angel113-cmyk/NotiPago), [lyape](https://github.com/Reve7339/lyape), [cuadre](https://github.com/S-kkipie/cuadre), [luca](https://github.com/JosephRobles23/luca/blob/HEAD/docs/discovery/formatos-correos-bcp-yape.md) y [money-assistant](https://github.com/rgomeztinoco/money-assistant/tree/HEAD/resources/notification-formats)). Los nombres se reemplazaron.

- **BCP avisa sobre todo por correo** (`notificaciones@notificacionesbcp.com.pe`); no hay textos públicos de la notificación de su app ni de sus SMS («BCPOFICIAL»). Consumo con tarjeta: «Realizaste un consumo de S/ 53.30 con tu Tarjeta de Débito BCP en CA012 AVIACION.»; yapeo a celular desde el BCP: «Realizaste un yapeo a celular de S/ 2.00 desde tu Clasica Soles.» (no dice a quién); recibido: «Recibiste un yapeo de S/ 1,157.00 de NOMBRE.»; transferencias: «Realizaste una transferencia de S/ 25.00 desde tu Cuenta digital.» (asunto «Constancia de Transferencia a Otros Bancos / Entre mis Cuentas / a Terceros BCP»); rechazos: «Se rechazó tu compra por fondos insuficientes».
- **Yape no avisa al que paga** (0 «Yapeaste» en 142 avisos reales de pagoOK). Sí manda correo desde S/ 10: «¡Acabas de yapear exitosamente!» con la tabla Monto de yapeo, Celular del Beneficiario, Nombre del Beneficiario; y «Tu yapeo de servicio ha sido confirmado» (Empresa, Servicio).
- **Interbank:** «Plineaste S/ 1.00 a A. R. C. N.» (iniciales), «NOMBRE te ha plineado S/ 1.00» publicado **dos veces** (títulos «Interbank» y «Negocios»), «Realizaste un consumo de S/.50.00 en COMERCIO con tu Tarjeta de Crédito.», «Se realizó un pago recurrente de $26.19 en …» y la transferencia «TRAN S/ 10.00 A ****534 (25/10 08:48:33)», sin título ni nombre.
- **BBVA:** «¡Recibiste un Plin! 💵 NOMBRE te plineó S/16.80 .» y «Cobro con QR · NOMBRE  te hizo un pago de S/ 11.0».
- **Sin ningún texto público:** Scotiabank, Ligo, Prex, Bim (Banco de la Nación dejó de emitirla y el BCP cierra sus cuentas), Sip (billetera de Intercorp con Oh! y Agora), Ripley, Falabella, BanBif, Banco de la Nación, Mibanco, cajas y Mercado Pago. Para ellas hay que capturar avisos propios.
- **Circular 0024-2022-BCRP:** cada banco avisa a su cliente (el que envía y el que recibe) por el medio que elija; como mínimo, el nombre de la otra parte y el monto.

Lo aplicado en `fix/lector-bcp-interbank-yape`: fuente «Transferencia», correos de Yape con su tabla (iPhone), nombres de Interbank, «TRAN», limpieza de los asuntos del BCP, rechazos y promociones, y el Plin repetido de Interbank (Android: mismo texto de la misma app en 5 s; iPhone: mismo monto y fuente en 2 min).

## 7. Riesgos de plataforma y de tienda

- **Android 15 y 16:** las notificaciones con códigos de un solo uso (OTP) se marcan como «sensibles». Los lectores de notificaciones de terceros reciben el texto oculto. No afecta a los avisos de pago, pero sí a los mensajes de los bancos que traen una clave. No hay que depender de ellos.
- **Google Play, Accesibilidad:**
  - Una app que no es de accesibilidad necesita una divulgación destacada con consentimiento explícito y una declaración en Play Console.
  - Desde octubre de 2025 se prohíbe la automatización autónoma con la API.
  - Leer la constancia de Yape es lectura, no automatización, pero hay que justificarla bien en la declaración.
- **Google Play, acceso a notificaciones:** la política de *spyware* prohíbe robar información de las notificaciones de otras apps si no es la función principal de la app. Por eso la ficha y el onboarding deben dejar claro que leer los pagos es la función central.
- **Seguridad:** el fraude del «Yape falso» se hace con capturas de pantalla o con notificaciones de otras apps. Filtrar por paquete exacto (y no por el texto) también protege contra eso.

## 8. Fuentes

**Plin, interoperabilidad y billeteras**
- Plin, sitio oficial: https://plin.pe/
- BBVA, «Ya son 7 las entidades financieras que se han incorporado a Plin»: https://www.bbva.com/es/pe/ya-son-7-las-entidades-financieras-que-se-han-incorporado-a-plin/
- Caja Arequipa, Guía PLIN (enero 2025): https://www.cajaarequipa.pe/wp-content/uploads/2025/01/Guia-PLIN-23-01-25.pdf
- Gestión, «Ligo se adhiere a Plin»: https://gestion.pe/tu-dinero/finanzas-personales/fintech-peruana-se-adhiere-a-plin-y-podra-interoperar-con-otros-bancos-ligo-brcr-sbs-noticia/
- BCRP, Estrategia de interoperabilidad 2024: https://www.bcrp.gob.pe/docs/Sistema-Pagos/articulos/estrategia-de-interoperabilidad-2024.pdf
- BCRP, Estrategia de interoperabilidad 2025: https://www.bcrp.gob.pe/docs/Sistema-Pagos/articulos/estrategia-de-interoperabilidad-2025-1.pdf
- Gestión, Lemon en Perú: https://gestion.pe/economia/empresas/lemon-la-billetera-cripto-que-ingreso-al-terreno-de-yape-y-plin-sus-expectativas-en-el-mercado-peruano-pagos-digitales-visa-criptomonedas-billeteras-digitales-yape-plin-noticia/
- Peru Retail, SBS y la emisora vinculada a Lemon: https://www.peru-retail.com/sbs-autoriza-organizacion-de-nueva-emisora-de-dinero-digital-vinculada-a-lemon-para-operar-en-peru/
- Infomercado, Coopac Norandino lanza DALE: https://infomercado.pe/coopac-norandino-lanza-dale-la-primera-billetera-digital-interoperable-que-conectara-a-todos-sus-socios/
- El Peruano, Caja Piura asume a Caja Sullana: https://elperuano.pe/noticia/247689-sbs-caja-piura-asumira-la-cartera-de-creditos-y-depositos-de-caja-sullana

**Fichas de Google Play** (`https://play.google.com/store/apps/details?id=<paquete>`): todas las de la tabla de la sección 2.

**Proyectos abiertos con textos reales**
- https://github.com/S-kkipie/cuadre
- https://github.com/Sirveme/pagoOK
- https://github.com/adria9s/yape-listener-prueba
- https://github.com/Reve7339/lyape
- https://github.com/PaulGuillen/PagoControl
- https://github.com/Lume03/Kipu
- https://github.com/Powerwid/Listener
- https://github.com/Keny4747/motocaja
- https://github.com/edzondev/new-app-quipu
- https://github.com/draux-l/Chihuan
- https://github.com/Alexander-Manosalva-Peralta/parlante-cobros-app

**Android y Google Play**
- Android Authority, notificaciones sensibles en Android 15: https://androidauthority.com/android-15-sensitive-notifications-3416414
- Android Authority, Android 16 y la pantalla bloqueada: https://www.androidauthority.com/android-16-sensitive-notifications-lock-screen-3501564
- Google Play, uso de la API de Accesibilidad: https://support.google.com/googleplay/android-developer/answer/10964491
- Google Play, vista previa de políticas: https://support.google.com/googleplay/android-developer/answer/16585319
