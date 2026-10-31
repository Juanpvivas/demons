# Tasks: Combate a distancia y recompensas

**Input**: [spec](spec.md), [plan](plan.md), [contrato](contracts/ranged-combat.md), [datos](data-model.md), [quickstart](quickstart.md).
**Entrega**: 015-I1 completo, tres cambios; rama `codex/015-combate-a-distancia-y-recompensas`, base main4fb1267; [Issue #58](https://github.com/Juanpvivas/demons/issues/58), PR por orquestador.
**Flujo**: [roles/TDD](../../docs/DEVELOPMENT_WORKFLOW.md); Spec Kit prepara, agentes ejecutan. Sólo orquestador marca [X] tras QA. Sin nuevas evidencias Git.

## Preparación y setup mínimo

- [X] T001 project-orchestrator con qa-validator: revisar preparación `specs/015-combate-a-distancia-y-recompensas/`, tres reglas humanas/tabla exacta, límites y dependencia TDD; aprobar antes de código o balance.
- [X] T002 dev-godot: declarar sólo campos nuevos neutros0 en `resources/schemas/enemy_stats.gd` y `unit_stats.gd` y señal `rifle_shot_visual_requested(snapshot)` en `scenes/enemies/enemigo.gd`, según contrato. Sin emisiones/conexiones/consultas/ataques/premios ni modificar .tres/balance. Depende T001.
- [X] T003 godot-tester con qa-validator: confirmar importación/carga de interfaces T002 y neutralidad contra base; QA aprueba sólo setup. APIs actuales bastan para RED físico; parser/import roto no vale fallo esperado. Depende T002.

## RED de las tres historias

- [X] T004 [US1] godot-tester: escribir/ejecutar RED válido en `tests/unit/units/test_soldado.gd` y `tests/unit/levels/test_combat_ranged_integration.gd` para alcance864 con cuerpos/física reales hogar144→entrada1008, frente/carril/borde/diagonales inmediatas conservadas y negativos detrás/fuera/diagonal profunda; no acreditar alcance sólo llamando ataque manualmente. Depende T003.
- [X] T005 [US2] godot-tester: escribir/ejecutar RED válido en `tests/unit/enemies/test_enemigo.gd`, fixtures de nivel y `tests/unit/systems/test_combat_audio.gd`/`test_combat_visual_effects.gd` sobre enemigo estacionario/fusil inmediato+intervalos, blanco frontal vivo mismo carril/alcance, pérdida→marcha, contacto sin doble daño, diez perfiles e inicial1 sin mutación/spawn alterado; snapshot3datos/gen y admisión audio/VFX ANTES de daño/baja/terminal síncronos, cada evento único y voces admitidas conservadas, pool/callback viejo/pausa/terminal/close. Usar física real y fixture/observer de autoridad vigente sin inventar LOST por último soldado muerto. Depende T004.
- [X] T006 [US3] godot-tester: escribir/ejecutar RED válido en `tests/unit/units/test_soldado.gd` y fixture de integración para machete letal+2moral/+3vida/cap, fullHP, noletal, dueño muerto, reentrada y enemigo reciclado durante callback, última baja+terminal, y fusil+1sinheal. Adaptar sólo expectativas históricas que contradiga explícitamente la nueva regla, no relajar controles negativos. Depende T005.
- [X] T007 qa-validator: revisar RED T004–T006, controles positivos, geometría real, identidad/transacción y tabla; aprobar sólo aserciones por comportamiento ausente, sin implementación entregada. No fabricar RED para presentación reutilizada. Depende T006.

## Implementación y GREEN

- [X] T008 [US1] dev-godot: implementar tres cambios en `scenes/units/soldado.gd`, `scenes/enemies/enemigo.gd`, Resources de soldado/enemigos/oleadas, adaptadores `scenes/visuals/combat_visual_effects.gd` y `scenes/audio/combat_audio.gd`, contexto de spawner/nivel sólo si necesario. Alcance864 real, perfiles exactos inmutables, enemigo marcha/fusil/contacto excluyente y premio machete transaccional con cap/vida; snapshot validado por generación y presentación independiente. Reusar arte/audio existentes, sin pruebas, otras mecánicas/UI/persistencia/red, renderer/release o mezcla013/014. Depende T007; requiere T009–T010 para aprobación.
- [X] T009 [US1] godot-tester: confirmar GREEN T004–T006, regresión pertinente y suite GUT completa, import/build/CI aplicables y playtesting de balance según quickstart; generar un único export Web final para preview8813 y observar tres cambios/visual/audio/menú/retry en computador y apps disponibles. Distinguir física real/callback, fixture/producción, medios/gestos/renderer/FPS no observados y riesgos, sin nuevas evidencias Git o campaña006. Depende T008.
- [X] T010 qa-validator: contrastar fuente/Resources, RED/GREEN/regresión/build y playtesting T009 con tres reglas humanas/tabla; aprobar funcionalidad sólo con evidencia suficiente, especificar límites y devolver fallos al rol dueño. No certificar publicación o hardware ni observación no realizada. Depende T009.

## Documentación, CI y entrega

- [X] T011 docs-writer: consolidar sólo comportamiento aprobado en `README.md`, `docs/SPEC.md`, `docs/ARCHITECTURE.md` y specs015, distinguiendo nuevos cambios intencionales de historia anterior. Conservar013/014, pausa006 y pendientes004/005/013/014; sin tareas/fuente/tests o logs nuevos. Depende T010.
- [ ] T012 project-orchestrator con godot-tester: revisar diff/commits por resultado, publicar revisión consolidada y verificar CI del head exacto, reutilizando comprobaciones válidas y repitiendo sólo invalidadas; sin promoción/merge/distribución. Depende T011.
- [ ] T013 qa-validator: revisar documentación/CI/revisión exacta T012; emitir APROBADO PARA INTEGRACIÓN sólo con fuente, GREEN/regresión/build y balance suficientemente verificados, con límites físicos/publicación intactos. Depende T012.
- [ ] T014 project-orchestrator: consolidar Issue único y PR borrador con `Refs #<issue>`, tres cambios/IDs/RED/GREEN/QA/límites y adjuntarlo al chat; marcar sólo alcance aprobado, sin promoción/merge/distribución. Depende T013.
- [ ] T015 project-orchestrator con roles responsables: sólo con autorización futura, cumplir SC008/publicación de artefacto/renderer/firma/versión/instalación/smoke/hardware/60FPS y QA de publicación. Pendiente sin bloquear integración aprobada y sin heredar excepciones previas.

## Dependencias y cobertura

T001→T002→T003→T004→T005→T006→T007→T008→T009→T010→T011→T012→T013→T014. T015 es gate futuro separado. Sin [P] por archivos compartidos; un incremento entrega las tres historias, no RED sin GREEN.

FR001/SC001→T004,T008–T010; FR002–004/SC002–003→T005,T008–T010; FR005–006/SC004→T006,T008–T010; FR007–009/SC005–006→T005–T006,T008–T010; FR010/SC007→T004–T014; SC008→T015. Documentación y arte proporcional sin tests artificiales; balance sí requiere playtesting.
