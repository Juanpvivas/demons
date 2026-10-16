# Android Chrome — observación física y pendientes de producción

2026-10-16, Bogotá. **W02–W05 aprobados por QA en la copia observada**; W07
parcial. Producción sin observador y cambio de pestaña/regreso siguen pendientes.
T007/T012 no se cierran con este reporte. No se repitieron exportación ni GUT.
Fuente `4a2915c`, ZIP SHA256
`205d3916f21ce8c2b29eaf4bbbd804908dab7e9c93356355f4a335212eabfd71`;
script de nivel `4e89dce236868c4203079e06937b5c8dbcbbd564382f373d2216d4aa8c700d7f`.

## Evidencia recuperada sin recargar

La persona confirmó **«Completé la secuencia»**. Se recuperó el buffer de
`WEB_OBSERVER` de la página local mediante USB/Chrome DevTools. El lector
solo envió `Runtime.enable` y recibió `consoleAPICalled`: no evaluó código,
inyectó entrada, consultó otras pestañas ni cambió el juego. Se conservaron
solo mensajes propios, sin seriales. Logcat filtrado no entregó esas líneas.

Se deduplicó por timestamp de consola, ticks, tipo y contenido. Se excluyeron
las sesiones antiguas11:01/11:03Z y los gestos posteriores a LOST. Las sesiones
nuevas empezaron a **12:26:04.637Z** (s3) y **12:27:28.378Z** (s4). Los pares
mouse/touch de coordenadas y tiempo coincidentes corresponden al mismo gesto
físico, no se cuentan como dos toques humanos.

[Derivado PRE/POST y métricas](android-observed-cases.json),
[504 registros originales de las dos sesiones](android-observed-sessions.jsonl).
El raw seleccionado tiene SHA256
`71371ebbc76b0f7899c2ffc063a9e1aee7b79078d81ba5ccfce217d4a8cc35a0`.
El buffer completo congelado está fuera del repo, en
`/private/tmp/demons-web-final-003/android-observer-console-human-frozen.jsonl`.
El lector se cerró ordenadamente; no quedan grabaciones ni listener activos.

| Caso | Gesto real y precondición | PRE→POST durante JUGANDO | Resultado acotado |
|---|---|---|---|
| W02 recoger sin desplegar | s3, secuencias55/56, posición570.89,453.40; gesto en celda5,4 libre; único pickup3 centrado576,442 en celda6,4 | reserva11→14, soldados2→2; pickup desaparece | PASS observado; sin gasto10 ni unidad nueva |
| W03 libre con fondos | s3, secuencias11/12, posición507.85,525.51, celda5,5 libre, sin pickup | reserva12→2, soldados1→2, celda5,5 queda ocupada | PASS observado |
| W04 ocupada con fondos | s3, secuencias57/58, posición565.80,540.75, celda5,5 ya ocupada y reserva14 | reserva14→14, soldados1→1, ocupación5,5 conservada | PASS observado; fondos suficientes discriminan el rechazo |
| W05 libre sin fondos | s4, secuencias1/2, posición553.60,504.18, celda5,5 libre y sin pickup | reserva0→0, soldados1→1, celda libre; REJECTED registrado | PASS observado |

Los toques no siguieron literalmente todos los marcadores A/B; la conclusión
usa coordenadas, ocupación y saldo reales. El descenso2→1 soldados antes de
W04 ocurrió entre gestos; el ocupante5,5 sigue presente antes y después de W04.
Recogidas de dos pickups solapados suman6 legítimamente y no se usan como
prueba de recoger un único pickup. Los gestos tardíos en LOST no acreditan
PLAYING. No se atribuye al relato humano un saldo ni una celda no registrados.

## Pantalla y partida

