# Tasks: Sonidos de combate

**Input**: [spec.md](spec.md), [plan.md](plan.md), [contrato](contracts/combat-audio.md), [datos](data-model.md), [quickstart](quickstart.md).  
**Entrega**: 014-I1 integrado en `main` por [PR #56 fusionado](https://github.com/Juanpvivas/demons/pull/56) (`45cd83a`), cinco cues/nueve WAV; rama de implementación `codex/014-sonidos-combate`, base main77be629; [Issue #55](https://github.com/Juanpvivas/demons/issues/55) abierto por publicación T014.
**Flujo**: [roles/TDD](../../docs/DEVELOPMENT_WORKFLOW.md); Spec Kit prepara, agentes ejecutan. Sólo orquestador marca [X] tras QA. Sin evidencias nuevas Git.

## Fase 1: Preparación y contrato neutral

- [X] T001 project-orchestrator con qa-validator: revisar preparación `specs/014-sonidos-combate/`, cinco cues, exclamación breve+caída autorizada, eventos reales/reciclado/resultado/limpieza y gates. Aprobar antes de modificar código.
- [X] T002 dev-godot: declarar únicamente `scenes/audio/combat_audio.gd` y `resources/schemas/combat_audio_profile.gd` importables según contrato, con firmas/arrays/configuración neutras; sin pool, señales conectadas, reproducción, recurso final o cambios de nivel/actores/Managers. Depende T001.
- [X] T003 godot-tester con qa-validator: comprobar carga/importación de T002 y neutralidad contra base; QA emite veredicto de setup sin aprobar comportamiento. Usar harness GUT vigente; error de entorno/parser no vale RED. Depende T002.

## Fase 2: RED de hechos y ciclo de sesión

- [X] T004 [US1] godot-tester: escribir/ejecutar RED válido en `tests/unit/systems/test_combat_audio.gd` y `tests/unit/levels/test_combat_audio_integration.gd`: tiro confirmado/última bala frente a rechazo/recarga; baja real de ambos bandos una vez frente a hit no letal/cleanup/despawn, registro doble/reciclado, resultado real único frente a menú/retry y baja final+victoria ambas aceptadas. Usar actores/Managers reales o fixtures justificados, WAV en memoria y aserciones, sin implementación. Depende T003.
- [X] T005 [US2] godot-tester: añadir/ejecutar RED en los mismos tests para capacidad fija/resultado reservado, RNG jugable intacto, pausa/foco sin replay atrasado y callbacks viejos sin efecto. Cubrir routing exclusivo de9players a GameplaySFX con playback_type STREAM (Sample Web omite AudioEffects) y cierre idempotente/aislado sin mutear/borrar bus, reencaminar aMaster o alterar intro/otra instancia. Getters cuentan total combate+terminal. No cambiar stubs aprobados ni provocar parser/import roto; usar aserciones seguras. Ganancias/picos/propiedades numéricas limiter se verifican proporcionalmente T008, sin tests espejo de arte. Depende T004.
- [X] T006 qa-validator: revisar calidad/controles positivos y RED T004–T005 contra contrato; aprobar sólo fallo esperado por comportamiento ausente, no parser/import o audio sin dispositivo. La percepción de medios no requiere RED artificial. Depende T005.

## Fase 3: Implementación completa y GREEN

- [X] T007 [US1] dev-godot: implementar cinco cues en `scenes/audio/combat_audio.gd`, perfil/`resources/audio/combat_audio_profile.tres`, layout estático `default_bus_layout.tres` con GameplaySFX/HardLimiter según contrato y composición nivel/spawner; observar señales confirmadas sin alterar emisores/mecánicas. Integrar nueve WAV/SOURCES/licencias; pool8+1, rutas exclusivas aSFX y ganancias de producción nuevas, RNG local, dedupe/limpieza aislada sin modificar Master/audio013. Conservar voces admitidas tiro/baja final antes de victoria. Sin tests, balance/presets/version/publicación. Depende T006; aprobación exige T008–T009.
- [X] T008 [US1] godot-tester: confirmar GREEN T004–T005, regresión/suite completa, import/build/export/CI y quickstart con cinco eventos/variantes, resultado y limpieza aislada. Verificar medios/mezcla: bus/rutas9players STREAM/limiter/perfil y techo en runtime/captura disponible sin tocar Master/intro; preview Web y latencia Stream observable, sin extrapolar nativo o modificar singlethread/presets. Escucha si disponible; declarar destinos/audio/renderer/medición no observados y fixture/producción. Comparar coste acotado, sin campaña de rendimiento ni reabrir006. Depende T007.
- [X] T009 qa-validator: contrastar spec/código/medios/licencias, RED/GREEN y verificación disponible T008, aprobar funcionalidad sólo con evidencia suficiente y límites de audición/build/dispositivo explícitos. No certificar publicación o hardware ni atribuir escucha no realizada. Depende T008.

## Fase final: Documentación, CI e integración

- [X] T010 docs-writer: consolidar sólo comportamiento aprobado en `README.md`, `docs/SPEC.md`, `docs/ARCHITECTURE.md` y specs014 pertinentes; conservar tono, audio013 definitivo e historia, pausa006 y pendientes004/005/013. No tareas/fuente/tests ni logs/evidencias nuevos. Depende T009.
- [X] T011 project-orchestrator con godot-tester: revisar diff/commits por resultado, publicar revisión consolidada de rama y comprobar CI de head exacto; reutilizar verificaciones válidas y repetir sólo invalidadas. Sin promoción/merge/distribución. Depende T010.
- [X] T012 qa-validator: revisar documentación/CI/revisión exacta T011 y emitir APROBADO PARA INTEGRACIÓN sólo con fuente, GREEN/regresión, medios/build suficientes y límites explícitos; T014 sigue pendiente de publicación. Depende T011.
- [X] T013 project-orchestrator: consolidar Issue único y PR borrador 014-I1 con `Refs #<issue>`, trazabilidad RED/GREEN/QA y límites, adjuntar PR; marcar sólo alcance aprobado, sin promoción/merge/distribución. Depende T012.
- [ ] T014 project-orchestrator con roles responsables: sólo con autorización futura de publicación, verificar SC007 (artefacto/renderer/firma/versión/instalación/smoke/hardware/60FPS y QA de publicación). Permanece pendiente sin bloquear integración funcional aprobada ni heredar excepciones beta.

## Dependencias y cobertura

T001→T002→T003→T004→T005→T006→T007→T008→T009→T010→T011→T012→T013. T014 es gate posterior autorizado por separado. Sin [P]: historias comparten controlador/fixtures; no paralelizar RED y desarrollo. US1 y US2 son verificables por separado, ambos integran este incremento completo de cinco cues.

FR001–003/SC001–002→T004,T007–T009; FR004/SC005→T007–T009; FR005/SC003→T005,T007–T009; FR006–008/SC004→T005,T007–T009; SC006→T003–T013; SC007→T014. Arte/medios sólo verificación proporcional, sin pruebas artificiales que repliquen archivos.
