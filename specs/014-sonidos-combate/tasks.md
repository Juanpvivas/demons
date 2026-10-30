# Tasks: Sonidos de combate

**Input**: [spec.md](spec.md), [plan.md](plan.md), [contrato](contracts/combat-audio.md), [datos](data-model.md), [quickstart](quickstart.md).  
**Entrega**: 014-I1 completo, cinco cues/nueve WAV; rama `codex/014-sonidos-combate`, base main77be629; [Issue #55](https://github.com/Juanpvivas/demons/issues/55), PR por orquestador.
**Flujo**: [roles/TDD](../../docs/DEVELOPMENT_WORKFLOW.md); Spec Kit prepara, agentes ejecutan. Sólo orquestador marca [X] tras QA. Sin evidencias nuevas Git.

## Fase 1: Preparación y contrato neutral

- [X] T001 project-orchestrator con qa-validator: revisar preparación `specs/014-sonidos-combate/`, cinco cues, exclamación breve+caída autorizada, eventos reales/reciclado/resultado/limpieza y gates. Aprobar antes de modificar código.
- [ ] T002 dev-godot: declarar únicamente `scenes/audio/combat_audio.gd` y `resources/schemas/combat_audio_profile.gd` importables según contrato, con firmas/arrays/configuración neutras; sin pool, señales conectadas, reproducción, recurso final o cambios de nivel/actores/Managers. Depende T001.
- [ ] T003 godot-tester con qa-validator: comprobar carga/importación de T002 y neutralidad contra base; QA emite veredicto de setup sin aprobar comportamiento. Usar harness GUT vigente; error de entorno/parser no vale RED. Depende T002.

## Fase 2: RED de hechos y ciclo de sesión

- [ ] T004 [US1] godot-tester: escribir/ejecutar RED válido en `tests/unit/systems/test_combat_audio.gd` y `tests/unit/levels/test_combat_audio_integration.gd`: tiro confirmado/última bala frente a rechazo/recarga; baja real de ambos bandos una vez frente a hit no letal/cleanup/despawn, registro doble/reciclado, resultado real único frente a menú/retry y baja final+victoria ambas aceptadas. Usar actores/Managers reales o fixtures justificados, WAV en memoria y aserciones, sin implementación. Depende T003.
- [ ] T005 [US2] godot-tester: añadir/ejecutar RED en los mismos tests para capacidad fija/resultado reservado sin colas ilimitadas, RNG jugable intacto, pausa/foco sin replay atrasado, cierre idempotente y callbacks/generaciones de actor/voz/partida viejos sin efecto. Conservar audio013/menú/retry en regresión. Depende T004.
- [ ] T006 qa-validator: revisar calidad/controles positivos y RED T004–T005 contra contrato; aprobar sólo fallo esperado por comportamiento ausente, no parser/import o audio sin dispositivo. La percepción de medios no requiere RED artificial. Depende T005.

## Fase 3: Implementación completa y GREEN

- [ ] T007 [US1] dev-godot: implementar cinco cues en `scenes/audio/combat_audio.gd`, perfil Resource y `resources/audio/combat_audio_profile.tres`, composición en `scenes/levels/nivel_monte_calvo.gd`/`wave_spawner.gd`; observar señales confirmadas existentes sin alterar emisores/mecánicas. Integrar nueve WAV de root en `assets/audio/combat/` con SOURCES/licencias portables. Pool finito, resultado reservado, RNG local, dedupe por activación y cierre/pausa/foco; conservar voces ya admitidas de tiro/baja final antes de victoria. Sin pruebas, audio013, balance/presets/version/publicación. Depende T006; aprobación exige T008–T009.
- [ ] T008 [US1] godot-tester: confirmar GREEN T004–T005, regresión pertinente y suite GUT completa, import/build/export/CI aplicables y quickstart con cinco eventos/variantes, resultado y limpieza de sesión; verificar medios proporcionalmente, preview/escucha si disponible y declarar destinos/audio/renderer no observados, fixture/producción y límites. Comparar coste disponible acotado, sin campaña de rendimiento ni reabrir006. Depende T007.
- [ ] T009 qa-validator: contrastar spec/código/medios/licencias, RED/GREEN y verificación disponible T008, aprobar funcionalidad sólo con evidencia suficiente y límites de audición/build/dispositivo explícitos. No certificar publicación o hardware ni atribuir escucha no realizada. Depende T008.

## Fase final: Documentación, CI e integración

- [ ] T010 docs-writer: consolidar sólo comportamiento aprobado en `README.md`, `docs/SPEC.md`, `docs/ARCHITECTURE.md` y specs014 pertinentes; conservar tono, audio013 definitivo e historia, pausa006 y pendientes004/005/013. No tareas/fuente/tests ni logs/evidencias nuevos. Depende T009.
- [ ] T011 project-orchestrator con godot-tester: revisar diff/commits por resultado, publicar revisión consolidada de rama y comprobar CI de head exacto; reutilizar verificaciones válidas y repetir sólo invalidadas. Sin promoción/merge/distribución. Depende T010.
- [ ] T012 qa-validator: revisar documentación/CI/revisión exacta T011 y emitir APROBADO PARA INTEGRACIÓN sólo con fuente, GREEN/regresión, medios/build suficientes y límites explícitos; T014 sigue pendiente de publicación. Depende T011.
- [ ] T013 project-orchestrator: consolidar Issue único y PR borrador 014-I1 con `Refs #<issue>`, trazabilidad RED/GREEN/QA y límites, adjuntar PR; marcar sólo alcance aprobado, sin promoción/merge/distribución. Depende T012.
- [ ] T014 project-orchestrator con roles responsables: sólo con autorización futura de publicación, verificar SC007 (artefacto/renderer/firma/versión/instalación/smoke/hardware/60FPS y QA de publicación). Permanece pendiente sin bloquear integración funcional aprobada ni heredar excepciones beta.

## Dependencias y cobertura

T001→T002→T003→T004→T005→T006→T007→T008→T009→T010→T011→T012→T013. T014 es gate posterior autorizado por separado. Sin [P]: historias comparten controlador/fixtures; no paralelizar RED y desarrollo. US1 y US2 son verificables por separado, ambos integran este incremento completo de cinco cues.

FR001–003/SC001–002→T004,T007–T009; FR004/SC005→T007–T009; FR005/SC003→T005,T007–T009; FR006–008/SC004→T005,T007–T009; SC006→T003–T013; SC007→T014. Arte/medios sólo verificación proporcional, sin pruebas artificiales que repliquen archivos.
