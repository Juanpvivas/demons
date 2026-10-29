# Implementation Plan: Recarga directa sobre la trinchera

**Feature ID**: `012-recarga-trinchera` | **Planned Branch**: `codex/012-recarga-trinchera` | **Date**: 2026-10-29 | **Spec**: [spec.md](spec.md)
**Tracking**: [Issue #49](https://github.com/Juanpvivas/demons/issues/49) | **Entrega**: `012-I1`.
**Note**: preparación con Spec Kit y templates del preset `demons-agent-tdd`; `demons-preparation` termina al revisar tareas. Ejecución por agentes según `docs/DEVELOPMENT_WORKFLOW.md`; T008 aprobó funcionalmente `012-I1` sobre `ba122ef`. Seguimiento de documentación/CI y gate final de integración en [tasks.md](tasks.md) y [PR #50](https://github.com/Juanpvivas/demons/pull/50); [límites de alcance](spec.md#alcance-de-la-aprobación-funcional), publicación separada.

## Summary

Trasladar la acción del panel a un botón por hogar dentro del HUD existente. El nivel conserva la autoridad de ocupación/identidad y delega la orden a `Soldado.request_reload()`; la presentación observa señales. El panel queda informativo, sin alterar reglas de recarga ni el input del tablero fuera de la UI.

## Technical Context

**Language/Version**: GDScript / Godot 4.x vigente del proyecto.
**Primary Dependencies**: `HUD.tscn`/`hud.gd`, `nivel_monte_calvo.gd`, `BoardManager`, `LaneBoardConfig` y API de recarga de `Soldado`.
**Storage**: ninguno nuevo; hogares/ocupación y estado runtime existentes, costes/carga en `UnitStats`.
**Testing**: GUT RED tras interfaz neutral; GREEN/regresión y smoke visual/input acotado.
**Target Platform**: Web en Chrome de computador y apps Android/iOS disponibles; PC nativo sólo desarrollo.
**Project Type**: juego 2D compartido entre destinos.
**Performance Goals**: máximo cinco controles estables y refresco de estado por señales; conservar objetivo constitucional sin reabrir diagnóstico 006.
**Constraints**: no polling de estado ni seguimiento del actor; sin cambios de balance, física, autoloads, renderer, presets, versión o distribución.
**Scale/Scope**: cinco hogares configurados; una acción visible por hogar y ninguna acción duplicada en el panel.

## Constitution Check

- I: el actor conserva coste y reglas desde Resources; HUD sólo presenta y emite intención. El nivel revalida ocupante, vida e identidad antes de delegar.
- II: tester RED → QA de RED → dev → tester GREEN/regresión → QA funcional → documentación. Setup neutral no entrega comportamiento; no reconstruir evidencia de 005/011.
- III: mismo significado en ratón/toque; feedback existente de retorno y rechazo; controles legibles en cada destino ejecutado.
- IV/V: conservar estructuras/pooling; cambios por señales y resize, sin campaña FPS. Integración necesita pruebas/build/CI/QA; pendientes físicos y publicación continúan identificados sin heredar la excepción de beta 1.0.1.
- Revisión previa/posterior al diseño: no se propone excepción constitucional. Este chequeo de preparación no sustituye el veredicto independiente.

## Project Structure

- `scenes/ui/HUD.tscn`, `scenes/ui/hud.gd`: capa de botones de hogares, enlaces por dueño, presentación y consulta del botón; retirar `SelectionPanel/Contents/ReloadButton` sólo al implementar el comportamiento.
- `scenes/levels/nivel_monte_calvo.gd`: registrar/desregistrar cada hogar y su ancla al crear/bajar dueño, recibir intención con hogar/identidad y validar contra `BoardManager`; desconectar en cierre.
- `scenes/levels/monte_calvo_camera.gd`: señal de encuadre aplicado para actualizar geometría después de `force_update_scroll()`, sin polling ni cambio del encuadre actual.
- `tests/unit/ui/test_trench_reload_controls.gd`, `tests/unit/levels/test_trench_reload_input.gd`: nuevas pruebas de interfaz real e identidad; regresión de `test_hud.gd`, `test_trench_selection_input.gd`, `test_pickup_input_routing.gd`, `test_soldado_reload_return.gd` y ciclo de `GameRoot`.
- Esta carpeta: spec, plan, [contrato](contracts/trench-reload.md), [quickstart](quickstart.md), checklist y tareas que mantiene el orquestador. No se necesitan modelos persistentes ni un sistema de salud/recarga nuevo.

## Execution Design

1. **Preparación e interfaz neutral**: QA revisa requisitos. Dev añade sólo firmas importables del contrato en T002; getter devuelve `null`, intención devuelve `false`, registro es vacío y señales nuevas sólo declaradas. No crear botones funcionales, conectar órdenes ni retirar la acción anterior antes del RED.
2. **RED**: tester comprueba controles reales, estado y destinatario correcto sin selección; aceptación/repetición, fondos/pausa/terminal, muerte/reemplazo/cierre, coste/salud/moral/regreso y enrutamiento GUI. Un fallo de importación o ausencia de una firma no vale como RED. QA distingue aprobación de RED de entrega.
3. **Estado y ciclo**: HUD mantiene como máximo cinco Buttons y el vínculo `home_cell`→dueño/ID capturado. Nivel registra después de que el actor inicialice su estado; creación, baja y reemplazo actualizan el vínculo. HUD observa `reload_state_changed`, economía, estado de partida y cierre; refresca también el estado inicial. Desconexiones idempotentes impiden callbacks de dueño/intento anterior.
4. **Anclaje**: calcular el centro global del hogar desde `Tablero`/configuración, no desde el soldado. Convertir mundo→coordenadas del canvas del HUD con las transformaciones vigentes; leer el encuadre inicial al registrar y escuchar `framing_changed` emitida por la cámara después de `force_update_scroll()` al redimensionar. Así la geometría no depende del orden de callbacks de resize. No desplazar tablero/actores ni cambiar `canvas_items/expand`. Conservar mínimo 112×48 y aplicar área segura del destino; comprobar separación de barras, HUD, vecinos y bordes. No polling de estado ni de posición del soldado.
5. **Orden e input**: señal con hogar/ID; nivel revalida pertenencia a `home_cells`, ocupante válido vivo, hogar e identidad actual y partida/cierre antes de `request_reload()`. El actor sigue siendo la última autoridad económica y de retorno. Buttons con `MOUSE_FILTER_STOP`; sus contenedores decorativos no cubren el tablero. Consumir mouse/touch y evitar duplicación por ratón emulado, también deshabilitados; conservar pickup→selección/despliegue fuera de GUI.
6. **GREEN y entrega**: tester verifica el contrato y regresión completa en CI; adapta expectativas del antiguo botón al cambio autorizado sin falsear su historia. Smoke acotado por destino según quickstart, QA independiente, documentación de comportamiento aprobado y PR en borrador de `012-I1` con Issue #49. Sin distribución ni cierre de pendientes de otras features.

## Inputs resolved

Flujo móvil aplicado al stack Godot compartido: descripción/confirmación directa cierran los estados de UX; texto, estilo y mínimo se heredan. No hay API, persistencia ni permisos nuevos. GodotPrompter consultado para el diseño: `using-godot-prompter`, `hud-system`, `godot-ui`, `responsive-ui`, `input-handling`; no se implementa desde las skills de preparación.
