# Tasks: Marcha enemiga

**Input**: [spec](spec.md), [plan](plan.md), [contrato](contracts/advance-visual.md) y [quickstart](quickstart.md).
**Incremento**: I1 visual en `codex/008-marcha-enemiga`, base `90cc824`. Issue [#36](https://github.com/Juanpvivas/demons/issues/36); [PR #37 en borrador](https://github.com/Juanpvivas/demons/pull/37). T001–T009 conservan su aprobación histórica en `f05d9e6`. Corrección de continuidad T010–T016 APROBADA PARA INTEGRACIÓN por QA; resultados, CI exacta y límites en el PR en borrador. Publicación pendiente.

Flujo: [desarrollo](../../docs/DEVELOPMENT_WORKFLOW.md). Arte/recursos sin lógica nueva usan importación y criterios visuales, no RED artificial. Si cambia comportamiento, volver al orquestador para una secuencia tester RED → dev → GREEN → QA. Sólo el orquestador registra `[X]` tras aprobación independiente; no añadir evidencias nuevas a Git.

## Fase 1: Preparación

- [X] T001 project-orchestrator: revisar `checklists/requirements.md`, rama/base, Issue 008, roles y alcance de I1; registrar la decisión de pausar 006 sin completar sus pendientes y autorizar la ruta visual tras QA de preparación.

## Fase 2: US1 — Ciclo de aproximación

**Objetivo**: apoyos opuestos y pasos intermedios legibles, con identidad pictórica y estados actuales intactos. Cubre FR-001–006 y SC-001–004.

- [X] T002 [US1] dev-godot: crear `assets/sprites/enemies/monte_calvo/enemigo_marcha_atlas.png`, `enemigo_marcha_opuesta_atlas.png` y sus `.import`, e integrar únicamente ocho fases de `advance` en `enemigo_lateral_frames.tres` según `contracts/advance-visual.md`; medir regiones/anclajes de las texturas importadas y conservar contacto/caída, escena, código y stats. Entregar procedencia/prompt/encaje al tester y a docs; no ejecutar pruebas. Depende de T001.
- [X] T003 [US1] godot-tester: comprobar importación/carga y ciclo real ampliado/a tamaño juego, unión final→inicio, varios actores y recorrido avance/contacto/impacto/baja/reutilización/Retry de `quickstart.md`; ejecutar regresión existente pertinente de `tests/unit/enemies/test_enemigo_visual.gd`, `test_enemigo.gd` y pool/integración afectados. Identificar destinos Web/apps y límites; conservar apps normales/datos y limpiar sólo recursos propios. Sin probes o mediciones de rendimiento. Depende de T002.
- [X] T004 [US1] qa-validator: contrastar arte/recurso/fuentes y T003 con FR-001–008/SC-001–004; emitir alcance funcional/visual y riesgos, sin certificar pruebas no realizadas, rendimiento o publicación. Si se modificó lógica, exigir su TDD antes de aprobar. Depende de T003.

## Fase final: Documentación y entrega

- [X] T005 docs-writer: consolidar sólo alcance aprobado, procedencia/prompt y encaje en `assets/sprites/enemies/monte_calvo/SOURCES.md`, documentos de 008 y notas útiles de `README.md`/`docs/SPEC.md`; conservar pausa006 y pendientes históricos. No modificar tareas ni volcar registros. Depende de T004 aprobado.
- [X] T006 qa-validator: revisar documentación final de 008, procedencia y vigencia del estado probado tras T005, devolviendo cualquier defecto al rol responsable; confirmar que no se abrió trabajo de rendimiento ni publicación. Depende de T005.
- [X] T007 project-orchestrator: revisar diff/base/tamaño, guardar el resultado aprobado y crear PR en borrador desde `codex/008-marcha-enemiga` hacia `main`, vinculado al Issue 008; sin promoción, merge automático o distribución. Depende de T006 aprobado.
- [X] T008 godot-tester: revisar CI de la revisión exacta del PR, suite completa `tests/unit/` mediante `tools/ci/run_gut.py`, import/build y artefacto Web de `tools/web/export.sh`; verificar correspondencia fuente/paquete normal y repetir sólo comprobaciones invalidadas. Sin nueva campaña de rendimiento. Depende de T007 y CI terminal.
- [X] T009 qa-validator: revisar T008, alcance funcional/visual, documentación e integridad del estado final; emitir APROBADO PARA INTEGRACIÓN sólo si cumplen, conservando los límites de cada destino y publicación pendiente. Depende de T008.

## Dependencias y estrategia

Cadena T001 → T002 → T003 → T004 → T005 → T006 → T007 → T008 → T009. Un único I1; no hay tareas `[P]` porque arte, recurso, importación y estado aprobado se comparten. La investigación de sólo lectura puede avanzar en paralelo sin usar el mismo motor/dispositivo.

El orquestador registra las aprobaciones: T009 cierra la entrega original y T016 la corrección solicitada en revisión. Los PR intermedios usan `Refs`; `Closes` sólo si todos los criterios del Issue 008 están cumplidos. Conserva Issue30/004/T039/005/T071 y demás requisitos históricos sin marcarlos por esta mejora. La preparación termina aquí y se entrega al flujo de agentes, sin invocar `speckit-implement`.

## Corrección solicitada en revisión: continuidad del ciclo

La persona observa un leve brinco al completar los dos apoyos y aporta dos referencias adicionales. Se conserva el alcance de FR-001–008/SC-001–005 y la historia anterior; no es una nueva feature ni autoriza gameplay o rendimiento.

- [X] T010 godot-tester: diagnosticar la discontinuidad en las ocho fases y el cierre, comparando altura del cuerpo, apoyo, alineación y orden temporal con las nuevas referencias. Entregar capturas y causa a desarrollo; sin modificar la implementación ni fabricar RED de arte.
- [X] T011 dev-godot: corregir la causa visual identificada por T010 en el encaje, secuencia o arte de `advance`, preservando contacto/caída, escena, lógica, stats y velocidad jugable. Consultar al orquestador si requiere código o cambio de alcance. No ejecutar pruebas.
- [X] T012 godot-tester: comparar antes/después durante varios ciclos, ampliados y a tamaño de juego, y comprobar la marcha real en Chrome y los destinos afectados disponibles; verificar importación/carga y regresión pertinente, reutilizando evidencia no invalidada. Sin mediciones de rendimiento ni instalaciones sin preservar apps/datos.
- [X] T013 qa-validator: revisar T010–T012 de forma independiente contra FR-001–008/SC-001–004, especialmente continuidad del cuerpo, transferencia de apoyo y última→primera pose. No sustituir movimiento real por una imagen estática ni extrapolar destinos.
- [X] T014 docs-writer: documentar la corrección aprobada, las referencias adicionales y el encaje final útil en documentos de 008/SOURCES; mantener historia, pausa de 006 y publicación pendiente. Sin registros nuevos de QA en Git.
- [X] T015 qa-validator: revisar T014 y la vigencia del estado probado antes de actualizar el PR; aprobar sólo el alcance documentado real.
- [X] T016 project-orchestrator, godot-tester y qa-validator: guardar el resultado aprobado, actualizar el mismo PR en borrador y el Issue, verificar CI/paquete de la revisión exacta y obtener APROBADO PARA INTEGRACIÓN final. Marcar sólo después del veredicto independiente; sin promoción, merge o publicación.

Orden de corrección: T010 → T011 → T012 → T013 → T014 → T015 → T016. Los criterios visuales e importación son proporcionales; cualquier cambio de comportamiento requiere su ciclo TDD antes de desarrollo.
