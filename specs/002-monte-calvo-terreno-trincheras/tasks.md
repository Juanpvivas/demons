---
description: "Primera iteración visual de Monte Calvo: terreno, conservación de mecánicas y trincheras decorativas"
---

# Tasks: Monte Calvo — terreno y trincheras, iteración visual 1

**Feature ID**: `002-monte-calvo-terreno-trincheras`
**Input**: [spec.md](spec.md), [plan.md](plan.md), [research.md](research.md), [data-model.md](data-model.md), [contrato](contracts/visual-boundary.md), [referencia](references/visual-reference.md) y [validación](quickstart.md).
**Status**: ejecución iniciada por agentes; los checkboxes se actualizan solo tras QA y no certifican verificaciones pendientes.
**Execution Branch**: `codex/002-monte-calvo-terreno-trincheras`, preparada por el orquestador.
**Issue**: [#13](https://github.com/Juanpvivas/demons/issues/13).
**Dependency**: PR #12 (preset/flujo de agentes) sigue abierto; esta rama parte de ese cambio y no modifica su PR.

## Formato y aprobación

El [flujo compartido](../../docs/DEVELOPMENT_WORKFLOW.md) gobierna ejecución y evidencia. Cada tarea identifica propietario, ruta, dependencias y verificación. `[P]` señala únicamente archivos independientes con prerrequisitos satisfechos; no autoriza editar simultáneamente la misma escena. Solo el orquestador registra `[X]` tras `APROBADO` de QA.

Este alcance es arte estático sin lógica nueva: revisión visual/de integración y regresión existente, sin RED artificial ni pruebas que solo enumeren sprites. Si se necesita cambiar comportamiento, detener esa ampliación y preparar sus tareas RED → desarrollo → GREEN/regresión → QA; no cambiar scripts, costos, input o geometría bajo estas tareas.

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

- [ ] T008 [US2] godot-tester: ejecutar la regresión existente pertinente de `tests/unit/levels/test_nivel_montecalvo.gd`, `test_wave_spawner.gd` y sistemas/unidades aplicables, además de los escenarios I1–I9 de `quickstart.md` con ratón/toque en V1 y V3–V4; registrar esperado/observado y limitaciones en `specs/002-monte-calvo-terreno-trincheras/evidence/us2.md`; depende de T007; no añadir UI o alterar tests para compensar fallos del arte.
- [ ] T009 [US2] qa-validator: revisar de forma independiente `specs/002-monte-calvo-terreno-trincheras/contracts/visual-boundary.md`, el diff de `scenes/levels/Nivel_MonteCalvo.tscn` y los reportes T004/T007/T008; aprobar o devolver terreno y conservación de mecánicas con causas concretas; depende de T008; solo lectura y veredicto, sin modificar el checkout ni marcar tareas.

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
           └→ T005 ──────┴→ T006 → T007 → T008 → T009
                                                  └→ T010 → T011 → T012
                                                                 └→ T013 → T014 → T015 → T016 → T017 → T018
```

- T003 y T005 pueden avanzar en paralelo tras T002: escena nueva frente a imágenes en archivos distintos. No ejecutar dos editores/importadores concurrentes sobre el mismo checkout; el orquestador serializa la importación.
- El resto mantiene orden explícito. T006 y T011 editan la misma escena: nunca se ejecutan en paralelo.
- T004/T007/T008/T012/T013/T014/T015 pertenecen al tester; el desarrollador no ejecuta pruebas. T009/T016/T018 son QA en solo lectura; el orquestador conserva los veredictos y el estado de tareas.
- Esta feature no cambia lógica. Si una corrección requiriera comportamiento nuevo, las tareas RED no podrán depender de su implementación; el orquestador deberá preparar ese alcance con pruebas válidas antes de desarrollarlo.

## Trazabilidad

| Requisito / resultado | Tareas principales |
|---|---|
| FR-001/002; US1; SC-001 | T002, T005, T006, T007 |
| FR-003; US3; SC-001/002 | T010, T011, T012 |
| FR-004; SC-002/003 | T003, T004, T007, T008, T009, T011, T012 |
| FR-005–009; US2; SC-003/004/006 | T001, T004, T008, T009, T013, T014, T016 |
| FR-010; SC-005 | T001, T002, T007, T008, T012, T015 |
| FR-011 | T003, T004, T011, T016 |
| FR-012; evidencia de SC-001–007 | T001, T007, T008, T012, T013, T014, T015, T016, T017, T018 |
| FR-013; SC-007 | T001, T015, T016 |

## Estrategia de entrega

MVP visual: T001–T009, terreno US1 con conservación US2 aprobada. Iteración completa: añadir trincheras US3 y terminar T010–T018. No detener la iteración completa dando por entregado solo el MVP.

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
