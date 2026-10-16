# 003 — Entrega Web revisada y alcance de validación

**Fecha**: 2026-10-16, Bogotá. **Rol**: docs-writer, consolidación T014 para QA.
**Issue**: [#14](https://github.com/Juanpvivas/demons/issues/14).
**Estado**: entrega 003 aceptada por QA en su alcance Web para Chrome de
escritorio y este Xiaomi horizontal. La demo sigue en desarrollo con límites
globales de medición y soporte explícitos. Este documento consolida lo
aprobado; su dictamen y marcado corresponden a QA y al orquestador.
No hay publicación en itch.io; esta consolidación no hace merge ni difusión.

## Progreso aprobado

[Tasks](../tasks.md) es la fuente vigente de aprobaciones y checkboxes.
QA aprobó T011/T012 y la revisión T013: trazabilidad FR-001–012/SC-001–007
completa para esta entrega acotada. Los informes de medición y sus límites
permiten aceptar 003 sin certificar rendimiento sostenido o entornos no
probados. T014 consolida esos hechos para su dictamen documental; solo el
orquestador marca la tarea tras QA. No se amplía soporte por extrapolación.

- Política: constitución 2.0.0, Web más apps Android/iOS; ejecución nativa de
  computador sigue disponible para desarrollar/probar. Se conservan el flujo
  de agentes, TDD y las evidencias históricas.
- Exportación: Godot estándar 4.7.1, Compatibility solo Web, un hilo, sin PWA o
  extensiones; preset con recursos de producción y exclusiones comprobadas en
  el PCK. Configuración Mobile y distribución Android/iOS conservadas.
- Generación: `tools/web/export.sh` produce carpeta Web, ZIP y manifest/logs
  exteriores; dos generaciones T010, incluida copia limpia, verificaron el
  procedimiento. Workflow nuevo adjunta artefactos; run remoto aún NOT RUN.
- Corrección necesaria FR-003: se eliminó el despliegue accidental al recoger
  munición. T015 documentó RED real y T017 añadió protección de despliegue
  emulado; T016/T017/T018 quedaron aprobados para código y escritorio.
  Costos, recompensas, datos, InputMap, escenas y arte se conservaron.

Referencias: [baseline](baseline.md), [arranque](web-startup.md),
[paquete inicial](web-package.md), [RED de recogida](t015-red.md),
[RED de despliegue emulado](t017-w03-red.md),
[GREEN, invariantes y candidato vigente](t017-green.md).

## Candidato local vigente

| Dato | Valor |
|---|---|
| ZIP | `build/demons-web.zip`, ignorado por Git |
| Manifest | `build/web-manifest.json`, exterior al ZIP |
| Fuente | `4a2915c5ceb075fbaa3ec7ce1e129a4c34aa497a`, copia limpia, `source_dirty=false` |
| Tamaño ZIP | 14 893 307 bytes, aproximadamente 14.89 MB |
| SHA256 | `205d3916f21ce8c2b29eaf4bbbd804908dab7e9c93356355f4a335212eabfd71` |
| Contenido | 12 miembros, index.html en raíz, 44 652 145 bytes extraídos |
| Avisos | 3 archivos en `licenses/`, copias exactas; sin licencia nueva para la IP del juego |
| PCK | 78 rutas, clases/escenas/pickup y diez oleadas; sin internos excluidos |

[Manifest preservado](t017-web-manifest.json),
[verificación de integridad](t017-package-verification.json) e
[inventario del PCK](t017-pck-inventory.json). Los textos propios de guía y
seguimiento se excluyen del paquete; editarlos no atribuye un nuevo build.

## Validación disponible

| Caso/entorno | Resultado y límite |
|---|---|
| W01 Chrome escritorio 155.0.8059.84 | PASS: tres cargas del candidato final, directa e iframes de 960/1152; arte y combate, sin errores. Caché existente; sin declarar carga fría. |
| W02–W05 escritorio | PASS controlado durante PLAYING: recoger 12→15 sin soldado; desplegar 15→5 con uno nuevo; rechazos por ocupación con fondos y por fondos insuficientes. Repetición visual de producción acotada, sin saldos ocultos atribuidos. |
| W06 resize/iframe | PASS acotado: clic correcto después de 1152×648→960×540; CSS (200,440)→mundo (240,528), celda (2,5), saldo 12→2 y una unidad durante PLAYING. También iframe con offset y corroboración visual de producción. |
| GUT de la corrección | 6/6 focalizados, 36 aserciones; suite 189/189, 532 aserciones, 3 avisos conocidos. Dispatch real SubViewport, no toque físico. |
| W10 recarga | PASS parcial reportado por tester; no completa regreso real de otra pestaña. |
| W10 cambio real de pestaña | PASS Android: confirmación humana y hidden→visible en el mismo run sin recarga observada. Escritorio continúa NOT RUN por límite de herramienta. |
| Chrome Android físico W02–W07 | Aceptados en el alcance horizontal; W02–W05 observados y recogida/despliegue/regreso de producción corroborados visualmente por la persona, sin saldos ocultos atribuidos al ZIP. |
| Firefox, Safari macOS, navegador iOS | NOT RUN. Sin soporte anunciado por extrapolación. |
| W08 smoke manual Web | PASS acotado: partidas manuales observadas hasta LOST con datos idénticos de producción, más corroboración visual sin observador. No se atribuye terminal oculto al ZIP ni victoria manual. |
| W12 carga/rendimiento/memoria Web | PARCIAL: escritorio, Android observado y métricas del contenedor móvil de producción; carga fría y memoria exclusiva del juego pendientes. Gate constitucional sin certificar. |
| CI Web remoto | NOT RUN; sí se verificó localmente el procedimiento de generación y empaquetado. |

El [informe GREEN](t017-green.md) contiene las pruebas aceptadas y separa los
ensayos tardíos en LOST de la evidencia válida en PLAYING.
[Datos del resize](w06-resize-click.json), [iframe durante PLAYING](w06-iframe-playing.json)
y [validación final parcial del tester](final-validation.md).

Esta última conserva dos mediciones distintas: proceso Godot **instrumentado
durante 30.0197 s**, media **119.42 FPS**, p95 **8.33 ms** y máximo **95.7 ms**;
y producción sin observador con **119.7 callbacks rAF/s del contenedor**,
que no miden FPS renderizados del juego. Son mediciones de escritorio,
separadas de las físicas Android siguientes.

En Xiaomi 2107113SG/Android 14/Chrome 154.0.8037.94, QA aprobó estos resultados de
la copia observada: W02 **11→14, soldados 2→2**; W03 **12→2, soldados 1→2**;
W04 ocupada con fondos **14→14, soldados 1→1**; W05 libre sin fondos **0→0,
soldados 1→1**, con rechazo registrado. Todos corresponden a JUGANDO; las
diferencias de soldados entre gestos no se atribuyen al toque. La evidencia
usa las posiciones reales, sin modificar límites de colocación.
[Informe físico](android-validation.md), [PRE/POST derivados](android-observed-cases.json)
y [registros de las sesiones](android-observed-sessions.jsonl).

Dos muestras Android instrumentadas de unos 30 s registraron medias
**60.144/60.101 FPS**, p95 **16.667 ms** y máximos **133.333/144.133 ms**.
Excluyen descarga y compilación, no prueban diez oleadas ni 60 FPS estables.
Carga fría y memoria exclusiva del juego siguen pendientes.

En producción móvil la persona confirmó **«Funcionó y pude volver al juego»**.
Los [13 registros del wrapper](android-production-probe.jsonl), resumidos en
[producción móvil](android-production-summary.json), conservan un único
inicio/carga y el mismo run, con ocultaciones de **3.654/4.954 s** y regreso,
sin recarga observada. Es corroboración visual humana de recogida/despliegue
y retorno, separada de los saldos/celdas PRE/POST de la copia observada.

Métricas con caché conservada: carga del documento iframe a **75.2 ms** desde
inicio, respuesta WASM **1227 ms**, contenedor **55.26 callbacks rAF/s** y heap
JavaScript estimado **10 MB**. Ni el documento listo ni el tiempo de respuesta
son primer píxel/partida lista; rAF no mide FPS del juego y el heap Chromium
puede estar cuantizado y no representa memoria exclusiva del juego, WASM,
PSS o VRAM. El registro incluye carga y cambios de visibilidad. Los nuevos
resultados de producción y el retorno recibieron aprobación acotada en
T007/T008; no cierran los gates globales.

## Límites globales y seguimiento

Permanecen sin certificar el rendimiento sostenido y dispositivo constitucional
de referencia, carga fría, memoria exclusiva del juego, otros navegadores y
run CI remoto. El foco de escritorio sigue NOT RUN; el retorno Android sí
está aprobado. T012 acredita mediciones reales con límites, no suprime esos
pendientes globales. La aceptación de 003 no implica publicación, merge,
victoria manual ni terminal visible en el ZIP sin observador.

La feature 002 permanece abierta con sus gates propios de iOS, entrada y
rendimiento; este cambio de destinos y la corrección de 003 no cierran su
historial. [Estado de 002](../../002-monte-calvo-terreno-trincheras/evidence/implementation-status.md).

La [guía de operador](../../../docs/WEB_EXPORT.md) explica generación, avisos y
futura carga manual en itch.io. La entrada y el smoke tienen aprobación
acotada; la guía no convierte esos resultados en soporte universal ni en
certificación de rendimiento sostenido.
