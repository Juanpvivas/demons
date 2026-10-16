# Android Chrome — observación física y pendientes de producción

2026-10-16, Bogotá. **W02–W05 aprobados por QA en la copia observada**.
Después la persona probó el ZIP sin observador y confirmó **«Funcionó y pude
volver al juego»**. Se recuperó una ejecución de producción con ocultación y
regreso sin recarga observada. QA aprobó **T007/T008 con alcance acotado**; T012/T013 se revisan con las
medidas y límites de este reporte. Este reporte no marca tareas. No se repitieron exportación ni GUT.
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

## Producción sin observador y regreso de pestaña

Se cargó el paquete extraído exacto desde `/production/` dentro de un wrapper
externo. La persona recibió pasos de recoger cuatro amarillos y otro antes
de desplegar, comprobar visualmente que recoger no crea una unidad, desplegar
en suelo libre a la izquierda del blanco en su fila y abrir otra pestaña de
Chrome unos cinco segundos antes de volver sin recargar. Respondió:
**«Funcionó y pude volver al juego»**. Este relato es corroboración manual
favorable a esos pasos; no acredita saldos, conteos por gesto ni estado terminal
ocultos del ZIP. W04/W05 exactos pertenecen a la prueba observada, no se
repitieron como nuevos controles de producción.

[Registros pasivos originales](android-production-probe.jsonl),
[derivado de producción](android-production-summary.json),
[captura al volver](android-production-return-current.png).
Trece mensajes únicos, SHA256
`b74f7d4ee1b1949b9dbd4926254c60f2e543e62a33710da3722dc2f9101b0c08`.
Se deduplicaron por `run_id`/`start_utc`, timestamp y contenido. El buffer se
recuperó sin recargar, seleccionando solo `/phone-production-check.html` y
filtrando `WEB_PROBE`/`WEB_PROBE_RESTORED` mediante `Runtime.enable`; no se
consultó contenido de otras pestañas ni se inyectó entrada. Listener cerrado.

Hay **una ejecución** `2026-10-16T12:39:35.789Z`, startUTC12:39:35.798Z, con
un registro de inicio humano y un evento de carga del iframe. Cronología:

| Estado de nuestra página | UTC | Desde el inicio |
|---|---|---:|
| visible |12:39:35.798|0ms|
| hidden |12:39:57.601|21802.8ms|
| visible |12:40:01.255|25456.3ms|
| hidden |12:40:02.253|26454.6ms|
| visible |12:40:07.206|31408.2ms|

Los intervalos ocultos duraron **3.6535s y4.9536s**, respectivamente; el segundo
se aproxima a los cinco segundos pedidos. Se conserva el mismo run y no hay
nuevo inicio/carga de iframe observado. La visibilidad acredita el ocultamiento
y retorno de nuestra página; el relato identifica la acción como abrir otra
pestaña, sin que la instrumentación lea esa pestaña. No prueba política interna
de suspensión/pausa del motor ni reanuda un estado terminal oculto.

La captura12:41:16Z muestra el juego de producción visible, sin A/B/HUD del
observador, un blanco a la izquierda, un amarillo y la cronología del wrapper.
No es una captura de todos los gestos ni permite saber el saldo/resultado final.
Se mantuvo horizontal2400×1080, CSS795×306, iframe795×230.

## Carga, cadencia y memoria disponibles de producción

El [wrapper temporal](phone-production-check.html) solo añade telemetría fuera
del iframe. No modifica el HTML exportado, el ZIP ni el juego. Los valores
originales se conservan en el [derivado](android-production-summary.json):

- Evento de documento del iframe a **75.2ms** desde el botón; NavigationTiming
  del HTML **69.6ms**. Son carga del documento, **no primer frame del juego**.
- Recursos de esa navegación: WASM39513091bytes, responseEnd **1295.8ms**
  (duración1227ms); PCK4702200bytes, responseEnd **336.2ms**
  (duración267.1ms). El transferSize reportado supera encodedBodySize en300bytes
  por recurso. Son tiempos del HTTP local por USB y el perfil/caché existente;
  **no carga fría verificada**, compilación total ni latencia de itch.io.
- Ventana objetivo30s del **rAF del contenedor**:1201 intervalos, suma de
  deltas visibles21734.4ms, media **55.258callbacks/s**, p50 **16.5ms**,
  p95 **16.6ms**, máximo **1835.7ms**. Incluye carga inicial, esperas del
  navegador e interrupciones de visibilidad; terminó a30843.1ms desde el
  botón. Los intervalos ocultos se separan al reiniciar la referencia temporal.
  **No mide FPS ni frame times renderizados del juego**.
- `performance.memory` de Chromium devolvió usedJSHeapSize/totalJSHeapSize
  **10000000bytes** y límite1940000000bytes. Es una estimación no estándar y
  redondeada del heapJS; **no memoria exclusiva del juego, totalWASM, PSS ni
  VRAM**. No se sustituyeron esas magnitudes por este número.

## Alcance restante

La copia observada acredita entrada/estado controlados y partida manual con
los mismos datos de producción hasta LOST; la ejecución sin observador añade
corroboración humana de recoger/desplegar y prueba pasiva de regreso visible.
QA aprobó la cobertura T007/T008 con los límites descritos, sin inventar
una pantalla terminal nueva.
W08 declara LOST observado en la copia con datos idénticos y no victoria ni
resultado terminal oculto del paquete sin HUD.

W12 tiene medidas de las sesiones disponibles de Android y escritorio, con
método y límites explícitos. Carga con caché fría verificada, memoria exclusiva
del juego/VRAM/PSS y rendimiento sostenido constitucional siguen **NOT RUN**.
Firefox, Safari y Web iOS mantienen su estado previo según disponibilidad.
No se publicó ni difundió el ZIP en itch.io y no se cerró la feature histórica002.

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
