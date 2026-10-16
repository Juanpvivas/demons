# 003 — Entrega Web WIP y validación parcial

**Fecha**: 2026-10-15, Bogotá. **Rol**: docs-writer, borrador de seguimiento.
**Issue**: [#14](https://github.com/Juanpvivas/demons/issues/14).
**Estado**: implementación disponible para revisión local; aceptación global
pendiente. Este reporte no completa T011/T014, no marca tareas ni constituye
consolidación final. No hay publicación en itch.io ni PR final de la feature.

## Progreso aprobado

[Tasks](../tasks.md) conserva **12/18 tareas aprobadas** por QA y marcadas por
el orquestador: T001–T006, T009/T010 y T015–T018. Siguen pendientes T007, T008,
T011, T012, T013 y T014. La documentación de entrega se mantiene como borrador
hasta contar con la matriz y los gates restantes.

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
| W10 cambio real de pestaña | NOT RUN por límite de la herramienta disponible. No simularlo con una llamada DOM. |
| Chrome Android físico W02–W05/W07 | Los cuatro casos NOT RUN; teléfono preparado para iniciar, pendientes acciones físicas. Una app Android nativa previa no valida el navegador. |
| Firefox, Safari macOS, navegador iOS | NOT RUN. Sin soporte anunciado por extrapolación. |
| W08 smoke manual Web | PARCIAL: interacciones durante PLAYING y LOST natural observado a 33.840 s, sin cierre. Producción sin observador no expone estado terminal; no acredita victoria manual ni smoke móvil. |
| W12 carga/rendimiento/memoria Web | PARCIAL en escritorio: proceso Godot instrumentado y cadencia del contenedor medidos; carga fría, memoria y Android NOT RUN. Gate constitucional pendiente. |
| CI Web remoto | NOT RUN; sí se verificó localmente el procedimiento de generación y empaquetado. |

El [informe GREEN](t017-green.md) contiene las pruebas aceptadas y separa los
ensayos tardíos en LOST de la evidencia válida en PLAYING.
[Datos del resize](w06-resize-click.json), [iframe durante PLAYING](w06-iframe-playing.json)
y [validación final parcial del tester](final-validation.md).

Esta última conserva dos mediciones distintas: proceso Godot **instrumentado
durante 30.0197 s**, media **119.42 FPS**, p95 **8.33 ms** y máximo **95.7 ms**;
y producción sin observador con **119.7 callbacks rAF/s del contenedor**,
que no miden FPS renderizados del juego. No son resultados Android ni una
certificación de 60 FPS estables. Carga fría y memoria permanecen NOT RUN.

## Lo que falta para cerrar

Completar los cuatro casos físicos Android, matriz de entrada y navegadores
según disponibilidad, W10 real y los reportes de smoke/rendimiento aplicables;
registrar límites con su estado exacto. Después corresponden QA global T013 y
consolidación T014. No se promueve o fusiona un PR ni se publica una página
por generar un ZIP WIP.

La feature 002 permanece abierta con sus gates propios de iOS, entrada y
rendimiento; este cambio de destinos y la corrección de 003 no cierran su
historial. [Estado de 002](../../002-monte-calvo-terreno-trincheras/evidence/implementation-status.md).

La [guía de operador](../../../docs/WEB_EXPORT.md) explica generación, avisos y
futura carga manual en itch.io. Su sección móvil permanece condicionada a
validación real; el paquete no se difunde a testers externos sin el smoke
exigido por la constitución.
