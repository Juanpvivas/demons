# Tasks: Cinco carriles horizontales y salida de trincheras

**Feature**: `005-cinco-carriles` · **Issue**: [#22](https://github.com/Juanpvivas/demons/issues/22) · **Rama de preparación**: `codex/005-cinco-carriles-preparacion`.
**Input**: [spec](spec.md), [plan aprobado documentalmente](plan.md), [modelo](data-model.md), [contrato](contracts/horizontal-combat.md), [quickstart](quickstart.md) y [flujo](../../docs/DEVELOPMENT_WORKFLOW.md).
**Estado**: I1 en ejecución en `codex/005-i1-tablero`, desde `7925454` (preparación integrada en I2). T001–T004 aprobadas por QA; pruebas RED T005–T007 en preparación. El comportamiento horizontal sigue pendiente.

I2/004 sigue conservado en `codex/004-i2-enemigo`, base `f90e888`, sin cierre ni
modificación de sus tareas/aprobaciones. Las ramas de incremento dependen de esa
base aún no integrada; declarar bases/diffs y revalidar al integrar, sin presentar
cambios heredados como exclusivos de 005. Un Issue para la feature; PR intermedios
`Refs #22`, último elegible `Closes #22`, siempre borrador y nunca merge automático.

## Reglas de ejecución y gates

- Rol y dependencias figuran en cada tarea. Solo orquestador marca `[X]` tras
  veredicto independiente aplicable; las tareas de implementación/entrega no se
  completan por aprobar RED o una revisión funcional parcial.
- RED semántico antes del desarrollo: setup mínimo resuelve parser/import/API,
  sin implementar conducta. Si un caso ya pasa, registrar cobertura existente;
  no romper código para fabricar RED. Dev no escribe/modifica/ejecuta pruebas.
- Cada I1–I4 exige su gate de destinos del [plan](plan.md#incrementos-previstos)
  y [quickstart](quickstart.md#gate-de-cada-incremento): Web de computador, APK
  Android Emulator y `.app` iOS Simulator por separado; entrada de SO, visual,
  resize, partida y comparación base/candidato de carga/frame times pertinentes.
  Cambios que arriesgan FPS requieren medición física antes de aceptación/merge.
- Sin hardware puede avanzarse en preparación/RED/desarrollo funcional, pero
  los gates obligatorios pendientes mantienen implementación/incremento WIP:
  ni revisión funcional parcial ni draft PR significan APROBADO o entregado.
  No pedir reconexión física, exención o pruebas Web móviles. I5 consolida y
  repite pendientes/invalidados; no aplaza verificaciones propias de otros PR.
- Para continuar a una rama dependiente basta GREEN funcional y revisión QA
  funcional parcial explícita del anterior; esta revisa suficiencia técnica
  y enumera límites, sin aprobar implementación. Orquestador guarda commit/base
  WIP antes de abrir la rama siguiente. Cada ciclo conserva su rama; retomar o
  integrar una base obliga a revisar diff/evidencia. Los gates de entrega siguen
  dependiendo de todos los controles, aunque otras ramas avancen funcionalmente.
- Resultados/comandos/límites se entregan al orquestador para PR y QA; logs en
  temporales/CI, sin nuevos archivos de evidencia Git. No volcar registros en
  estos documentos. Arte/documentos sin conducta no requieren RED artificial.
- Consultar GodotPrompter pertinente antes de escribir/revisar cada sistema.
  `[P]` permite autoría independiente en archivos distintos tras prerrequisitos;
  importaciones, builds y runners del checkout se serializan.

## Fase 1 — Preparación de ejecución

**Objetivo**: base preservada, incremento delimitado y harness operativo, sin confundir esta preparación con su ejecución.

- [X] T001 project-orchestrator: verificar `specs/005-cinco-carriles/checklists/requirements.md`, spec/plan/tasks y Issue #22; preparar `codex/005-i1-tablero` con base I2 explícita, revisión de tamaño/IDs y conservación de 004 en `specs/004-personajes-municion-monte-calvo/tasks.md`; sin dependencias.
- [X] T002 godot-tester: comprobar importación y baseline GUT con `tools/ci/run_gut.py` sobre T001, identificar cobertura existente en `tests/unit/` y harness de cuerpos reales; reportar fallos de entorno separados de RED; depende de T001.

## Fase 2 — Contratos mínimos para RED

**Objetivo**: pruebas invocables sin implementar el comportamiento futuro.

- [X] T003 dev-godot: preparar solo interfaces/datos mínimos invocables de `resources/schemas/lane_board_config.gd`, `resources/levels/monte_calvo_board.tres`, `scenes/enemies/enemigo.gd` y `scenes/levels/wave_spawner.gd` conforme al contrato; sin activar cinco filas, movimiento, cursor o conteo nuevos y sin pruebas; depende de T002.
- [X] T004 qa-validator: revisar setup T003 contra `specs/005-cinco-carriles/contracts/horizontal-combat.md` y baseline T002, confirmando interfaz/harness utilizables y ausencia de conducta implementada antes de RED; depende de T003.

## Fase 3 — US1: Defender cinco filas desde las trincheras (P1) · I1

**Objetivo**: tablero horizontal funcional con cinco defensas y entrada enemiga derecha→izquierda.
**Criterio independiente**: cinco cargas/reserva cero, filas/plazas visibles, fusil estacionario correcto y derrota física izquierda en cada fila. Machete móvil y recarga UI continúan pendientes de I2/I3.

- [ ] T005 [P] [US1] godot-tester RED: escribir `tests/unit/systems/test_lane_board_config.gd`/`tests/unit/levels/test_horizontal_board.gd` y ampliar `tests/unit/levels/test_monte_calvo_framing.gd` para cinco inicios gratuitos/cargados, whitelist/bordes/ocupadas sin gasto, filas independientes, cruce real izquierdo/LOST único y acciones tardías; comprobar antes del cambio de cámara RED de centrado del rectángulo en ambos ejes con aspectos distintos/resize e inversión pantalla↔mundo para plazas, pickups y despliegue bajo el nuevo canvas; fallo semántico, no error de harness; depende de T004.
- [ ] T006 [P] [US1] godot-tester RED: escribir `tests/unit/levels/test_horizontal_wave_spawner.gd` para inicial t0/fila3 sin cursor ni baja WaveManager, 99 WAVE/100 totales, orden1→5 continuo/esperas y WON por bajas WAVE; misma instancia INITIAL→WAVE→INITIAL en distinta fila limpia origen/carril/generación y registra visual una vez; depende de T004.
- [ ] T007 [P] [US1] godot-tester RED: escribir `tests/unit/units/test_horizontal_targeting.gd` para fusil a derecha, frente/diagonal contigua y límites longitudinales reales, exclusión detrás/profunda/dos filas, prioridad−X sin robar foco y daño/carga/moral vigentes; ejecutar fallo válido; depende de T004.
- [ ] T008 [US1] qa-validator: validar independientemente RED de T005–T007 frente a `specs/005-cinco-carriles/spec.md`/contrato; distinguir fallo esperado de entorno y cobertura ya GREEN; aprobar solo pruebas RED válidas, no implementación; depende de T005, T006 y T007.
- [ ] T009 [US1] dev-godot: implementar geometría/plazas/cinco inicios y validación antes de gasto en `scenes/levels/nivel_monte_calvo.gd`, `scenes/levels/Nivel_MonteCalvo.tscn` y `resources/levels/monte_calvo_board.tres`; adaptar `wave_spawner.gd`/`scenes/enemies/enemigo.gd` a −X/pool con origen y cursor sin cambiar API `core/object_pool.gd`, stats o tiempos; depende de T008 aprobada.
- [ ] T010 [US1] dev-godot: orientar formas y filtro explícito frontal/diagonal/rango en `scenes/units/Soldado.tscn`/`soldado.gd`, progreso en `scenes/enemies/enemigo.gd`, zona izquierda y cámara local `scenes/levels/monte_calvo_camera.gd`; no ampliar alcance ni añadir movimiento machete; depende de T009.
- [ ] T011 [US1] godot-tester GREEN: confirmar T005–T007, incluido centrado en ambos ejes/aspectos/resize e inversión pantalla↔mundo del nuevo canvas; ejecutar regresión explícita de `tests/unit/levels/test_monte_calvo_framing.gd`/`tests/unit/levels/test_pickup_input_routing.gd` y pertinente de `tests/unit/{systems,levels,units,enemies}/`, con cuerpos/Managers reales, economía/pickups, daño/moral, pooling y terminales; no corregir código; depende de T010.
- [ ] T012 [US1] qa-validator: revisión funcional parcial del código y RED/GREEN de T011 con `specs/005-cinco-carriles/contracts/horizontal-combat.md`; documentar suficiencia técnica para continuar y gates pendientes, sin APROBADO de implementación/entrega; depende de T011.
- [ ] T013 [US1] godot-tester: ejecutar gate I1 de `specs/005-cinco-carriles/quickstart.md` en Web/APK/.app, input real/plazas/pickups, visual/resize y partida a terminal; comparar carga/frame times base/candidato y medición física por riesgo de población/consultas/pool; sin hardware registrar pendiente/WIP, sin certificarlo; depende de T011.
- [ ] T014 [US1] qa-validator: aceptar implementación I1 solo con GREEN y todos los controles obligatorios de `specs/005-cinco-carriles/quickstart.md`, incluidos rendimiento físico/renderer aplicables; falta de T013 completo mantiene WIP y T009/T010 pendientes de aprobación; depende de T012 y T013 completas.
- [ ] T015 [US1] docs-writer: documentar únicamente I1 aprobado y pendientes I2/I3 en `docs/SPEC.md`/`docs/ARCHITECTURE.md`, sin registros de validación ni alterar 004; depende de T014 aprobada.
- [ ] T016 [US1] qa-validator: revisar diff/documentación final I1 y vigencia del estado probado en `docs/SPEC.md`, `docs/ARCHITECTURE.md` y fuentes T009/T010; si cambia conducta devolver al ciclo correspondiente; depende de T015.
- [ ] T017 [US1] project-orchestrator: registrar tareas I1 aprobadas en `specs/005-cinco-carriles/tasks.md`, revisar tamaño/base y preparar PR en borrador `Refs #22` con RED/GREEN/QA/límites breves; sin publicar como entrega mientras falten gates, sin promover/mergear; depende de T016 aprobada.

## Fase 4 — US2: Salir con machete al agotar la carga (P1) · I2

**Objetivo**: mismo soldado sale/espera/combate en su fila y libera origen al morir.
**Criterio independiente**: última bala mata único→espera; si queda frontal→sale a40 propios, contacto detiene sin atravesar y ambos reciben daño real.

- [ ] T018 [US2] project-orchestrator: guardar estado/base I1 GREEN con revisión T012 conforme y abrir `codex/005-i2-machete`, declarando dependencia WIP si T014–T017 siguen pendientes en `specs/005-cinco-carriles/tasks.md`; no aprobar ni entregar I1 por avanzar; depende de T012 conforme.
- [ ] T019 [US2] dev-godot: disponer interfaces de estado/movimiento invocables y campos propios `advance_speed/return_speed` de `resources/schemas/unit_stats.gd`/`resources/units/soldado_base_stats.tres`,40/40 según modelo; no implementar salida/contacto/retorno ni modificar pruebas; depende de T018.
- [ ] T020 [P] [US2] godot-tester RED: escribir `tests/unit/units/test_soldado_lane_motion.gd` para última bala→machete, único blanco muerto→espera, siguiente frontal→avance, perder blanco→espera/reanudar y excluir detrás/otras filas; medir40 propios con ticks y dos velocidades EnemyStats distintas; depende de T019.
- [ ] T021 [P] [US2] godot-tester RED: escribir `tests/unit/units/test_soldado_mobile_contact.gd` para dos cuerpos realmente móviles, bloqueo sin atravesar, alcance/daño mutuo/cooldowns y múltiples atacantes sin duplicación; origen reservado/muerte libera y blanco reciclado inválido; depende de T019.
- [ ] T022 [US2] qa-validator: validar fallo semántico y cobertura de T020/T021 contra `specs/005-cinco-carriles/contracts/horizontal-combat.md`, sin aceptar callbacks simulados como contacto real; depende de T020 y T021.
- [ ] T023 [US2] dev-godot: convertir raíz de `scenes/units/Soldado.tscn`/`soldado.gd` a cuerpo móvil y estados de salida/espera/contacto de misma fila; usar velocidades propias, buscar solo frontal y conservar vida/moral/arma/plaza de origen; depende de T022 aprobada.
- [ ] T024 [US2] dev-godot: implementar consulta física puntual/filtros y contacto real en `scenes/units/soldado.gd`/`scenes/enemies/enemigo.gd`, conservando daño/cadencias, exclusión de blancos inactivos/generación y bloqueo entre cuerpos sin cambio de fila; liberar origen desde `scenes/levels/nivel_monte_calvo.gd`; depende de T023.
- [ ] T025 [US2] godot-tester GREEN: confirmar T020/T021 y regresión de `tests/unit/{units,enemies,levels,systems}/` sobre movimiento/contacto real, targeting, salud/moral/carga, muerte fuera, pool/efectos y terminales; depende de T024.
- [ ] T026 [US2] qa-validator: revisión funcional parcial de T023–T025 contra `specs/005-cinco-carriles/spec.md`, con suficiencia para continuar y gates pendientes; sin APROBADO de implementación/entrega; depende de T025.
- [ ] T027 [US2] godot-tester: gate I2 de `specs/005-cinco-carriles/quickstart.md`, Web/APK/.app con machete/contacto por filas, gestos/resize/partida y playtest espacial; comparativa base/candidato y medición física por nuevos cuerpos/consultas; pendiente físico conserva WIP; depende de T025.
- [ ] T028 [US2] qa-validator: aceptar implementación I2 solo tras T027 completo y conformidad de código/RED/GREEN con `specs/005-cinco-carriles/contracts/horizontal-combat.md`; exigir gates propios y de bases para entrega, sin extrapolar emulación a hardware; depende de T026, T027 completas y T014 aprobada.
- [ ] T029 [US2] docs-writer: documentar movimiento/contacto aprobados y evolución de soldado estático en `docs/ARCHITECTURE.md`/`docs/SPEC.md`, conservando hallazgos históricos y recarga I3 pendiente; depende de T028 aprobada.
- [ ] T030 [US2] qa-validator: revisar resultado/documentación final I2 y vigencia del estado probado en `docs/ARCHITECTURE.md`/`docs/SPEC.md` y fuentes T023/T024; depende de T029.
- [ ] T031 [US2] project-orchestrator: actualizar `specs/005-cinco-carriles/tasks.md` solo tras aprobaciones y preparar PR I2 en borrador `Refs #22` con base/tamaño/QA/TDD; nunca entrega aprobada con gates pendientes; depende de T030 aprobada.

## Fase 5 — US3: Administrar plazas y munición (P2) · I3

**Objetivo**: seleccionar dueño de trinchera, recargar una sola vez y retornar sin romper economía/picking.
**Criterio independiente**: solo vivo/vacío/fondos acepta; cobra una vez, conserva vida/moral y regresa vulnerable sin ofensiva; gesto de caja no dispara otra acción.

- [ ] T032 [US3] project-orchestrator: guardar base I2 GREEN/T026 conforme, abrir `codex/005-i3-recarga` y declarar WIP/dependencias en `specs/005-cinco-carriles/tasks.md` si entrega anterior pendiente; depende de T026 conforme.
- [ ] T033 [US3] dev-godot: preparar interfaces mínimas invocables de estado/elegibilidad/intención en `scenes/units/soldado.gd`, `scenes/ui/HUD.tscn`/`hud.gd` y `scenes/levels/nivel_monte_calvo.gd`; sin aceptar/cobrar recarga ni implementar UI/ruta nueva antes de RED; depende de T032.
- [ ] T034 [P] [US3] godot-tester RED: escribir `tests/unit/units/test_soldado_reload_return.gd` para vivo/carga0/fondos/PLAYING, rechazo parcial/llena/muerto, bloqueo antes de callbacks de gasto y un cobro por retorno; vida/moral conservadas,40/s, sin ofensiva/vulnerable, muerte cancela/libera y fusil solo al llegar; depende de T033.
- [ ] T035 [P] [US3] godot-tester RED: escribir `tests/unit/levels/test_trench_selection_input.gd` y ampliar `tests/unit/ui/test_hud.gd` para selección dueño fuera/panel/botón, acción capturada→muerte→reemplazo sin cobrar nuevo, pickup sobre libre/ocupada/actor y solapadas, mouse emulado/toque sin doble orden y terminal; depende de T033.
- [ ] T036 [US3] qa-validator: validar T034/T035 contra `specs/005-cinco-carriles/contracts/horizontal-combat.md`; comprobar RED semántico y no solo botón deshabilitado como protección económica; depende de T034 y T035.
- [ ] T037 [US3] dev-godot: implementar transacción de recarga/guard de reentrada y retorno físico en `scenes/units/soldado.gd`, con carga completa al aceptar, salud/moral iguales, sin fusil/machete antes de HOME y daño entrante vigente; depende de T036 aprobada.
- [ ] T038 [US3] dev-godot: integrar selección por origen/identidad actual y HUD mínimo en `scenes/levels/nivel_monte_calvo.gd`/`scenes/levels/Nivel_MonteCalvo.tscn` y `scenes/ui/HUD.tscn`/`hud.gd`, usando señales/contenedores, consumo GUI y precedencia de picking vigente; depende de T037.
- [ ] T039 [US3] godot-tester GREEN: confirmar T034/T035 y regresión pertinente de `tests/unit/{units,levels,ui,systems,enemies}/`, incluidas economía/solapadas, daño en retorno, selección obsoleta, input y terminales; depende de T038.
- [ ] T040 [US3] qa-validator: revisión funcional parcial de T037–T039 frente a `specs/005-cinco-carriles/spec.md`, suficiente para continuar pero con gates de entrega pendientes, sin APROBADO de implementación; depende de T039.
- [ ] T041 [US3] godot-tester: gate I3 de `specs/005-cinco-carriles/quickstart.md` en Web/APK/.app con ratón/toque de SO, panel/recarga/retorno/daño visibles y saldo antes/después, resize/partida; comparar rendimiento base/candidato y medición física por retorno/contacto/UI; depende de T039.
- [ ] T042 [US3] qa-validator: aceptar I3 solo con todas las verificaciones T041 completas y contrato satisfecho en `specs/005-cinco-carriles/contracts/horizontal-combat.md`; requisitos pendientes conservan WIP, sin aceptar renderer distinto por inferencia; depende de T040, T041 completas y T028 aprobada.
- [ ] T043 [US3] docs-writer: documentar interacción/recarga aprobadas y límites en `docs/SPEC.md`/`docs/ARCHITECTURE.md`, sin resultados simulados o registros de validación; depende de T042 aprobada.
- [ ] T044 [US3] qa-validator: revisar documentación y diff final I3 de `docs/SPEC.md`/`docs/ARCHITECTURE.md` con fuentes T037/T038 y estado probado vigente; depende de T043.
- [ ] T045 [US3] project-orchestrator: registrar aprobaciones en `specs/005-cinco-carriles/tasks.md` y preparar PR I3 en borrador `Refs #22`, con base/tamaño/TDD/QA y sin entrega si falta gate obligatorio; depende de T044 aprobada.

## Fase 6 — Composición/presentación transversal · I4

**Objetivo**: trincheras y poses laterales de referencia, estados legibles y cinco filas utilizables en las vistas afectadas.
**Criterio independiente**: filas1/3/5 distinguen fusil dentro, salida/espera/golpe, regreso/daño y derrota; resize no cambia plazas ni mapping de gestos.

- [ ] T046 project-orchestrator: guardar base I3 GREEN/T040 conforme y abrir `codex/005-i4-presentacion`, registrando dependencia WIP si corresponde en `specs/005-cinco-carriles/tasks.md`; depende de T040 conforme.
- [ ] T047 dev-godot: preparar solo interfaz observadora mínima de desplazamiento/retorno en `scenes/units/soldado_visual.gd` y `scenes/enemies/enemigo_visual.gd` para RED invocable, sin nuevas poses/transiciones o autoridad jugable; depende de T046.
- [ ] T048 godot-tester: ampliar `tests/unit/units/test_soldado_visual.gd`, `tests/unit/enemies/test_enemigo_visual.gd` y `tests/unit/ui/test_hud.gd` con RED solo de conducta adicional nueva de I4 (presentación de estados/última bala/retorno, snapshot/reset y adaptación de HUD); ejecutar como regresión GREEN el centrado/resize/mapping de I1 en `tests/unit/levels/test_monte_calvo_framing.gd`/`tests/unit/levels/test_horizontal_board.gd`, sin reconstruir o fabricar RED histórico; sin assertions de píxeles ni RED artificial de arte; depende de T047.
- [ ] T049 qa-validator: validar RED T048 y criterios visuales de `specs/005-cinco-carriles/references/visual-reference.md` contra contrato, separando cobertura existente y arte sin lógica; depende de T048.
- [ ] T050 dev-godot: preparar piezas/poses horizontales de trincheras, fusil/machete/marcha/retorno/caída en `assets/sprites/levels/monte_calvo/`, `assets/sprites/units/monte_calvo/` y `assets/sprites/enemies/monte_calvo/`, con importación/procedencia `SOURCES.md`; no incrustar actores/HUD en fondo ni añadir cobertura; depende de T049 aprobada.
- [ ] T051 dev-godot: integrar recursos/presentación observadora en `scenes/levels/MonteCalvoVisual.tscn`, `scenes/units/soldado_visual.gd`, `scenes/enemies/enemigo_visual.gd` y escenas de actor; adaptar `scenes/levels/monte_calvo_camera.gd`/`scenes/ui/HUD.tscn` sin mover geometría o stats; depende de T050.
- [ ] T052 godot-tester GREEN: confirmar T048 y regresión de `tests/unit/{units,enemies,levels,ui,systems}/`, snapshot/reset/material/generación y ausencia de autoridad de animaciones sobre combate/recursos/ocupación; depende de T051.
- [ ] T053 qa-validator: revisión funcional parcial de T050–T052 con `specs/005-cinco-carriles/references/visual-reference.md` y contrato; registrar suficiencia para consolidar y gates pendientes sin APROBADO de implementación/entrega; depende de T052.
- [ ] T054 godot-tester: gate I4 de `specs/005-cinco-carriles/quickstart.md` Web/APK/.app, QA visual de estados/filas1/3/5, input real tras resize, carga/partida; comparar carga/frame times base/candidato y medición física por recursos/efectos nuevos, sin certificar hardware desde software; depende de T052.
- [ ] T055 qa-validator: aceptar I4 con T054 completo, criterios visuales y `specs/005-cinco-carriles/contracts/horizontal-combat.md` satisfechos; sin hardware/rendimiento obligatorio el incremento sigue WIP; depende de T053, T054 completas y T042 aprobada.
- [ ] T056 docs-writer: consolidar composición/estados aprobados y procedencia útil en `docs/SPEC.md`, `docs/ARCHITECTURE.md` y `assets/sprites/{levels,units,enemies}/monte_calvo/SOURCES.md`, sin logs/evidencias Git; depende de T055 aprobada.
- [ ] T057 qa-validator: revisar documentación/recursos/diff final I4 contra `specs/005-cinco-carriles/references/visual-reference.md` y estado probado, sin ampliar aprobación a entornos no verificados; depende de T056.
- [ ] T058 project-orchestrator: registrar aprobaciones I4 en `specs/005-cinco-carriles/tasks.md` y preparar PR en borrador `Refs #22` con base, binarios/generados aparte y límites; sin promote/merge automático; depende de T057 aprobada.

## Fase 7 — Consolidación y cierre transversal · I5

**Objetivo**: verificar integración sin repetir rutina o trasladar gates anteriores a esta fase.

- [ ] T059 project-orchestrator: guardar base integrada funcional/T053 conforme y preparar `codex/005-i5-validacion` con dependencias WIP identificadas en `specs/005-cinco-carriles/tasks.md`; revisar qué evidencia quedó invalidada al integrar bases, sin dar por entregados incrementos pendientes; depende de T053 conforme.
- [ ] T060 godot-tester: ejecutar suite completa mediante el comando del quickstart con `tools/ci/run_gut.py` y ruta real al binario Godot y smoke de producción en `scenes/levels/Nivel_MonteCalvo.tscn`; preservar100/población y99/WON, recorrer inicio→terminal y victoria determinista separada; defecto nuevo se devuelve al ciclo TDD, sin rebalance silencioso; depende de T059.
- [ ] T061 godot-tester: consolidar controles de `specs/005-cinco-carriles/quickstart.md`/SC-001–SC-007, reusar solo evidencia válida del mismo estado y repetir pendientes/invalidados en sus destinos; mediciones físicas ausentes siguen pendientes, no sustituir por emulación; depende de T060.
- [ ] T062 qa-validator: evaluar 12 FR/7 SC en `specs/005-cinco-carriles/spec.md` y coherencia integrada de T060/T061; solo aprobación global si gates de I1–I4 y todos los requisitos obligatorios completos, sin heredar cierre de004; depende de T014, T028, T042, T055 aprobadas y T061 completa.
- [ ] T063 docs-writer: consolidar comportamiento aprobado/limitaciones útiles en `README.md`, `docs/SPEC.md` y `docs/ARCHITECTURE.md`, sin nuevos archivos de evidencias ni crónicas; depende de T062 aprobada.
- [ ] T064 qa-validator: revisar diff/documentación finales de `README.md`, `docs/SPEC.md` y `docs/ARCHITECTURE.md` contra estado integrado probado y trazabilidad de `specs/005-cinco-carriles/tasks.md`; depende de T063.
- [ ] T065 project-orchestrator: registrar aprobaciones finales en `specs/005-cinco-carriles/tasks.md`, revisar bases/tamaño/checklists y preparar último PR en borrador con `Closes #22` solo si todos los criterios cumplidos; si no, conservar WIP/Issue abierto, sin promover/mergear; depende de T064 aprobada.

## Dependencias y oportunidades de paralelo

Ruta funcional: T001→T002→T003→T004→{T005,T006,T007}→T008→T009→T010→T011→T012
→T018→T019→{T020,T021}→T022→T023→T024→T025→T026→T032→T033→{T034,T035}
→T036→T037→T038→T039→T040→T046→T047→T048→T049→T050→T051→T052→T053
→T059→T060→T061. Cada revisión funcional parcial conforme habilita trabajar
sobre base WIP, nunca aprobación/entrega del incremento anterior.

Rutas de aceptación: I1 T013→T014→T015→T016→T017; I2 T027→T028→T029→T030→T031;
I3 T041→T042→T043→T044→T045; I4 T054→T055→T056→T057→T058. Conservan sus
prerrequisitos GREEN/QA parcial y bases aprobadas indicados en tareas. Cierre
I5 requiere T014/T028/T042/T055 más T061→T062→T063→T064→T065.

Ejemplos de paralelo de autoría: US1 T005/T006/T007 tras T004; US2 T020/T021
tras T019; US3 T034/T035 tras T033. Son archivos distintos; sus ejecuciones
sobre el checkout se serializan. Implementaciones que comparten `soldado.gd`,
`enemigo.gd`, nivel o HUD nunca se ejecutan en paralelo. No paralelizar RED y
su implementación ni compartir una rama durante ciclos ajenos.

## Cobertura y estrategia de entrega

| Requisito | Tareas principales (más gates de su incremento) |
|---|---|
| FR-001 | T005/T009, inicio y cinco defensas |
| FR-002 | T005/T009 y T035/T038, whitelist/reserva/selección |
| FR-003 | T006/T009, cursor y fila de activación |
| FR-004 | T007/T010, fusil/rango/diagonales/prioridad |
| FR-005 | T019/T020/T023, salida/espera/velocidad propia |
| FR-006 | T021/T024, contacto/daño/cooldowns |
| FR-007 | T034/T035/T037/T038, transacción/retorno/UI |
| FR-008 | T005/T021/T024/T034, reserva/baja/liberación |
| FR-009 | T007/T035/T038, moral/economía/picking |
| FR-010 | T006/T009/T060,100 enemigos y99 bajas WAVE/WON |
| FR-011 | T048/T050/T051/T054, presentación/arte de acciones reales |
| FR-012 | T005/T010/T011 (cámara/mapping I1), T006/T021/T035/T048/T051 (reset/adaptación adicional) |
| SC-001 | T005/T011/T013 y T048/T054 |
| SC-002 | T005/T007/T011/T013, repetido en regresión afectada |
| SC-003 | T020/T021/T025/T027 y T034/T039/T041/T054 |
| SC-004 | T005/T035/T039/T041 |
| SC-005 | T006/T011/T013/T027/T041/T054/T060 |
| SC-006 | T005/T011 cámara/mapping automatizados; T013/T027/T041/T054 por destino separado |
| SC-007 | T013/T027/T041/T054 y consolidación T061; sin físico permanece pendiente |

MVP parcial: I1/US1 da tablero horizontal funcional conservando lo demás
pendiente; solo se entrega si cumple sus gates obligatorios. I2 añade machete,
I3 interacción de recarga, I4 presentación y I5 consolida. No acumular resultados
independientes: orientación≤400 líneas manuales (adiciones+eliminaciones)/20
archivos por PR, binarios/generados separados; justificación de unidad mínima
I1 en plan y revisión real de tamaño en T001/T017. No fragmentar TDD para
fusionar RED pendiente ni reescribir historial compartido.

No hay hooks de tareas: `.specify/extensions.yml` no existe. El análisis
independiente de consistencia y los gates documentales están aprobados. La
futura ejecución corresponde al orquestador equivalente a
`/implementar-feature 005-cinco-carriles`; esta preparación no la invoca
ni ejecuta pruebas o builds del juego.
