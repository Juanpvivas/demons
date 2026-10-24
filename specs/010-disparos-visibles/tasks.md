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
- [X] T010 project-orchestrator con godot-tester: publicar únicamente la rama de trabajo y confirmar CI de la revisión exacta, incluyendo suite completa `tests/unit/` por `tools/ci/run_gut.py`, import/build y exportación Web de los workflows existentes. Depende de T009; se permite abrir un PR provisional en borrador con `Refs #40` para disparar CI Web, sin declarar aún el gate final. No distribuir builds ni repetir la suite completa sin cambios/fallos que lo justifiquen; resultados/limitaciones para QA y el cuerpo del PR.
- [X] T011 qa-validator: revisar `docs/SPEC.md`, `docs/ARCHITECTURE.md`, documentación 010 y resultados exactos de T010 junto al alcance funcional aprobado. Depende de T009 y T010; emitir APROBADO PARA INTEGRACIÓN sólo con documentación, GREEN/regresión, build/export y CI correctos; publicación continúa pendiente.
- [X] T012 project-orchestrator: consolidar y entregar el PR en borrador de `codex/010-disparos-visibles` contra `main`, vinculado a [#40](https://github.com/Juanpvivas/demons/issues/40), con comportamiento final, trazabilidad RED/GREEN, QA, comandos/resultados/límites y publicación pendiente; reutilizar el provisional de T010 si existe. Depende de T011 aprobada; revisar descripción concreta con QA, marcar sólo alcance aprobado y usar `Closes #40` sólo si todos los criterios de 010 están cumplidos (en otro caso `Refs #40`). Sin promover, fusionar ni distribuir automáticamente.

## Dependencias y aprobación

T001 → T002 → T003 → T004 → T005 → T006 → T007 → T008 → T009 → T010 → T011 → T012. T008 requiere además T006; T011 requiere además T009. No hay tareas paralelas porque el contrato y los archivos se comparten.

RED aprobado completa únicamente su tarea de pruebas; T005 permanece pendiente hasta GREEN y QA. TDD no se fabrica para documentos/setup, ni se atribuye retroactivamente a la corrida u otros sistemas existentes. El orquestador registra las aprobaciones proporcionales; Spec Kit no ejecuta estas tareas. Un límite de publicación no se convierte en prueba aprobada ni en obligación nueva de medición dentro de 010.

## Revisión de 010-I1 — legibilidad y alcance (2026-10-24)

La persona probó Web y apps Android/iOS y confirmó este ajuste para el mismo
PR #41: tamaño doble de destello/trazadora, extremo frontal 264→396 (+50 %),
recorrido visual de 0,30 s y desvanecido final de 0,10 s. Se mantienen el daño
inmediato, las diagonales contiguas y las demás reglas. T001–T012 conservan
su aprobación histórica del perfil anterior; no acreditan esta revisión.

- [X] T013 docs-writer en autoría, con project-orchestrator y qa-validator: alinear spec, plan, contrato, modelo, quickstart y checklist de 010 con el perfil autorizado, alcance en Resource y geometría propia por actor; revisar coherencia antes de RED. Sin gameplay ni evidencia retroactiva.
- [ ] T014 godot-tester en RED: ampliar las pruebas de alcance frontal y vida visual mediante las interfaces existentes; demostrar fallo por tiro ausente dentro del nuevo rango y por desaparición anterior al nuevo recorrido. Cubrir límites, aislamiento del Resource, pausa y cierre pertinentes; actualizar fronteras del perfil anterior sin alterar su historia. Depende de T013.
- [ ] T015 qa-validator: auditar T014 y sus fallos por aserción contra el contrato revisado; aprobar sólo la tarea RED, dejando implementación pendiente. Depende de T014.
- [ ] T016 dev-godot: implementar el alcance frontal desde UnitStats/.tres sin mutar formas compartidas; duplicar tamaño visual, recorrer boca→destino capturado durante 0,30 s y desvanecer en otros 0,10 s, con flash de 0,14 s y acabado pictórico. Conservar daño inmediato, cadencia, munición, diagonales, prioridades, corrida y ciclo del pool. Sin pruebas, cambios a project.godot ni alcance adicional. Depende de T015; aprobación requiere T017–T018.
- [ ] T017 godot-tester en GREEN: repetir RED y regresión pertinente de combate horizontal, efectos y ciclo; verificar importación/exportación, visual y entrada en Chrome de computador y apps Android/iOS disponibles, y una sesión manual de balance por el nuevo alcance. Preservar datos y una app normal por destino; declarar variantes y límites, sin mediciones nuevas de rendimiento. Depende de T016 implementada.
- [ ] T018 qa-validator: revisar código, pruebas, RED/GREEN y secuencia visual real de T016–T017, incluidos destino visible, estilo, límites de rango y limpieza. Aprobar sólo con evidencia suficiente, sin certificar publicación. Depende de T017.
- [ ] T019 docs-writer en consolidación: actualizar docs/SPEC.md, docs/ARCHITECTURE.md y documentación 010 con el comportamiento aprobado, distinguiendo el ajuste de alcance de las reglas conservadas; sin registros de ejecución ni cambios a tareas. Depende de T018.
- [ ] T020 project-orchestrator con godot-tester y qa-validator: publicar la rama existente, confirmar suite GUT completa y CI/build/export de la revisión exacta tras documentación; QA revisa el estado final y emite APROBADO PARA INTEGRACIÓN con publicación pendiente. Depende de T019; reutilizar evidencia aún válida sin repetir por rutina.
- [ ] T021 project-orchestrator: actualizar el PR #41 en borrador y el Issue #40 con el comportamiento final, pruebas/QA y límites; marcar sólo el alcance aprobado. Depende de T020. Sin promoción, merge ni distribución; publicación pendiente e Issue #30 pausado.

Orden de revisión: T013 → T014 → T015 → T016 → T017 → T018 → T019 → T020 → T021.
