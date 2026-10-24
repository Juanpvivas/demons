# Tasks: Disparos visibles — 010-I1

**Input**: [spec](spec.md), [plan](plan.md), [contrato](contracts/rifle-shot-visual.md), [modelo](data-model.md) y [quickstart](quickstart.md).
**Tracking**: [Issue #40](https://github.com/Juanpvivas/demons/issues/40) | rama `codex/010-disparos-visibles`.
**Flujo**: [DEVELOPMENT_WORKFLOW](../../docs/DEVELOPMENT_WORKFLOW.md). Spec Kit prepara; los agentes ejecutan. Sólo el orquestador marca `[X]` después de QA independiente. Todos los IDs empiezan pendientes.

Un solo incremento funcional: no separar RED de su implementación GREEN al entregar el PR. Sin tareas de publicación, mediciones de FPS ni reactivación de #30. Logs/capturas temporales fuera de Git; resultados y límites breves en el PR.

## Fase 1 — Preparación e interfaz mínima

- [X] T001 project-orchestrator con qa-validator: revisar consistencia de `specs/010-disparos-visibles/spec.md`, `plan.md`, `tasks.md`, `contracts/rifle-shot-visual.md` y `checklists/requirements.md`; confirmar alcance 010-I1/Issue #40 y separar integración/publicación. Sin dependencias; verificación documental.
- [X] T002 dev-godot: preparar sólo la señal y helper neutro de `scenes/units/soldado.gd`/`soldado_visual.gd`, la clase/escena `scenes/visuals/rifle_shot_visual_effect.gd` y `RifleShotVisualEffect.tscn`, y las firmas nuevas neutras de `scenes/visuals/combat_visual_effects.gd` según contrato. Sin emisión, ancla calculada, conexión, adquisición, dibujo, reloj o finalización funcional. Conservar APIs de bajas. Depende de T001; tester verifica carga/importación y qa-validator comprueba neutralidad antes de aprobar setup.

## Fase 2 — US1: reconocer cada disparo (P1)

**Grupo de comportamiento**: evento confirmado + snapshot + efecto reciclado + ciclo de intento; FR-001–009, SC-001–004. Independiente: observar un tiro real y su desaparición conservando el combate.

### RED

- [X] T003 [US1] godot-tester: escribir/ejecutar `tests/unit/units/test_soldado_rifle_effects.gd` y `tests/unit/systems/test_rifle_visual_effects.gd`; extender proporcionalmente `tests/unit/game/test_game_root.gd`. Cubrir tiro real/cadencia/ausencia de listener, frente/diagonal, última bala, no tiro en estados excluidos, snapshot anterior a daño/reciclado, registro idempotente, vida ≤0,20 s, simultáneos/reset/callback obsoleto, PAUSED y WON/LOST con fade previo, menú/cierre/Retry sin residuos. Depende de T002 aprobada; entregar RED por aserciones del comportamiento ausente, con entorno/acción válidos, y distinguir regresión ya GREEN.
- [X] T004 [US1] qa-validator: auditar sólo lectura T003 y el contrato de `specs/010-disparos-visibles/contracts/rifle-shot-visual.md`; confirmar que no es fallo de parser/importación ni prueba vacía y que T003 no depende de implementación. Depende de T003; veredicto «APROBADO — tarea de pruebas en RED; implementación pendiente» cuando corresponda.

### Desarrollo y GREEN

- [X] T005 [US1] dev-godot: implementar productor/snapshot en `scenes/units/soldado.gd` y `soldado_visual.gd`, efecto en `scenes/visuals/rifle_shot_visual_effect.gd`/`RifleShotVisualEffect.tscn`, segundo pool/ciclo en `scenes/visuals/combat_visual_effects.gd` y cierre anterior a deshabilitar hijos en `scenes/levels/nivel_monte_calvo.gd`. Una señal antes del daño, flash/trazo pictóricos, snapshot sin actores, fade terminal y cierre inmediato según contrato. Depende de T004 aprobada; no tocar stats, atlas, corrida, enemigo, pool genérico, UI ni `project.godot`; dev no escribe ni ejecuta tests. Aprobación requiere T006–T008.
- [X] T006 [US1] godot-tester: confirmar GREEN de T003 y regresión pertinente de `tests/unit/units/test_soldado.gd`, `test_soldado_visual.gd`, `test_soldado_reload_return.gd`, `test_soldado_lane_motion.gd`, `tests/unit/systems/test_combat_visual_effects.gd`, nivel/GameRoot afectados. Depende de la implementación entregada de T005, sin exigir marcarla aprobada antes de GREEN; reportar pruebas, resultados, causa de cualquier ajuste y conservación de daño/munición/moral/oleadas/condiciones terminales, sin debilitar aserciones.
- [X] T007 [US1] godot-tester: ejecutar `specs/010-disparos-visibles/quickstart.md` §§4–5: import/build/export existentes con `tools/web/export.sh`, visual real en Chrome de computador y smoke pertinente en apps Android/iOS disponibles; confirmar boquilla/dirección/estilo/duración, HUD/entrada/resize y nueva partida. Depende de T006; conservar datos/apps y declarar destino, renderer, fixture y límites. Sin pruebas Web móvil, distribución ni campaña de rendimiento.
- [X] T008 [US1] qa-validator: revisar independientemente fuente, pruebas RED/GREEN y visual real de T005–T007 contra `specs/010-disparos-visibles/spec.md`/contrato. Depende de T006 y T007; aprobar comportamiento sólo con GREEN y evidencia suficiente, o devolver defectos al rol responsable. Declarar pendientes físicos/de renderer/paquete y anomalías observadas, sin certificar publicación.

## Fase 3 — Documentación y PR

- [X] T009 docs-writer: documentar sólo comportamiento aprobado en `docs/SPEC.md` y el patrón observador/pool/cierre en `docs/ARCHITECTURE.md`, con historial breve y enlaces a 010; consolidar `specs/010-disparos-visibles/plan.md`, `research.md` y `quickstart.md` si difiere la decisión final. Depende de T008 aprobada; no modificar `tasks.md`, gameplay o tests ni volcar registros.
- [ ] T010 project-orchestrator con godot-tester: publicar únicamente la rama de trabajo y confirmar CI de la revisión exacta, incluyendo suite completa `tests/unit/` por `tools/ci/run_gut.py`, import/build y exportación Web de los workflows existentes. Depende de T009; se permite abrir un PR provisional en borrador con `Refs #40` para disparar CI Web, sin declarar aún el gate final. No distribuir builds ni repetir la suite completa sin cambios/fallos que lo justifiquen; resultados/limitaciones para QA y el cuerpo del PR.
- [ ] T011 qa-validator: revisar `docs/SPEC.md`, `docs/ARCHITECTURE.md`, documentación 010 y resultados exactos de T010 junto al alcance funcional aprobado. Depende de T009 y T010; emitir APROBADO PARA INTEGRACIÓN sólo con documentación, GREEN/regresión, build/export y CI correctos; publicación continúa pendiente.
- [ ] T012 project-orchestrator: consolidar y entregar el PR en borrador de `codex/010-disparos-visibles` contra `main`, vinculado a [#40](https://github.com/Juanpvivas/demons/issues/40), con comportamiento final, trazabilidad RED/GREEN, QA, comandos/resultados/límites y publicación pendiente; reutilizar el provisional de T010 si existe. Depende de T011 aprobada; revisar descripción concreta con QA, marcar sólo alcance aprobado y usar `Closes #40` sólo si todos los criterios de 010 están cumplidos (en otro caso `Refs #40`). Sin promover, fusionar ni distribuir automáticamente.

## Dependencias y aprobación

T001 → T002 → T003 → T004 → T005 → T006 → T007 → T008 → T009 → T010 → T011 → T012. T008 requiere además T006; T011 requiere además T009. No hay tareas paralelas porque el contrato y los archivos se comparten.

RED aprobado completa únicamente su tarea de pruebas; T005 permanece pendiente hasta GREEN y QA. TDD no se fabrica para documentos/setup, ni se atribuye retroactivamente a la corrida u otros sistemas existentes. El orquestador registra las aprobaciones proporcionales; Spec Kit no ejecuta estas tareas. Un límite de publicación no se convierte en prueba aprobada ni en obligación nueva de medición dentro de 010.
