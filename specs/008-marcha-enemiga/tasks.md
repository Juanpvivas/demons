# Tasks: Marcha enemiga

**Input**: [spec](spec.md), [plan](plan.md), [contrato](contracts/advance-visual.md) y [quickstart](quickstart.md).
**Incremento**: I1 visual en `codex/008-marcha-enemiga`, base `90cc824`. Issue [#36](https://github.com/Juanpvivas/demons/issues/36). Arte, verificación funcional/visual local y documentación APROBADOS por QA; PR, CI y cierre de integración pendientes.

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
- [ ] T007 project-orchestrator: revisar diff/base/tamaño, guardar el resultado aprobado y crear PR en borrador desde `codex/008-marcha-enemiga` hacia `main`, vinculado al Issue 008; sin promoción, merge automático o distribución. Depende de T006 aprobado.
- [ ] T008 godot-tester: revisar CI de la revisión exacta del PR, suite completa `tests/unit/` mediante `tools/ci/run_gut.py`, import/build y artefacto Web de `tools/web/export.sh`; verificar correspondencia fuente/paquete normal y repetir sólo comprobaciones invalidadas. Sin nueva campaña de rendimiento. Depende de T007 y CI terminal.
- [ ] T009 qa-validator: revisar T008, alcance funcional/visual, documentación e integridad del estado final; emitir APROBADO PARA INTEGRACIÓN sólo si cumplen, conservando los límites de cada destino y publicación pendiente. Depende de T008.

## Dependencias y estrategia

Cadena T001 → T002 → T003 → T004 → T005 → T006 → T007 → T008 → T009. Un único I1; no hay tareas `[P]` porque arte, recurso, importación y estado aprobado se comparten. La investigación de sólo lectura puede avanzar en paralelo sin usar el mismo motor/dispositivo.

El orquestador registra las aprobaciones y entrega el enlace después de T009. Los PR intermedios usan `Refs`; `Closes` sólo si todos los criterios del Issue 008 están cumplidos. Conserva Issue30/004/T039/005/T071 y demás requisitos históricos sin marcarlos por esta mejora. La preparación termina aquí y se entrega al flujo de agentes, sin invocar `speckit-implement`.
