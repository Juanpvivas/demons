# Tasks: Carrera del soldado colombiano

**Input**: [spec](spec.md), [plan](plan.md), [contrato](contracts/run-visual.md) y [quickstart](quickstart.md).
**Incremento**: I1 visual desde `main` `a88e7c5`, rama `codex/009-carrera-soldado-colombiano`. Issue [#38](https://github.com/Juanpvivas/demons/issues/38). Implementación y QA pendientes; publicación pendiente.

Flujo: [desarrollo](../../docs/DEVELOPMENT_WORKFLOW.md). Arte/recursos sin lógica nueva usan verificación visual, importación y regresión existente; no RED artificial. Si cambia comportamiento, volver al orquestador para tester RED → dev → GREEN → QA. Sólo el orquestador marca `[X]` tras QA. Sin nuevos archivos de evidencias en Git.

## Fase 1: Preparación

- [X] T001 project-orchestrator: revisar `checklists/requirements.md`, alcance, rama/base e Issue único009; obtener QA de preparación de `spec.md`, `plan.md`, `tasks.md` y sus contratos antes de asignar arte. Conservar pausa006 y requisitos históricos de publicación.

## Fase 2: US1 — Corrida de ida y regreso

**Objetivo**: pasos alternados y cierre continuo en ambos recorridos con personaje, equipo y reglas vigentes. Cubre FR-001–007 y SC-001–004.
**Criterio independiente**: observar tres vueltas de cada clip y el recorrido de salida/contacto/orden de recarga/regreso/hogar del quickstart.

- [ ] T002 [US1] dev-godot: crear `assets/sprites/units/monte_calvo/soldado_carrera_machete_atlas.png`, `soldado_carrera_regreso_atlas.png`, sus hojas opuestas `soldado_carrera_machete_opuesta_atlas.png` y `soldado_carrera_regreso_opuesta_atlas.png`, y sus `.import`; integrar únicamente ocho fases de `melee_march` y `returning` en `soldado_lateral_frames.tres` según `contracts/run-visual.md`, con ciclo0,60s. Medir regiones/márgenes y apoyos; conservar todos los otros clips, atlas anterior, escenas, scripts, stats y enemigo008. Entregar procedencia/prompts/encaje al tester y docs; no ejecutar pruebas. Depende de T001 aprobado.
- [ ] T003 [US1] godot-tester: verificar importación/carga y reproducción real de ambos clips durante tres vueltas ampliadas/a tamaño juego, apoyos, unión y actores/filas según `quickstart.md`; comprobar salida/parada/contacto/ataque/recarga/regreso/hogar, impacto/baja y nuevo intento, smoke de partida y regresión existente pertinente de `tests/unit/units/test_soldado_visual.gd`, `test_soldado.gd` y flujos de nivel afectados. Identificar Web/app/entorno y límites; preservar apps/datos y limpiar sólo recursos propios. Sin campaña de rendimiento. Depende de T002.
- [ ] T004 [US1] qa-validator: contrastar arte real, recursos, fuentes y T003 con FR-001–008/SC-001–004; emitir veredicto funcional/visual independiente, revisando especialmente las dos transferencias de apoyo y el cierre. No extrapolar destinos ni aprobar lógica sin TDD. Depende de T003.

## Fase final: Documentación y entrega

- [ ] T005 docs-writer: consolidar sólo lo aprobado en `assets/sprites/units/monte_calvo/SOURCES.md`, documentos009 y notas útiles de `README.md`/`docs/SPEC.md`; registrar procedencia/prompts/encaje definitivos y mantener publicación pendiente. No editar tareas ni volcar registros. Depende de T004 aprobado.
- [ ] T006 qa-validator: revisar T005, enlaces/coherencia y vigencia de la evidencia del estado final, sin abrir rendimiento o publicación. Depende de T005.
- [ ] T007 project-orchestrator: revisar diff/base/tamaño y commits, publicar rama y preparar PR en borrador a `main`, vinculado al Issue009; sin promoción, merge o distribución. Depende de T006 aprobado.
- [ ] T008 godot-tester: confirmar CI terminal de la revisión exacta del PR, suite completa `tests/unit/` mediante `tools/ci/run_gut.py`, import/build y artefacto Web de `tools/web/export.sh`; verificar correspondencia fuente/paquete normal y repetir sólo comprobaciones invalidadas. Depende de T007.
- [ ] T009 qa-validator: revisar T008, alcance funcional/visual, documentación y estado final; emitir APROBADO PARA INTEGRACIÓN sólo si se cumple el alcance de009, con límites por destino y publicación pendiente. Depende de T008.

## Dependencias y estrategia

Cadena T001 → T002 → T003 → T004 → T005 → T006 → T007 → T008 → T009. Un único I1; sin `[P]` porque ambos clips comparten identidad, recurso e importación. La investigación de sólo lectura puede avanzar en paralelo, sin competir por motor/dispositivo.

La preparación termina al analizar estas tareas; no invoca `speckit-implement` ni ejecuta el juego. El orquestador usa `Refs` en entregas intermedias y `Closes` sólo tras cumplir todos los criterios de009. No marca pendientes de004/005/006 por esta entrega.