Xiaomi2107113SG, Android14, Chrome154.0.8037.94. Horizontal físico2400×1080;
ventanaCSS795×306, DPR2.75, iframe795×232. A/B y HUD legibles, con altura útil
reducida por las barras y el encabezado del wrapper. La región derecha gris
visible permite tocar fuera del arte; los gestos fuera de la zona visual
del combate no se usan para los cuatro casos seleccionados. No se añadieron
límites al tablero.
[Preflight](android-landscape-preflight.png), [lecturas](android-landscape-preflight.json).

[Captura posterior a la secuencia](android-human-completed-current.png),
12:29:27Z: horizontal, reserva8/soldados1/PERDIDA, gesto56 8→8/1→1. Esta captura
es posterior al final y no reemplaza los PRE/POST de PLAYING. Las sesiones
emitieron LOST a ticks de motor50.987s y35.486s, respectivamente; hubo toque,
recolección y despliegue durante PLAYING, sin cierre observado. No se forzó
ninguna transición ni se acredita victoria manual.

## Rendimiento observado disponible

Misma copia con etiquetas y logging de solo lectura; sin grabación de pantalla
durante estas sesiones. Se conservan los valores originales en el derivado:

| Sesión | Proceso acumulado | Frames | Media desde delta | p50/p95 | Máximo |
|---|---:|---:|---:|---:|---:|
| s3 |30.06118s|1808|60.144FPS|16.393/16.667ms|133.333ms|
| s4 |30.04956s|1806|60.101FPS|16.667/16.667ms|144.133ms|

Engine reportó60FPS en ambos cortes. El primer `_process` ocurrió a1945ms y
1934ms de motor: **excluye descarga y compilación del navegador**, no es carga
fría ni tiempo hasta primer pixel. Los máximos impiden afirmar ausencia de
picos; estas muestras iniciales no certifican60FPS estables, diez oleadas ni
la categoría/antigüedad del dispositivo constitucional de referencia. No se
midió memoria del juego/VRAM ni se equiparó PSS de Chrome con ella.

## Pendientes y preparación para repetir producción

W01 de producción Android, corroboración W02–W05 sin observador, W06 adaptación
completa, W07 de producción, W10 otra pestaña/regreso y W12 de producción
siguen pendientes. El paquete extraído sin observador sigue listo en
`http://localhost:8063/production/`. Se abrió un wrapper temporal nuevo
`http://localhost:8063/phone-production-check.html`, sin iframe inicial ni
autostart; botón único **«Comenzar producción»**. [Fuente](phone-production-check.html),
[preflight sin partida](android-production-gate-ready.png),
[handoff y límites](android-production-gate-ready.json). El paquete y su HTML
exportado no se modificaron. La página propia guarda/loguea Navigation/Resource
Timing, ventana de30s de callbacks rAF del contenedor (noFPS del juego), heapJS
Chromium si existe (no memoria exclusiva del juego) y su visibilitychange.
Persiste únicamente su clave localStorage y consoleWEB_PROBE para recuperar
tras respuesta humana demorada, sin observar otra pestaña. No hay listener
ni grabación activos. La persona recibió pasos de corroboración visual y
abrir otra pestaña cinco segundos antes de volver; respuesta pendiente.
No se repiten los cuatro casos observados ya concluyentes. El ZIP no expone
saldo/estado: no se le atribuirán valores exactos de la copia observada.

## Preparación anterior conservada

Primero se encontró retrato0/0. El intento autorizado de orientación temporal
fue rechazado por Android con `WRITE_SETTINGS`, exit255; no cambió ajustes.
La persona activó después giro automático1: se preservó esa preferencia.
[Intento](android-rotation-attempt.json), [preflight anterior](android-preflight-2026-10-16.json).

Las dos grabaciones180s terminaron **antes** de las sesiones nuevas y muestran
solo la vieja PERDIDA/sin gestos. No son evidencia de los toques posteriores:
[muestras1](android-waiting-clip1-hud.jpg), [muestras2](android-waiting-clip2-hud.jpg),
[resumen histórico de espera](android-observation-waiting.json). Los videos
permanecen fuera del repositorio y no se abrió otra grabación rutinaria.
