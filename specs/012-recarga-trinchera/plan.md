# Implementation Plan: Recarga directa sobre la trinchera

**Feature ID**: `012-recarga-trinchera` | **Branch**: `codex/012-recarga-trinchera` | **Date**: 2026-10-29 | **Spec**: [spec.md](spec.md)
**Tracking**: [Issue #49](https://github.com/Juanpvivas/demons/issues/49), [PR #50](https://github.com/Juanpvivas/demons/pull/50) | **Entrega**: revisión visual de `012-I1`.
**Estado**: preparación del cambio de presentación solicitado tras T001–T012. Esa entrega y sus aprobaciones permanecen históricas; el estado vigente y sus veredictos se mantienen en [tasks.md](tasks.md). Spec Kit prepara; los agentes ejecutan `docs/DEVELOPMENT_WORKFLOW.md`.

## Summary

Sustituir los botones visibles por una zona transparente sobre cada trinchera y un brillo rojo que conserva el arte existente. El dueño vacío sin fondos queda rojo tenue estático; sólo `PLAYING` y `can_reload()` permiten pulso/orden. Se mantiene la ruta HUD→nivel→actor por hogar/identidad y el panel informativo, sin alterar economía ni regreso.

## Technical Context

**Language/Version**: GDScript / Godot 4.7.1 vigente.
**Dependencies**: HUD, nivel Monte Calvo, `BoardManager`, `Soldado`, configuración HOME y piezas laterales `PosteriorN`/`ParapetoN` existentes.
**Storage/API**: ningún dato persistente o servicio nuevo; coste/carga siguen en `UnitStats`.
**Target**: Web de computador y apps Android/iOS disponibles. No publicar instaladores de PC.
**Scope**: máximo cinco controles y diez copias visuales creadas una vez, refresco de estado por señales y un Tween por hogar elegible; no polling de estado ni asignación por frame/pulso.
**Constraints**: sin cambios de balance, física, cámara, renderer, presets, versión, distribución o campaña FPS 006.

## Constitution Check

- I: HUD/componente sólo presentan y emiten intención; nivel y actor conservan autoridad e identidad. Reutilizar texturas y orden de capas sin tocar actores/HP.
- II: RED válido de texto/área/estados/ciclo antes de desarrollo; GREEN y regresión, revisión visual real y QA independiente. El aspecto artístico no exige un fallo artificial por píxeles.
- III: ratón/toque significan una orden; conservar tamaño/legibilidad del arte, hit testing de HOME y feedback tenue/pulsante confirmado por la persona.
- IV/V: animación acotada e idempotente por hogar, sin campaña de rendimiento añadida. Integración funcional con build/CI/QA; hardware/FPS/renderer/paquete final y publicación conservan su gate separado.

## Project Structure

- `scenes/ui/trench_reload_control.gd`: componente `TrenchReloadControl extends Button`, sin decoración ni texto. Enlaza las dos piezas reales, mantiene estado visual normal/tenue/pulso y gestiona sus copias/Tween locales; [contrato](contracts/trench-reload.md).
- `scenes/ui/hud.gd`: conserva getter y señales existentes; instancia el componente y proyecta el área sobre la trinchera, no por encima. Deriva necesidad/elegibilidad por señales de dueño, fondos y partida; sin trasladar economía.
- `scenes/levels/nivel_monte_calvo.gd`: proporciona las piezas por hogar al registro del HUD; revalidación de orden sin cambios.
- `scenes/ui/HUD.tscn` sólo si la composición lo requiere. Arte/scene de Monte Calvo conserva atlas, transforms y z-order; no se necesitan bitmap, shader, bloom o luces nuevos.
- `tests/unit/ui/test_trench_reload_controls.gd` y `tests/unit/levels/test_trench_reload_input.gd`: nuevas expectativas y regresión GUI real, con ajuste sólo de presentación sustituida en pruebas relacionadas. La ruta aún inexistente del componente no debe provocar un preload/parser falso RED.

## Execution Design

1. **Preparación T013**: revisar la nueva decisión, contrato, tareas y checklist; conservar historia T001–T012 y no tratar la prueba Xiaomi anterior como validación del brillo.
2. **RED T014–T015**: usar getter Button existente para demostrar ausencia del texto vacío/área sobre HOME; observar nuevas capacidades sólo tras comprobar su disponibilidad, sin error de importación. Cubrir tenue/pulso/normal, fondos, pausa/terminal sin SceneTree pause, fin/reemplazo, entrada real y resize. QA aprueba el fallo esperado antes de desarrollo.
3. **Presentación T016**: un `TrenchReloadControl` por vínculo hereda el control real. `StyleBoxEmpty` en normal/hover/pressed/disabled/focus y texto vacío; el área sigue consumiendo gestos incluso deshabilitada. El nivel entrega las piezas `PosteriorN`/`ParapetoN` según HOME, nunca por selección.
4. **Brillo local**: dos copias aditivas reutilizan textura/alpha/transform de sus piezas como hijos locales, con expansión leve 1.03 y sin capturar input. Conservan z efectivo −4/+1 y oclusión del soldado. Estado/fuerza visuales reales pintan ambas copias; Tween suave de 0.6 s subida y 0.6 s bajada, ligado al control, sin `TIME`, `_process` ni recreación por ciclo. Estado repetido no reinicia/duplica; cambiar/salir/cerrar mata Tween, restaura y retira copias.
5. **Estado/entrada/geometría**: necesidad por dueño vivo/carga cero; elegibilidad por `can_reload()` y `PLAYING` actual. Pausa/terminal detienen pulso explícitamente por señal aunque SceneTree no se pause. Se conserva intención hogar/ID y delegación al actor; zona proyectada sobre arte/HOME tras encuadre aplicado y resize, con frontera declarada en contrato. Fuera conserva pickup→selección/despliegue.
6. **Entrega T017–T022**: GREEN/regresión y visual/build por destino disponible, QA funcional, documentación, suite completa/CI exacto y QA final en el mismo PR draft. Fixture temporal declarado para cinco hogares/estados difíciles; sin nuevos registros de evidencias en Git, merge o publicación automáticos.

## Inputs resolved

La persona sustituye explícitamente el texto por rojo y toque de trinchera, y decide tenue estático sin fondos/pulso al poder recargar. El resto de elegibilidad, economía, panel, identidad y ciclo se hereda. No hay API, persistencia, permisos ni pantallas nuevos. GodotPrompter aplicado al diseño: índice, HUD/UI, input, 2D y Tween; las rutas de instalación personales no se versionan.
