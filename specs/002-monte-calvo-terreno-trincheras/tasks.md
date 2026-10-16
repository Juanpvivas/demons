---
description: "Primera iteración visual de Monte Calvo: terreno, conservación de mecánicas y trincheras decorativas"
---

# Tasks: Monte Calvo — terreno y trincheras, iteración visual 1

**Feature ID**: `002-monte-calvo-terreno-trincheras`
**Input**: [spec.md](spec.md), [plan.md](plan.md), [research.md](research.md), [data-model.md](data-model.md), [contrato](contracts/visual-boundary.md), [referencia](references/visual-reference.md) y [validación](quickstart.md).
**Status**: ejecución iniciada por agentes; los checkboxes se actualizan solo tras QA y no certifican verificaciones pendientes.
**Execution Branch**: `codex/002-monte-calvo-terreno-trincheras`, preparada por el orquestador.
**Issue**: [#13](https://github.com/Juanpvivas/demons/issues/13).
**Dependency**: PR #12 (preset/flujo de agentes) fusionado, verificado el 2026-10-16; esta rama conserva su base y no modifica ese PR.

## Formato y aprobación

El [flujo compartido](../../docs/DEVELOPMENT_WORKFLOW.md) gobierna ejecución y evidencia. Cada tarea identifica propietario, ruta, dependencias y verificación. `[P]` señala únicamente archivos independientes con prerrequisitos satisfechos; no autoriza editar simultáneamente la misma escena. Solo el orquestador registra `[X]` tras `APROBADO` de QA.

El alcance artístico es estático: revisión visual/de integración y regresión existente, sin RED artificial ni pruebas que solo enumeren sprites. La adenda de preparación del 2026-10-16 delimita exclusivamente el arreglo previo de I4 en T019–T022, con preparación aprobada por QA; la implementación sigue pendiente de RED y su veredicto. No cambiar scripts, costos, input o geometría bajo las tareas artísticas; conservar los 18 IDs, checkboxes y evidencias originales.

## Fase 1: Preparación y prerrequisitos

- [X] T001 godot-tester: registrar la línea base de `scenes/levels/Nivel_MonteCalvo.tscn`, `project.godot`, scripts/Resources y `tests/unit/` según `quickstart.md`; capturar estados y las cuatro configuraciones disponibles, ejecutar la regresión y smoke previos y documentar coordenadas/dispositivos/fallos preexistentes en `specs/002-monte-calvo-terreno-trincheras/evidence/baseline.md`; sin modificar gameplay; QA revisa evidencia antes de avanzar.
- [X] T002 docs-writer, autoría: consolidar la guía de producción en `specs/002-monte-calvo-terreno-trincheras/references/production-brief.md` con `references/visual-reference.md`, mediciones y máscara de protección derivadas de T001, piezas/dimensiones previstas y criterios de materiales/contraste; no ampliar alcance; depende de T001 aprobada y pasa por QA antes de producir arte.

## Fase 2: Base visual aislada

- [X] T003 [P] dev-godot: crear la estructura estática de `scenes/levels/MonteCalvoVisual.tscn` según `contracts/visual-boundary.md`, con transform identidad, z negativo y grupos FondoMontanas/Suelo/Bordes/Trincheras; sin integrar todavía el nivel, scripts, input o física; depende de T002 aprobada; reportar propiedades para T004.
- [X] T004 godot-tester: inspeccionar y cargar la escena aislada `scenes/levels/MonteCalvoVisual.tscn` para comprobar importación, transformación, capas y ausencia de nodos de comportamiento; registrar en `specs/002-monte-calvo-terreno-trincheras/evidence/visual-structure.md`; depende de T003; QA valida el contrato, sin exigir RED.

## Fase 3: US1 — Terreno ilustrado (P1)

**Objetivo**: suelo y horizonte legibles como primer incremento. **Criterio independiente**: escenarios US1 y rasgos aplicables de SC-001, sin necesitar trincheras.

- [X] T005 [P] [US1] dev-godot: producir `assets/sprites/levels/monte_calvo/terreno.png` y `montanas.png` con sus `.import`, siguiendo la guía T002 y la referencia; sin personajes/UI horneados, con suelo continuo y centro de bajo ruido; depende solo de T002 aprobada y puede avanzar junto a T003; el tester/QA revisan materialidad, escala, transparencia y lectura antes de integrar.
- [X] T006 [US1] dev-godot: componer suelo y montañas en `scenes/levels/MonteCalvoVisual.tscn` e instanciarla en `scenes/levels/Nivel_MonteCalvo.tscn`; conservar íntegros nodos, transformaciones y propiedades anteriores; depende de T004 y T005 aprobadas; reportar diff visual y contrato para verificación del tester.
- [X] T007 [US1] godot-tester: comparar capturas antes/después del terreno en `specs/002-monte-calvo-terreno-trincheras/evidence/us1.md`, cubriendo US1/AC1–3 y matriz V1–V2 de `quickstart.md`; comprobar lectura de placeholders/pickups, suelo continuo y ausencia de carriles/casillas nuevas; depende de T006; entregar evidencia a QA en T009, sin presentar captura como prueba de input.

## Fase 4: US2 — Conservar las mecánicas (P1, condición de cada incremento)

**Objetivo**: comprobar el terreno integrado sin cambiar reglas. **Criterio independiente**: resultados equivalentes de la matriz I1–I9 y contrato, más evidencia de entrada real separada de headless.

- [ ] T008 [US2] godot-tester: ejecutar la regresión existente pertinente de `tests/unit/levels/test_nivel_montecalvo.gd`, `test_wave_spawner.gd` y sistemas/unidades aplicables, además de los escenarios I1–I9 de `quickstart.md` con ratón/toque en V1 y V3–V4 (iOS Simulator autorizado, hardware iOS no probado); registrar esperado/observado y limitaciones en `specs/002-monte-calvo-terreno-trincheras/evidence/us2.md`; depende de T007 y T022 aprobadas; comparar arte con la misma corrección I4 y no añadir UI o alterar tests para compensar fallos del arte.
- [ ] T009 [US2] qa-validator: revisar de forma independiente `specs/002-monte-calvo-terreno-trincheras/contracts/visual-boundary.md`, el diff de `scenes/levels/Nivel_MonteCalvo.tscn` y los reportes T004/T007/T008/T022; aprobar o devolver terreno y conservación de mecánicas con causas concretas; depende de T008 y T022 aprobadas; solo lectura y veredicto, sin modificar el checkout ni marcar tareas.

### Adenda US2 — defecto previo I4, separada del arte (preparación aprobada 2026-10-16)

**Gate de alcance**: QA revisa primero esta adenda. Se fundamenta en I4 ya exigida y en la corrección TDD aprobada de 003; no se presenta como autorización humana explícita del backport. La evidencia RED nativa actual puede adoptarse en T019 sin repetir ejecuciones válidas ni reconstruir RED histórico. Referencias y hashes: [plan](plan.md#adenda-de-preparación--2026-10-16) y [contrato](contracts/visual-boundary.md).

- [X] T019 [US2] godot-tester: incorporar sin debilitar las seis pruebas de `4a2915c` en `tests/unit/levels/test_pickup_input_routing.gd` y su UID; conservar/adoptar el diagnóstico RED nativo previo al cambio en copias sin/con arte de 002, con comandos, logs, hashes y esperado/observado en `specs/002-monte-calvo-terreno-trincheras/evidence/t019-red.md`; depende del contrato disponible y QA de alcance de la adenda, nunca de T020; QA debe aprobar el fallo de I4 antes de desarrollo. Los cuatro controles que ya pasan son regresión, no RED fabricado.
- [X] T020 [US2] dev-godot: aplicar únicamente `scenes/levels/nivel_monte_calvo.gd` aprobado en 003/`4a2915c`, según hash del contrato, para ceder al picking si hay pickup antes de desplegar y conservar el despliegue por mouse normal/emulado sin pickup; depende de T019 aprobada; no modificar pruebas, ejecutarlas ni copiar Web/configuración/datos/balance/geometría/arte; reportar diff para T021, con aceptación pendiente de GREEN y T022.
- [X] T021 [US2] godot-tester: verificar GREEN de las mismas seis pruebas sin cambiar expectativas y regresión completa de `tests/unit/`, importación y matriz nativa pertinente de `quickstart.md`; registrar comandos, resultados reales, hashes y comparación sin/con arte con el mismo script corregido en `specs/002-monte-calvo-terreno-trincheras/evidence/t021-green.md`; depende de T020; separar los resultados automatizados de ratón PC/toque Android físico/gesto iOS Simulator y conservar pendientes de la matriz T008.
- [X] T022 [US2] qa-validator: revisar RED T019, diff exclusivo T020, GREEN/regresión T021 y manifests contra `specs/002-monte-calvo-terreno-trincheras/contracts/visual-boundary.md`; depende de T021; confirmar que la única diferencia de comportamiento histórico es recoger sin despliegue adicional, sin introducir regresión normal/emulada ni atribuir toque físico a GUT; emitir veredicto de ciclo, sin modificar checkout ni marcar tareas. Su aprobación habilita continuar la aceptación T008/T009, no cierra la matriz ni la feature.

## Fase 5: US3 — Trincheras decorativas (P2)

**Objetivo**: añadir tierra excavada, madera y sacos sin cobertura o colisión. **Criterio independiente**: escenarios US3 y comparación con/sin capa de trincheras sobre el terreno aprobado.

- [ ] T010 [US3] dev-godot: producir `assets/sprites/levels/monte_calvo/trincheras_atlas.png` y su `.import`, con piezas de excavación, madera, sacos y marco de rocas/hierba seca según T002 y terreno aprobado; registrar regiones de atlas en la escena al integrarlas; depende de T009 aprobada; tester/QA revisan coherencia artística antes de integrar, sin generar personajes, bandera, carteles o efectos.
- [ ] T011 [US3] dev-godot: distribuir las piezas de T010 en `scenes/levels/MonteCalvoVisual.tscn`, adaptando solo el arte a posiciones actuales y manteniéndolo detrás de actores/pickups; depende de T010 aprobada; no añadir física, selección, restricciones de celda ni modificar `Nivel_MonteCalvo.tscn` fuera de la instancia visual aprobada.
- [ ] T012 [US3] godot-tester: repetir las comprobaciones afectadas de lectura, costuras, recorte y picking de `quickstart.md` con trincheras en V1–V4 e I1–I5/I9; registrar en `specs/002-monte-calvo-terreno-trincheras/evidence/us3.md` comparaciones con/sin decoración y referencia; depende de T011; QA revisa US3/AC1–3 y SC-001/002/003/005 antes del cierre.

## Fase final: Regresión, evidencia y cierre

- [ ] T013 godot-tester: ejecutar importación limpia y suite GUT completa de `tests/unit/` para el estado final según `specs/002-monte-calvo-terreno-trincheras/quickstart.md`; guardar comandos, códigos de retorno, resultados y comparación de archivos protegidos en `evidence/regression.md`; depende de T012 aprobada; no reparar lógica ni fabricar RED, y devolver cualquier regresión atribuible a desarrollo.
- [ ] T014 godot-tester: ejecutar una partida completa y los escenarios separados de victoria/derrota de `specs/002-monte-calvo-terreno-trincheras/quickstart.md`; registrar resultados reales en `evidence/smoke.md`, distinguiendo señales/estado existentes de pantallas o controles que el nivel no tiene; depende de T013; una carencia previa se reporta y no se marca como aprobada.
- [ ] T015 godot-tester: medir antes/después en Android de referencia y completar la matriz PC/iOS de `specs/002-monte-calvo-terreno-trincheras/quickstart.md`; registrar dispositivo, resolución efectiva, FPS/tiempos de frame, memoria de texturas, carga y limitaciones en `evidence/performance.md`; depende de T014; no publicar builds ni cambiar versión/firma/exportaciones, y no declarar 60 FPS sin medición.
- [ ] T016 qa-validator: auditar `specs/002-monte-calvo-terreno-trincheras/spec.md`, `contracts/visual-boundary.md`, referencia, diff y reportes T012–T015 contra FR-001–013 y SC-001–007; depende de T015; emitir veredicto de entrega visual sin escribir archivos ni marcar tareas, dejando explícitos cualquier dispositivo o criterio pendiente.
- [ ] T017 docs-writer, consolidación: documentar únicamente el arte y estructura aprobados en `docs/ARCHITECTURE.md` y el estado visual aplicable en `docs/SPEC.md`, enlazando evidencia de `specs/002-monte-calvo-terreno-trincheras/`; depende de T016 aprobada; no graduar nuevas mecánicas ni atribuir pruebas históricas no realizadas.
- [ ] T018 qa-validator: revisar la consolidación en `docs/ARCHITECTURE.md`, `docs/SPEC.md` y evidencia final de `specs/002-monte-calvo-terreno-trincheras/`; depende de T017; confirmar que el estado de juego coincide con el verificado en T013–T015 y que esas evidencias siguen válidas, o devolver al tester solo las comprobaciones invalidadas; emitir veredicto sin modificar checkout o tareas.

## Dependencias y ejecución

```text
T001 → T002 → T003 → T004 ─┐
           └→ T005 ──────┴→ T006 → T007 ────────────┐
QA adenda → T019 RED → QA RED → T020 → T021 → T022 ┴→ T008 → T009
                                                            └→ T010 → T011 → T012
                                                                           └→ T013 → T014 → T015 → T016 → T017 → T018
```

- T003 y T005 pueden avanzar en paralelo tras T002: escena nueva frente a imágenes en archivos distintos. No ejecutar dos editores/importadores concurrentes sobre el mismo checkout; el orquestador serializa la importación.
- El resto mantiene orden explícito. T006 y T011 editan la misma escena: nunca se ejecutan en paralelo.
- T004/T007/T008/T012/T013/T014/T015 pertenecen al tester; el desarrollador no ejecuta pruebas. T009/T016/T018 son QA en solo lectura; el orquestador conserva los veredictos y el estado de tareas.
- El arte no cambia lógica. La única excepción propuesta I4 sigue T019 → T020 → T021 → T022, sin paralelizar ese ciclo ni inventar TDD retroactivo. Para otra corrección se requiere preparar un alcance distinto antes de desarrollarla.

## Trazabilidad

| Requisito / resultado | Tareas principales |
|---|---|
| FR-001/002; US1; SC-001 | T002, T005, T006, T007 |
| FR-003; US3; SC-001/002 | T010, T011, T012 |
| FR-004; SC-002/003 | T003, T004, T007, T008, T009, T011, T012 |
| FR-005–009; US2; SC-003/004/006 | T001, T004, T008, T009, T013, T014, T016; excepción I4: T019–T022 |
| FR-010; SC-005 | T001, T002, T007, T008, T012, T015; V4 iOS Simulator según adenda |
| FR-011 | T003, T004, T011, T016 |
| FR-012; evidencia de SC-001–007 | T001, T007, T008, T012, T013, T014, T015, T016, T017, T018 |
| FR-013; SC-007 | T001, T015, T016 |

## Estrategia de entrega

MVP visual: T001–T009, terreno US1 con conservación US2 aprobada. Iteración completa: añadir trincheras US3 y terminar T010–T018. No detener la iteración completa dando por entregado solo el MVP.

La adenda añade T019–T022 sin renumerar las 18 tareas originales. El arreglo separado debe quedar aprobado antes de aceptar T008/T009. El diagnóstico preimplementación actual no modifica los resultados históricos ni cuenta como corrección ya entregada; V4 admite simulador y SC-007 mantiene Android físico y su gate constitucional.

Al iniciar ejecución, el orquestador elegirá/reutilizará rama e Issue de esta feature y comprobará los gates vigentes. Al cerrar todas las tareas aprobadas coordinará publicación y PR en borrador según el flujo. Esa coordinación futura no se ejecuta desde esta preparación Spec Kit, ni reutiliza el Issue/PR del preset como si perteneciera a Monte Calvo.

## Registro de aprobación de ejecución

- T001 — `APROBADO` por `qa-validator` el 2026-10-15: línea base PC e inventario, 183/183 pruebas y 97/97 archivos intactos. Evidencia: [baseline.md](evidence/baseline.md). No aprueba todavía toque, móviles, rendimiento ni la integración visual.
- T002 — `APROBADO` por `qa-validator` el 2026-10-15: [guía de producción](references/production-brief.md), composición y máscara derivadas de T001. Habilita T003/T005; no certifica arte ni interacción todavía.
- T003/T004 — `APROBADO` por `qa-validator` el 2026-10-15: estructura estática aislada y carga correcta; cinco Node2D, identidad y capas negativas. [Verificación](evidence/visual-structure.md). No acredita aún integración ni entrada.
- T005 — `APROBADO` por `qa-validator` el 2026-10-15: PNG e importación/carga correctas, **solo para hoja única sin repetición**; el ensayo tileable mostró juntas. T006 debe resolver cobertura y cielo estático, y T007 comprobar composición/contraste. [Evidencia](evidence/visual-structure.md).

### Secuencia de producción en curso

El orquestador adelanta la producción estática T010/T011 como trabajo en curso para completar el arte solicitado, tras revisión técnica favorable de la estructura del terreno. QA no encuentra objeción de alcance; esta anticipación no equivale a aprobar T008/T009 ni su dependencia de aceptación. Antes de editar la composición para T011, el tester congela hash/copia y capturas US1 sin trincheras. T008/T009 y las tareas dependientes permanecen sin marcar mientras falten los criterios completos; los requisitos FR/SC, el cierre y la publicación conservan sus gates originales.
- T006/T007 — `APROBADO` por `qa-validator` el 2026-10-15: integración estática, contrato preservado y comparación visual PC V1/V2 favorable. [US1](evidence/us1.md); 161/161 pruebas pertinentes en [US2](evidence/us2.md). La matriz de entrada y la aceptación móvil/global de T008/T009 siguen pendientes.
- T010 — recurso aislado `APROBADO` por `qa-validator` como WIP anticipado: [atlas](evidence/atlas.md), importación/carga/render correctos y regiones completas. Habilita composición estática de trabajo T011; checkbox pendiente de dependencia y aceptación completas.
- T011 — `APROBADO` técnico/visual por `qa-validator` para PC V1/V2 observado, como WIP anticipado: ocho capturas finales, contrato intacto y suite final 183/183. La revisión no detecta corrección visual bloqueante; dependencia/checkbox y aceptación global continúan pendientes.
- Dictamen final de esta ejecución — `APROBADO` parcial por `qa-validator` para la implementación visual WIP observada en PC V1/V2 y Android físico, sin correcciones visuales bloqueantes. [Estado y evidencia](evidence/implementation-status.md): 183/183 pruebas, importación desde cero correcta, contrato preservado y prueba humana parcial antes/después. No habilita nuevos `[X]`: quedan matriz completa de entrada/picking, iOS físico, carga/VRAM y rendimiento sostenido. T008/T009 y T012–T018 mantienen sus gates; no hay consolidación definitiva ni publicación.

### Preparación de reanudación — 2026-10-16

Preparación documental aprobada por QA: simulador iOS autorizado para V4, hardware iOS no probado; Xiaomi físico para rendimiento; excepción I4 y tareas T019–T022 separadas. Conserva el registro histórico anterior: sus menciones a iOS físico describen la limitación de aquella ejecución, no invalidan la nueva vía V4. No se marca ninguna tarea ni se declara aprobado el arreglo nativo desde esta preparación.

- 2026-10-16: se retoma002 por prioridad explícita de la persona, conservando
  003 y su PR15 en borrador. Checklist16/16 y rama002 b670d86 limpios al inicio;
  se reutiliza issue13 y no se fusiona ni cierra ningún trabajo.
- QA **APROBÓ la preparación de la adenda002**: I4 heredado se aborda solo en
  T019–T022, separado del arte y con RED nativo antes de desarrollo. V4 simulado
  responde al método solicitado por la persona; hardware iOS sigue no probado.
  Xiaomi físico conserva la comparación de rendimiento, sin PASS automático de
  SC007 ni excepción implícita a la referencia constitucional. Se mantienen los
  siete checkboxes históricos y los 18 IDs; los cuatro nuevos siguen pendientes.

- 2026-10-16: **APROBADO T019 (solo RED)** por QA: test y UID idénticos a la
  fuente aprobada003, script002 aún sin corregir. Las copias nativas sin/con
  arte importaron correctamente y dieron4/6 PASS, dos fallos semánticos I4,
  28/36 aserciones, EXIT1. Se adopta el diagnóstico actual, sin reconstruir
  historia ni equiparar fixture con toque físico. [RED](evidence/t019-red.md).
  Habilitada T020; corrección y matriz nativa pendientes. **8/22** tareas
  marcadas, conservando los siete checkboxes históricos.

- 2026-10-16: **APROBADO T020/T021/T022** por QA para el ciclo I4 nativo
  automatizado. Import limpio0, GREEN6/6 (36 aserciones), regresión189/189
  (532 aserciones,38.199s, tres avisos históricos) y comparativo sin arte con
  el mismo arreglo6/6. Diff exclusivo y95/97 invariantes originales preservados;
  únicas excepciones: instancia visual y script I4. [GREEN](evidence/t021-green.md).
  Este dictamen no acredita gestos físicos, stretch/UI ni SC007; T008/T009 y la
  matriz nativa continúan pendientes. **11/22 tareas marcadas**.

- 2026-10-16: QA **APROBÓ la aclaración del método Android** solicitada por la
  persona: los casos controlados I1–I4/I9 se verifican en AVD mediante gestos
  del SO; el Xiaomi conserva muestreo humano y mediciones físicas, con resultados
  separados. No se exige repetir cada caso con dedo físico ni trasladar el PASS
  emulado a casos físicos no demostrados. [Método](quickstart.md). SC-007 y la
  referencia constitucional permanecen intactos; no se marca T008 por admitir
  el método. QA también aprobó la procedencia de la plantilla local iOS Simulator
  arm64 del mismo tag oficial 4.7.1, sin parches: resuelve el bloqueo de compilación,
  pero la ejecución y los gestos V4 siguen pendientes de evidencia y dictamen.

- 2026-10-16: la persona eligió expresamente «Usar el Xiaomi como referencia
  provisional para 002». QA **APROBÓ la enmienda constitucional 1.2.0** y su
  sincronización con los cuatro documentos de preparación. La excepción se
  limita al Xiaomi 11T Pro físico de esta feature; mantiene 60 FPS estables,
  QA independiente y la referencia nominal global. No aprueba SC-007 por sí
  sola ni se extiende a 003, otros teléfonos o iOS. Las mediciones y el dictamen
  de rendimiento conservan su evaluación separada.
