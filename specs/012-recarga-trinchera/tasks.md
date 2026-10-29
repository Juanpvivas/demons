# Tasks: Recarga directa sobre la trinchera

**Input**: [spec.md](spec.md), [plan.md](plan.md), [contrato](contracts/trench-reload.md) y [quickstart.md](quickstart.md).
**Entrega**: `012-I1`, revisión visual en T013–T022; [Issue #49](https://github.com/Juanpvivas/demons/issues/49); rama `codex/012-recarga-trinchera`; [PR #50 en borrador](https://github.com/Juanpvivas/demons/pull/50).
**Flujo**: `docs/DEVELOPMENT_WORKFLOW.md`. Spec Kit prepara; ejecución por roles. Sólo el orquestador marca `[X]` tras QA. Un RED aprobado no entrega la implementación. Resultados y límites al PR/temporales, sin nuevos archivos de evidencias en Git.

## Entrega anterior — T001–T012 (historia conservada)

Estas tareas aprobadas corresponden al botón visible anterior hasta `994b176`. La solicitud posterior sustituye presentación/área de entrada mediante T013–T022; no altera los veredictos históricos ni acredita el efecto nuevo.

## Fase 1: Preparación e interfaz neutral

- [X] T001 project-orchestrator con qa-validator: revisar `specs/012-recarga-trinchera/`, checklist, criterios y contrato contra el flujo confirmado y las reglas vigentes; aprobar preparación antes de modificar código.
- [X] T002 dev-godot: añadir únicamente las firmas neutrales importables del contrato en `scenes/ui/hud.gd` y `scenes/levels/nivel_monte_calvo.gd`, y declarar `framing_changed` en `scenes/levels/monte_calvo_camera.gd`; sin controles nuevos, registro funcional, emisiones/conexiones nuevas, recarga directa ni retirada del botón anterior. Godot-tester confirma carga y qa-validator neutralidad. Depende de T001.

## Fase 2: US1 — Recargar directamente desde cada hogar (P1)

**Criterio independiente**: cada dueño vivo sin balas tiene un control en su trinchera; un gesto válido recarga sólo a ese dueño sin selección previa y conserva economía, combate y regreso.

- [X] T003 [US1] godot-tester: escribir y ejecutar RED en `tests/unit/ui/test_trench_reload_controls.gd` y `tests/unit/levels/test_trench_reload_input.gd`; adaptar sólo expectativas de la UI sustituida en `tests/unit/ui/test_hud.gd` y pruebas de selección afectadas. Cubrir aparición automática, varios hogares, falta de fondos, selección independiente, anclaje HOME/resize, coste único, input real sin click-through/doble touch-mouse, identidad obsoleta y press→reemplazo→release, pausa/terminal/retorno/cierre y Retry. Fallos por aserción de comportamiento ausente, nunca parser/importación. Depende de T002 aprobada.
- [X] T004 [US1] qa-validator: revisar independientemente T003 y `specs/012-recarga-trinchera/contracts/trench-reload.md`; aprobar sólo el RED válido con controles positivos, preservando cobertura histórica y sin dar por entregada la nueva UI. Depende de T003.
- [X] T005 [US1] dev-godot: implementar controles y conexiones en `scenes/ui/hud.gd`, `scenes/ui/HUD.tscn` y `scenes/levels/nivel_monte_calvo.gd`; emitir `framing_changed` tras `force_update_scroll()` en `scenes/levels/monte_calvo_camera.gd` sin alterar su encuadre. Anclar al hogar mediante transformaciones del canvas, refrescar por señales y revalidar celda/identidad antes de `Soldado.request_reload()`. Retirar sólo el botón anterior conservando el panel informativo y las reglas del actor. Sin modificar tests, stats, renderer, versionado o distribución. Depende de T004; aprobación requiere T006–T008.
- [X] T006 [US1] godot-tester: confirmar GREEN de T003 y regresión pertinente de HUD, selección, pickup/input, framing, recarga/regreso y `tests/unit/game/test_game_root.gd`. Usar la misma cobertura RED, sin debilitar aserciones; reportar resultados y diferencias. Depende de implementación T005.
- [X] T007 [US1] godot-tester: ejecutar `specs/012-recarga-trinchera/quickstart.md`, import/build/export y smoke visual/entrada en Chrome de computador y apps Android/iOS disponibles; comprobar posición sobre trincheras, legibilidad, controles simultáneos, salud/HUD, resize, recarga/regreso y ciclo de partida. Conservar datos, distinguir fixture/producción y declarar límites de gestos nativos, renderer o hardware sin certificar FPS. Depende de T006.
- [X] T008 [US1] qa-validator: contrastar spec, código, RED/GREEN y evidencia visual/input de T005–T007; aprobar comportamiento sólo con evidencia suficiente y declarar límites reales. Devolver fallos al rol correspondiente. Depende de T006 y T007.

## Fase final: Documentación y entrega

- [X] T009 docs-writer: consolidar el comportamiento aprobado en `docs/SPEC.md`, `docs/ARCHITECTURE.md` y documentos de `specs/012-recarga-trinchera/`, sin marcar tareas ni añadir registros de ejecución. Depende de T008.
- [X] T010 project-orchestrator con godot-tester: publicar la rama y verificar CI de la revisión exacta, suite GUT completa mediante `tools/ci/run_gut.py`, importación y exportación Web existentes. Se permite abrir el PR provisional en borrador para ejecutar CI; reutilizar evidencia válida sin repeticiones rutinarias. Depende de T009.
- [X] T011 qa-validator: revisar documentación y resultados exactos de T010; emitir APROBADO PARA INTEGRACIÓN sólo con fuente, GREEN/regresión, build/export y CI conformes. Publicación y pendientes físicos conservan su gate independiente. Depende de T010.
- [X] T012 project-orchestrator: consolidar alcance, RED/GREEN, QA y límites en PR en borrador vinculado a #49; marcar sólo tareas aprobadas y usar Closes #49 únicamente con aceptación funcional completa de 012. Sin promover, fusionar ni distribuir automáticamente; la excepción de beta 1.0.1/build 4 no se aplica. Depende de T011.

**Dependencias**: T001→T002→T003→T004→T005→T006→T007→T008→T009→T010→T011→T012. No hay tareas `[P]` en esta cadena.
**Estrategia**: un incremento funcional completo, con RED/GREEN, QA independiente, documentación y CI; no entregar setup o RED como feature terminada. Mantener pendientes de publicación de 004/005 y la pausa de rendimiento 006.


## Revisión visual solicitada — T013–T022

**Resultado**: quitar texto y decoración de botón; la propia trinchera vacía queda roja tenue sin fondos, pulsa sólo al poder recargar y se toca para ordenar al mismo dueño. Mismo Issue/rama/PR antes de merge. Se conserva T001–T012; no reutilizar sus aprobaciones para el efecto nuevo.

- [X] T013 project-orchestrator con qa-validator: revisar spec/plan/contrato/checklist actualizados y decisión confirmada de rojo tenue/pulso, geometría sobre trinchera, ciclo y roles; aprobar preparación de la revisión antes de nuevas pruebas/implementación.
- [X] T014 [US1] godot-tester: escribir/ejecutar RED de la presentación y área nuevas en `tests/unit/ui/test_trench_reload_controls.gd` y `tests/unit/levels/test_trench_reload_input.gd`, adaptando sólo expectativas sustituidas. Cubrir texto/style ausentes, toque sobre HOME/arte real y resize, estados normal/tenue/pulso por fondos/PLAYING, aislamiento/idempotencia y limpieza de Tween/copias, input GUI con disabled y emulación, identidad/press→reemplazo→release, cobro/regreso y ciclo. Usar interfaz importable existente; ausencia de clase nueva no vale como parser/import RED. Arte final se valida visualmente, sin aserciones artificiales de píxeles. Depende de T013.
- [X] T015 [US1] qa-validator: revisar T014 y controles positivos, aprobar sólo fallo esperado por requisito ausente, preservando regresión de economía/selección/identidad/input; no aprobar todavía implementación. Depende de T014.
- [ ] T016 [US1] dev-godot: implementar componente de zona transparente/brillo en `scenes/ui/trench_reload_control.gd`, integrarlo en `scenes/ui/hud.gd` y pasar piezas por hogar desde `scenes/levels/nivel_monte_calvo.gd`; modificar `HUD.tscn` sólo si es necesario. Mantener texturas/alpha/z-order, rojo local sin actor/HP, Tween único/idempotente y limpieza; área sobre trinchera y misma autoridad/identidad. Sin tocar pruebas, balance, cámara, renderer, presets, versión o publicación. Depende de T015; aprobación requiere T017–T018.
- [ ] T017 [US1] godot-tester: confirmar GREEN de T014 y regresión pertinente de HUD, selección/pickup/input, framing, recarga/regreso y GameRoot. Ejecutar quickstart vigente, import/build/export y revisión visual/input Chrome de computador y apps Android/iOS disponibles: cinco hogares, pulso/tenue, arte/HP, resize, normalización y ciclo; conservar beta/datos, distinguir fixture/producción y declarar entornos/gestos/renderer/FPS no observados. Depende de implementación T016.
- [ ] T018 [US1] qa-validator: contrastar spec, código, RED/GREEN y visual/input/build de T016–T017; aprobar funcionalidad sólo con evidencia suficiente, declarar límites y devolver fallos al rol responsable. No extrapolar prueba humana Xiaomi del botón anterior al brillo nuevo. Depende de T017.
- [ ] T019 docs-writer: consolidar comportamiento aprobado en `docs/SPEC.md`, `docs/ARCHITECTURE.md` y documentos de `specs/012-recarga-trinchera/`; conservar historia y límites sin crónicas/evidencias nuevas ni marcado de tareas. Depende de T018.
- [ ] T020 project-orchestrator con godot-tester: publicar revisión en la misma rama/PR #50 y verificar CI del head exacto, guard Python, suite GUT completa mediante `tools/ci/run_gut.py`, importación y exportación Web. Reutilizar verificaciones válidas sin repeticiones rutinarias. Depende de T019.
- [ ] T021 qa-validator: revisar documentación consolidada y resultados exactos de T020; emitir APROBADO PARA INTEGRACIÓN sólo con fuente, GREEN/regresión, visual/build/export y CI conformes. Publicación y pendientes físicos siguen separados. Depende de T020.
- [ ] T022 project-orchestrator: consolidar título/cuerpo del PR #50 e Issue #49 alrededor de la señal roja y toque de trinchera, conservar trazabilidad RED/GREEN previa y nueva con límites; marcar sólo tareas aprobadas. `Closes #49` sólo con aceptación vigente completa, manteniendo PR en borrador sin promoción/merge/distribución. Depende de T021.

**Dependencias de la revisión**: T013→T014→T015→T016→T017→T018→T019→T020→T021→T022. No hay tareas `[P]` en esta cadena; sigue vigente la pausa de 006 y la separación de publicación de 004/005.
