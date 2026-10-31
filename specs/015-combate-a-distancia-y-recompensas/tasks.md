# Tasks: Combate a distancia y recompensas

**Input**: [spec](spec.md), [plan](plan.md), [contrato](contracts/ranged-combat.md), [datos](data-model.md), [quickstart](quickstart.md).
**Entrega**: 015-I1 completo, tres cambios; rama `codex/015-combate-a-distancia-y-recompensas`, base main4fb1267; [Issue #58](https://github.com/Juanpvivas/demons/issues/58), [PR #59 en borrador](https://github.com/Juanpvivas/demons/pull/59). Integración aprobada sobre `2351798`; sin merge ni publicación.
**Incremento siguiente**: 015-I2 en preparación; T016–T025 pendientes. I1/T001–T014 y sus aprobaciones se conservan; T015 publicación sigue pendiente.
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
- [X] T012 project-orchestrator con godot-tester: revisar diff/commits por resultado, publicar revisión consolidada y verificar CI del head exacto, reutilizando comprobaciones válidas y repitiendo sólo invalidadas; sin promoción/merge/distribución. Depende T011.
- [X] T013 qa-validator: revisar documentación/CI/revisión exacta T012; emitir APROBADO PARA INTEGRACIÓN sólo con fuente, GREEN/regresión/build y balance suficientemente verificados, con límites físicos/publicación intactos. Depende T012.
- [X] T014 project-orchestrator: consolidar Issue único y PR borrador con `Refs #<issue>`, tres cambios/IDs/RED/GREEN/QA/límites y adjuntarlo al chat; marcar sólo alcance aprobado, sin promoción/merge/distribución. Depende T013.
- [ ] T015 project-orchestrator con roles responsables: sólo con autorización futura, cumplir SC008/publicación de artefacto/renderer/firma/versión/instalación/smoke/hardware/60FPS y QA de publicación. Pendiente sin bloquear integración aprobada y sin heredar excepciones previas.

## Dependencias y cobertura

T001→T002→T003→T004→T005→T006→T007→T008→T009→T010→T011→T012→T013→T014. T015 es gate futuro separado. Sin [P] por archivos compartidos; un incremento entrega las tres historias, no RED sin GREEN.

FR001/SC001→T004,T008–T010; FR002–004/SC002–003→T005,T008–T010; FR005–006/SC004→T006,T008–T010; FR007–009/SC005–006→T005–T006,T008–T010; FR010/SC007→T004–T014; SC008→T015. Documentación y arte proporcional sin tests artificiales; balance sí requiere playtesting.

## 015-I2 — Dos asaltantes por fusilero (US4)

- [X] T016 docs-writer con project-orchestrator/qa-validator: preparar y revisar enmienda mínima `specs/015-combate-a-distancia-y-recompensas/{spec,plan,tasks}.md` y `contracts/ranged-combat.md`; confirmar A,A,R continuo, tabla por ola y límites antes de implementación. Sin nueva rama/Issue/setup o cambios de recursos.
- [X] T017 [US4] godot-tester: RED válido en `tests/unit/levels/test_combat_ranged_integration.gd` y pruebas de `WaveSpawner` pertinentes para composición global99/66A33R, orden continuo entre olas, inicialR1 independiente, tabla por ola e intervalos/carriles conservados. Cargar recursos actuales y fallar por composición, no por archivo nuevo ausente/parser. Adaptar bajo QA la expectativa I1 de entrada única/todosR para inspeccionar el perfilR de cada ola, conservando sus17 oráculos. Planificar regresión física mixta/pool del contrato sin exigir RED artificial de IA existente. Depende T016.
- [X] T018 qa-validator: validar RED T017 y alcance en `specs/015-combate-a-distancia-y-recompensas/`, separando fallo de composición nueva de regresión existente; no aprobar implementación. Depende T017.
- [X] T019 [US4] dev-godot: crear `resources/enemies/enemigo_asaltante_base.tres` rifle0 con otros stats intactos y autorar intercalación global A,A,R mediante count1/2 en `resources/waves/nivel_montecalvo_oleada_01.tres`…`_10.tres`; reusar entradas inmutables A/count2,R/count1 y parciales sin99 subrecursos; conservar perfilesR/tabla/inicial/tiempos/carriles sin mutación. Sin nueva IA; fuente sólo si defecto real demostrado lo exige. No tocar tests. Depende T018.
- [X] T020 [US4] godot-tester: GREEN T017 y regresión GUT pertinente/completa, import/build de fuente estable; en `tests/unit/levels/test_combat_ranged_integration.gd` y pruebas de enemigo/spawner cubrir física mixta A avanza con blanco/R parado dispara y avanza sin blanco/contacto/pool R→A→R sin restos. Playtesting de balance, único Web final para8813 y APK QA `PR59-S24-prueba2.apk` con package/firma anteriores según plan; declarar entorno/gestos/latencia/hardware no observados, sin nuevas evidencias Git. Depende T019.
- [X] T021 qa-validator: revisar datos, GREEN/regresión/build y playtesting T020 frente a tabla/contrato de `specs/015-combate-a-distancia-y-recompensas/`; aprobar funcionalidad I2 sólo con límites explícitos y sin cerrar T015. Depende T020.
- [X] T022 docs-writer: consolidar comportamiento I2 aprobado en `README.md`, `docs/SPEC.md`, `docs/ARCHITECTURE.md` y specs015 pertinentes, conservando historia I1/013/014, pausa006 y pendientes; sin fuente/tests/tasks o logs nuevos. Depende T021.
- [ ] T023 project-orchestrator con godot-tester: publicar revisión consolidada y verificar CI del head exacto, según `docs/DEVELOPMENT_WORKFLOW.md`; repetir sólo checks invalidados. Sin merge/promoción/distribución automática. Depende T022.
- [ ] T024 qa-validator: contrastar documentación, CI y revisión exacta T023 con `specs/015-combate-a-distancia-y-recompensas/spec.md`; emitir APROBADO PARA INTEGRACIÓN I2 con límites físicos/publicación intactos. Depende T023.
- [ ] T025 project-orchestrator: actualizar mismo PR59 en borrador/Issue58 con Refs#58, trazabilidad y límites conforme `docs/DEVELOPMENT_WORKFLOW.md`; sólo root entrega APK personal autorizado en borrador privado429670877. No marcar T015/SC008 ni promover/fusionar/publicar otros destinos. Depende T024.

Dependencias I2: T016→T017→T018→T019→T020→T021→T022→T023→T024→T025.
FR011–014/SC009–010→T017,T019–T021; SC011→T016–T025. T015 sigue separado.
Sin [P] por archivos compartidos; ningún ID o aprobación I1 se renumera/reabre.
