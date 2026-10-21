# Tasks: Diagnóstico y estabilización del rendimiento

**Feature**: `006-diagnostico-rendimiento` · **Issue**: [#30](https://github.com/Juanpvivas/demons/issues/30) · **I1**: `codex/006-i1-rendimiento`, base `5d50cb0`.
**PR I1 en borrador**: [#31](https://github.com/Juanpvivas/demons/pull/31), `Refs #30`; bases nativas, US2 y publicación pendientes.
**Estado**: instrumento T001–T007, dictamen limitado T009 y documentación/entrega T013–T015 aprobados por QA para integración; I1 entrega instrumento y diagnóstico sin parche, en PR en borrador. T008/base nativa y T010–T012/US2 pendientes; publicación pendiente. Input: [spec](spec.md), [plan](plan.md), [protocolo](contracts/profiling-protocol.md), [quickstart](quickstart.md) y [flujo](../../docs/DEVELOPMENT_WORKFLOW.md).

Spec Kit sólo prepara. Orquestador registra `[X]` tras QA; dev no escribe/ejecuta tests, QA sólo revisa. Nuevos resultados de validación quedan en temporales/CI y en el resumen del PR, no en Git. No fabricar RED de presentación equivalente ni de fuente histórica. El alcance previsto reúne US1 y una primera corrección US2 autorizada; T009 delimita esta entrega al instrumento y diagnóstico, con bases nativas y US2 pendientes. El Issue conserva seguimiento posterior y usa `Refs`, sin publicación.

## Fase 1: Base y contrato invocable

- [X] T001 project-orchestrator: comprobar `AGENTS.md`, `specs/006-diagnostico-rendimiento/checklists/requirements.md`, base/checkout, Issue #30, preparación y matriz; entregar roles, contratos y rama real, conservando T039/T071 pendientes.
- [X] T002 dev-godot: crear sólo esqueleto invocable de `tools/performance/probe.gd` según API del protocolo, sin cálculos/inventario/validación ni integración productiva; QA revisa el alcance mínimo; depende de T001 y preparación aprobada.

## Fase 2: US1 — Diagnóstico reproducible (P1)

**Criterio independiente**: instrumento valida series/población/condiciones y permite repetir una base honesta sin cambiar el juego.

- [X] T003 [US1] godot-tester: escribir y ejecutar RED semántico en `tests/unit/systems/test_performance_probe.gd`: números/percentiles conocidos y reloj real, vacío/regresión/duración corta, oráculo incompatible y condiciones observadas distintas/ausentes contra expected en inicio/final/comparación, lectura anidada/activo oculto/inactivo/queued sin mutación, reinicio/cierre y comparación que permite distinta revisión pero rechaza escenario/renderer/viewport/cap/config/cohorte distintos; depende de T002, sin aceptar parser/import como RED.
- [X] T004 [US1] qa-validator: revisar prueba/contrato/esqueleto en `tools/performance/probe.gd` y `tests/unit/systems/test_performance_probe.gd`; aprobar sólo RED válido, sin entregar instrumento ni optimización; depende de T003.
- [X] T005 [US1] dev-godot: implementar el instrumento optativo mínimo en `tools/performance/probe.gd`, sin IO por frame, autoridad jugable, autoload ni referencia desde escenas normales; depende de T004 aprobado.
- [X] T006 [US1] godot-tester: verificar GREEN de `tests/unit/systems/test_performance_probe.gd`, regresión pertinente y neutralidad de la lectura con nodos reales; informar modificaciones propias de test sin debilitar contrato; depende de T005.
- [X] T007 [US1] qa-validator: validar instrumento y RED/GREEN frente al `contracts/profiling-protocol.md`, incluidos invalidación/compatibilidad y límites del observador; habilitar su uso sin aprobar aún diagnóstico o parche; depende de T006.
- [ ] T008 [US1] godot-tester: ejecutar nueva base `5d50cb0` y diagnóstico del `contracts/profiling-protocol.md` en Web de computador/APK/app iPad disponibles, con tres repeticiones por condición y oráculos independientes. Perfilar o aislar un factor para confirmar/descartar coste del shader; separar render fijo, producción y pacing/foco iOS, sin atribuir GPU/Self desde TIME_PROCESS. Collectors/ablaciones/resultados sólo temporales; depende de T007.
- [X] T009 [US1] qa-validator: revisar muestras/cohortes/contexto y atribución de T008 contra `contracts/profiling-protocol.md`; emitir dictamen causal y alcance exacto del primer parche autorizado, o mantener US2 pendiente si no hay señal válida; depende de T008.

## Fase 3: US2 — Primera estabilización verificada (P2)

**Criterio independiente**: parche mínimo reduce un coste confirmado, conserva lectura/partida y no oculta empeoramientos. La candidata de presentación equivalente usa comparación visual y perfilado, sin tests artificiales de texto.

- [ ] T010 [US2] dev-godot: aplicar en `assets/sprites/units/monte_calvo/soldado_readability.gdshader` sólo el ahorro autorizado en T009 (candidata: omitir cuatro vecinos cuando alfa central es cero conservando RGBA/bordes/antialias); sin discard, cambios de arte, reglas, física, resolución, pulso o presets. No implementar sin causa aprobada; depende de T009.
- [ ] T011 [US2] godot-tester: repetir comparación base/candidata del protocolo y equivalencia visual de poses/tintes/flips/caída, entrada/recarga/recogida y recorrido afectados según `quickstart.md`; verificar importación, exportaciones y suite completa `tests/unit/` mediante `tools/ci/run_gut.py` o CI exacta vigente. Evaluar dispersión y perturbación, restaurar app normal única/datos y limpiar propios procesos; depende de T010.
- [ ] T012 [US2] qa-validator: revisar fuente, mediciones nuevas y regresiones T011 contra FR-001–010/SC-001–006; emitir APROBADO PARA INTEGRACIÓN sólo con coste reducido y neutralidad acreditados, declarando riesgos y publicación pendiente; depende de T011.

## Fase final: Documentación y entrega

- [X] T013 docs-writer: consolidar alcance aprobado y guía útil en `docs/SPEC.md`, `docs/ARCHITECTURE.md`, `README.md` cuando corresponda y documentos006, sin volcar registros; reportar metadatos postmerge004 desactualizados al orquestador; depende de T012 aprobado si se entrega corrección, o de T009 con dictamen explícito sin parche para entregar sólo instrumento y diagnóstico limitado.
- [X] T014 qa-validator: revisar documentación T013 y vigencia de fuente/verificaciones en `specs/006-diagnostico-rendimiento/`, sin exigir repetir evidencia no invalidada; depende de T013.
- [X] T015 project-orchestrator: registrar aprobaciones en `specs/006-diagnostico-rendimiento/tasks.md`, alinear sólo encabezados postmerge del seguimiento004, comprobar diff/base/tamaño/CI/exportación, publicar rama y crear PR en borrador `Refs #30`. Conservar Issue #30 abierto, T039/T071 pendientes, sin promover/fusionar/distribuir; depende de T014 aprobado.

## Dependencias y estrategia

Cadena con corrección: T001→T002→T003→T004→T005→T006→T007→T008→T009→T010→T011→T012→T013→T014→T015. Si T009 no autoriza un parche, la entrega limitada sigue T009→T013→T014→T015; conserva pendientes las bases no acreditadas de T008 y T010–T012, sin presentar US1/US2 ni SC-001 nativos como completos. RED no depende de implementación. No hay `[P]`: instrumento, motor y checkout compartidos; investigación de sólo lectura puede avanzar en paralelo.

Entregar un incremento coherente con QA y documentación. El resultado previsto es US1+primer parche US2; si T009 no autoriza un parche, entregar sólo instrumento y diagnóstico en el alcance aprobado, con las bases no acreditadas y US2 pendientes: no inventar una optimización ni marcarla entregada. Otros cuellos de botella y publicación quedan fuera de I1; los requisitos de 004/T039 y 005/T071 conservan sus propios artefactos/hardware y aprobación humana. La orientación de 400 líneas/20 archivos se revisa al delimitar el diff, sin fragmentar RED/GREEN.
