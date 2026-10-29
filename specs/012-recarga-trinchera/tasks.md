# Tasks: Recarga directa sobre la trinchera

**Input**: [spec.md](spec.md), [plan.md](plan.md), [contrato](contracts/trench-reload.md) y [quickstart.md](quickstart.md).
**Entrega**: `012-I1`; [Issue #49](https://github.com/Juanpvivas/demons/issues/49); rama `codex/012-recarga-trinchera`.
**Flujo**: `docs/DEVELOPMENT_WORKFLOW.md`. Spec Kit prepara; ejecución por roles. Sólo el orquestador marca `[X]` tras QA. Un RED aprobado no entrega la implementación. Resultados y límites al PR/temporales, sin nuevos archivos de evidencias en Git.

## Fase 1: Preparación e interfaz neutral

- [X] T001 project-orchestrator con qa-validator: revisar `specs/012-recarga-trinchera/`, checklist, criterios y contrato contra el flujo confirmado y las reglas vigentes; aprobar preparación antes de modificar código.
- [ ] T002 dev-godot: añadir únicamente las firmas neutrales importables del contrato en `scenes/ui/hud.gd` y `scenes/levels/nivel_monte_calvo.gd`, y declarar `framing_changed` en `scenes/levels/monte_calvo_camera.gd`; sin controles nuevos, registro funcional, emisiones/conexiones nuevas, recarga directa ni retirada del botón anterior. Godot-tester confirma carga y qa-validator neutralidad. Depende de T001.

## Fase 2: US1 — Recargar directamente desde cada hogar (P1)

**Criterio independiente**: cada dueño vivo sin balas tiene un control en su trinchera; un gesto válido recarga sólo a ese dueño sin selección previa y conserva economía, combate y regreso.

- [ ] T003 [US1] godot-tester: escribir y ejecutar RED en `tests/unit/ui/test_trench_reload_controls.gd` y `tests/unit/levels/test_trench_reload_input.gd`; adaptar sólo expectativas de la UI sustituida en `tests/unit/ui/test_hud.gd` y pruebas de selección afectadas. Cubrir aparición automática, varios hogares, falta de fondos, selección independiente, anclaje HOME/resize, coste único, input real sin click-through/doble touch-mouse, identidad obsoleta y press→reemplazo→release, pausa/terminal/retorno/cierre y Retry. Fallos por aserción de comportamiento ausente, nunca parser/importación. Depende de T002 aprobada.
- [ ] T004 [US1] qa-validator: revisar independientemente T003 y `specs/012-recarga-trinchera/contracts/trench-reload.md`; aprobar sólo el RED válido con controles positivos, preservando cobertura histórica y sin dar por entregada la nueva UI. Depende de T003.
- [ ] T005 [US1] dev-godot: implementar controles y conexiones en `scenes/ui/hud.gd`, `scenes/ui/HUD.tscn` y `scenes/levels/nivel_monte_calvo.gd`; emitir `framing_changed` tras `force_update_scroll()` en `scenes/levels/monte_calvo_camera.gd` sin alterar su encuadre. Anclar al hogar mediante transformaciones del canvas, refrescar por señales y revalidar celda/identidad antes de `Soldado.request_reload()`. Retirar sólo el botón anterior conservando el panel informativo y las reglas del actor. Sin modificar tests, stats, renderer, versionado o distribución. Depende de T004; aprobación requiere T006–T008.
- [ ] T006 [US1] godot-tester: confirmar GREEN de T003 y regresión pertinente de HUD, selección, pickup/input, framing, recarga/regreso y `tests/unit/game/test_game_root.gd`. Usar la misma cobertura RED, sin debilitar aserciones; reportar resultados y diferencias. Depende de implementación T005.
- [ ] T007 [US1] godot-tester: ejecutar `specs/012-recarga-trinchera/quickstart.md`, import/build/export y smoke visual/entrada en Chrome de computador y apps Android/iOS disponibles; comprobar posición sobre trincheras, legibilidad, controles simultáneos, salud/HUD, resize, recarga/regreso y ciclo de partida. Conservar datos, distinguir fixture/producción y declarar límites de gestos nativos, renderer o hardware sin certificar FPS. Depende de T006.
- [ ] T008 [US1] qa-validator: contrastar spec, código, RED/GREEN y evidencia visual/input de T005–T007; aprobar comportamiento sólo con evidencia suficiente y declarar límites reales. Devolver fallos al rol correspondiente. Depende de T006 y T007.

## Fase final: Documentación y entrega

- [ ] T009 docs-writer: consolidar el comportamiento aprobado en `docs/SPEC.md`, `docs/ARCHITECTURE.md` y documentos de `specs/012-recarga-trinchera/`, sin marcar tareas ni añadir registros de ejecución. Depende de T008.
- [ ] T010 project-orchestrator con godot-tester: publicar la rama y verificar CI de la revisión exacta, suite GUT completa mediante `tools/ci/run_gut.py`, importación y exportación Web existentes. Se permite abrir el PR provisional en borrador para ejecutar CI; reutilizar evidencia válida sin repeticiones rutinarias. Depende de T009.
- [ ] T011 qa-validator: revisar documentación y resultados exactos de T010; emitir APROBADO PARA INTEGRACIÓN sólo con fuente, GREEN/regresión, build/export y CI conformes. Publicación y pendientes físicos conservan su gate independiente. Depende de T010.
- [ ] T012 project-orchestrator: consolidar alcance, RED/GREEN, QA y límites en PR en borrador vinculado a #49; marcar sólo tareas aprobadas y usar Closes #49 únicamente con aceptación funcional completa de 012. Sin promover, fusionar ni distribuir automáticamente; la excepción de beta 1.0.1/build 4 no se aplica. Depende de T011.

**Dependencias**: T001→T002→T003→T004→T005→T006→T007→T008→T009→T010→T011→T012. No hay tareas `[P]` en esta cadena.
**Estrategia**: un incremento funcional completo, con RED/GREEN, QA independiente, documentación y CI; no entregar setup o RED como feature terminada. Mantener pendientes de publicación de 004/005 y la pausa de rendimiento 006.
