# Android — sesión con interacción humana sobre la línea base

**Fecha**:2026-10-16UTC (2026-10-15enBogotá). **Rol**:`godot-tester`. Complemento del [baseline Android](android-baseline.md), previo al arte. Xiaomi2107113SG, app debug local del snapshot original; no se reinstaló ni modificó el build durante esta sesión.

Se reinició exclusivamente `com.juanpvivas.demons` mediante `am force-stop` y `am start -W`. **Retorno0, COLD**, inicio registrado a **2026-10-16T01:08:17Z**; Android reportó TotalTime346ms/WaitTime352ms para la Activity. No es medición de carga completa. El agente solo reinició y capturó la pantalla; **la persona realizó los toques físicos**. No hubo inyecciónADB ni cambios de gameplay/estado desde un observador.

| Captura | Tiempo desde retorno del lanzamiento | Observación directa |
|---|---:|---|
| [08s](android-human-baseline-08s.png) |8.250s|Soldado blanco inicial y enemigos rojos sobre el fondo gris|
| [18s](android-human-baseline-18s.png) |18.370s|Soldado inicial naranja, enemigos y pickup amarillo visible|
| [28s](android-human-baseline-28s.png) |28.343s|Soldado inicial naranja y otro soldado naranja arriba/a su derecha; pickup visible|
| [40s](android-human-baseline-40s.png) |40.338s|Soldado inicial naranja y otros soldados blancos visibles, incluido uno a su izquierda|

Todas son2400×1080 y la captura retornó0. [Eventos de ejecución](android-human-baseline-events.json). Los tiempos corresponden al reloj del capturador; no se registraron coordenadas o instantes de cada toque ni telemetría de saldo.

La persona confirmó después: **«Recogí munición y apareció otro soldado».** El orquestador transmitió este relato al tester. Las capturas corroboran que hay nuevos soldados visibles durante la sesión. Se registra como evidencia humana de recolección y aparición de un nuevo soldado en el juego original.

No se infiere de esa frase ni de las capturas el saldo exacto, costo descontado, celda elegida, número de pickups recogidos o correspondencia de cada aparición a un toque concreto. Tampoco acredita por separado celda ocupada, rechazo por falta de fondos o ausencia de despliegue adicional por el mismo evento de recolección. Esos casos no fueron confirmados individualmente por la persona. La equivalencia de picking sobre la decoración futura sigue pendiente hasta repetir la prueba con el arte integrado.

No se cambió implementación, pruebas, ajustes de seguridad, proyecto, versión o firma. Esta sesión amplía la evidencia anterior: el bloqueo de INJECT_EVENTS se conserva como limitación de la herramienta, pero no impidió el toque físico de la persona. No acredita aún toda la matrizV3/I1–I9 ni un objetivo sostenido de rendimiento.
