# Tasks: Cinco carriles horizontales y salida de trincheras

**Feature**: `005-cinco-carriles` · **Issue**: [#22](https://github.com/Juanpvivas/demons/issues/22) · **Rama de preparación**: `codex/005-cinco-carriles-preparacion`.
**Input**: [spec](spec.md), [plan aprobado documentalmente](plan.md), [modelo](data-model.md), [contrato](contracts/horizontal-combat.md), [quickstart](quickstart.md) y [flujo](../../docs/DEVELOPMENT_WORKFLOW.md).
**Estado**: I1 y 004-I2 integrados en `main` mediante Squash and merge del PR #24 (`658dd7e`). I2 integrado en `main` mediante Squash and merge del PR [#25](https://github.com/Juanpvivas/demons/pull/25) (`c1f43d2`). I3 integrado en `main` mediante Squash and merge del PR [#26](https://github.com/Juanpvivas/demons/pull/26) (`8c4cab4`), con T032–T045 aprobadas. I4 en curso en `codex/005-i4-presentacion` desde ese main: T046/T047 aprobadas, pruebas T048 en preparación. I5 y publicación T071 permanecen pendientes.
**PR conjunto integrado**: [#24](https://github.com/Juanpvivas/demons/pull/24), `Refs #18` y `Refs #22`; integración realizada el 2026-10-20, publicación pendiente.

Transición completada: el PR #24 reunió 004-I2 y 005-I1 desde
`codex/005-i1-tablero` hacia `main` (`2dc532d` como base de revisión).
La persona autorizó el squash y la eliminación de las dos ramas superadas,
realizados tras comprobar que todo el contenido aprobado quedó integrado.
Las features siguen abiertas y la publicación pendiente. I2 se integró mediante el PR #25 el 2026-10-20. I3 se integró mediante el
PR #26 el mismo día: selección, recarga atómica y regreso vulnerable. I4 parte
de `8c4cab4` con alcance T046–T058: presentación lateral y adaptación visual,
sin cambiar geometría, balance o mecánicas. I5 y publicación siguen pendientes.
Durante I2, la API de recarga existente se conserva dentro del hogar; fuera
de él rechaza la orden sin gasto hasta incorporar el regreso de I3. El fusil
sigue limitado a HOME y esa adaptación requiere RED antes de implementarse.

## Reglas de ejecución y gates

- Solo orquestador marca `[X]` tras veredicto independiente de la tarea.
  Las aprobaciones históricas conservan su alcance; esta enmienda no las amplía.
- RED semántico → dev → GREEN/regresión → QA → documentación. Dev no escribe,
  modifica ni ejecuta pruebas. Setup no implementa la conducta que debe guiar RED.
- Integración (constitución 4.0.0): GREEN, compilación/exportación aplicables,
  entrada/visual/resize/smoke Web de computador, APK Android Emulator y `.app`
  iOS Simulator disponibles, comparación base/candidato, documentación y CI.
  QA emite `APROBADO PARA INTEGRACIÓN`; errores reales de fuente/build/función
  bloquean. Se evalúan también diferencias de rendimiento observadas.
- Publicación: T071 conserva SC-007/60 FPS físicos, renderer y paquete final,
  firma/versionado y matriz de destino; exige `APROBADO PARA PUBLICACIÓN` y
  autorización humana. Ausencia de certificación/hardware no impide por sí
  sola integración ni se marca aprobada desde Compatibility/software de QA.
  Merge a main no distribuye. No pedir reconexión ni pruebas Web móviles.
- I1–I4 conservan sus verificaciones funcionales propias; I5 reutiliza evidencia
  válida y repite sólo pendientes/invalidados. Publicación no se aplaza sin
  seguimiento: permanece explícita en T071 y la feature/Issue no se cierran.
- Logs en temporales/CI, resultados breves en PR; sin evidencias nuevas Git.
  Arte/documentos sin conducta no requieren RED artificial. Consultar skills
  GodotPrompter pertinentes antes de escribir/revisar sistemas de Godot.
- `[P]` permite autoría independiente; importaciones/builds/runners y cambios
  sobre archivos compartidos se serializan. No cambiar de rama en el ciclo.

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

- [X] T005 [P] [US1] godot-tester RED: escribir `tests/unit/systems/test_lane_board_config.gd`/`tests/unit/levels/test_horizontal_board.gd` y ampliar `tests/unit/levels/test_monte_calvo_framing.gd` para cinco inicios gratuitos/cargados, whitelist/bordes/ocupadas sin gasto, filas independientes, cruce real izquierdo/LOST único y acciones tardías; comprobar antes del cambio de cámara RED de centrado del rectángulo en ambos ejes con aspectos distintos/resize e inversión pantalla↔mundo para plazas, pickups y despliegue bajo el nuevo canvas; fallo semántico, no error de harness; depende de T004.
- [X] T006 [P] [US1] godot-tester RED: escribir `tests/unit/levels/test_horizontal_wave_spawner.gd` para inicial t0/fila3 sin cursor ni baja WaveManager, 99 WAVE/100 totales, orden1→5 continuo/esperas y WON por bajas WAVE; misma instancia INITIAL→WAVE→INITIAL en distinta fila limpia origen/carril/generación y registra visual una vez; depende de T004.
- [X] T007 [P] [US1] godot-tester RED: escribir `tests/unit/units/test_horizontal_targeting.gd` para fusil a derecha, frente/diagonal contigua y límites longitudinales reales, exclusión detrás/profunda/dos filas, prioridad−X sin robar foco y daño/carga/moral vigentes; ejecutar fallo válido; depende de T004.
- [X] T008 [US1] qa-validator: validar independientemente RED de T005–T007 frente a `specs/005-cinco-carriles/spec.md`/contrato; distinguir fallo esperado de entorno y cobertura ya GREEN; aprobar solo pruebas RED válidas, no implementación; depende de T005, T006 y T007.
- [X] T009 [US1] dev-godot: implementar geometría/plazas/cinco inicios y validación antes de gasto en `scenes/levels/nivel_monte_calvo.gd`, `scenes/levels/Nivel_MonteCalvo.tscn` y `resources/levels/monte_calvo_board.tres`; adaptar `wave_spawner.gd`/`scenes/enemies/enemigo.gd` a −X/pool con origen y cursor sin cambiar API `core/object_pool.gd`, stats o tiempos; depende de T008 aprobada.
- [X] T010 [US1] dev-godot: orientar formas y filtro explícito frontal/diagonal/rango en `scenes/units/Soldado.tscn`/`soldado.gd`, progreso en `scenes/enemies/enemigo.gd`, zona izquierda y cámara local `scenes/levels/monte_calvo_camera.gd`; no ampliar alcance ni añadir movimiento machete; depende de T009.
- [X] T011 [US1] godot-tester GREEN: confirmar T005–T007, incluido centrado en ambos ejes/aspectos/resize e inversión pantalla↔mundo del nuevo canvas; ejecutar regresión explícita de `tests/unit/levels/test_monte_calvo_framing.gd`/`tests/unit/levels/test_pickup_input_routing.gd` y pertinente de `tests/unit/{systems,levels,units,enemies}/`, con cuerpos/Managers reales, economía/pickups, daño/moral, pooling y terminales; no corregir código; depende de T010.
- [X] T012 [US1] qa-validator: revisión funcional parcial del código y RED/GREEN de T011 con `specs/005-cinco-carriles/contracts/horizontal-combat.md`; documentar suficiencia técnica para continuar y gates pendientes, sin APROBADO de implementación/entrega; depende de T011.
- [X] T013 [US1] godot-tester: ejecutar el gate funcional I1 de `specs/005-cinco-carriles/quickstart.md` en Web/APK/.app disponibles: input real/plazas/pickups, visual/resize donde exista y partida a terminal; comparar carga/frame times base/candidato y declarar diferencias, errores, variantes y límites para QA. SC-007, renderer/paquete final y hardware siguen en T071; depende de T011.
- [X] T014 [US1] qa-validator: emitir APROBADO PARA INTEGRACIÓN de I1 sólo con GREEN, código/contrato, controles funcionales T013, compilación aplicable y CI; evaluar diferencias de rendimiento sin inferir hardware desde software. Falta de certificación física/renderer/paquete final queda en T071 y no bloquea por sí sola; fallos reales de fuente/build/función sí. La aprobación habilita T009/T010 con su alcance explícito; depende de T012 y T013 completas.
- [X] T015 [US1] docs-writer: documentar I1 aprobado para integración y pendientes I2/I3/I4/publicación en `docs/SPEC.md`/`docs/ARCHITECTURE.md`, consolidándolo con 004-I2 aprobado sin alterar historia; sin registros de validación; depende de T014 y 004/T020 aprobadas para integración.
- [X] T016 [US1] qa-validator: revisar diff/documentación final I1 y vigencia del estado probado en `docs/SPEC.md`, `docs/ARCHITECTURE.md` y fuentes T009/T010; si cambia conducta devolver al ciclo correspondiente; depende de T015.
- [X] T017 [US1] project-orchestrator: registrar tareas aprobadas, revisar diff/base/tamaño conjunto y preparar único PR 004-I2 + 005-I1 hacia main en borrador con Refs #18 y Refs #22, trazabilidad RED/GREEN/QA y publicación pendiente. Sin Closes, promoción, merge ni distribución automática; depende de T016, 004/T022 y T070 aprobadas para integración.

## Fase 4 — US2: Salir con machete al agotar la carga (P1) · I2

**Objetivo**: mismo soldado sale/espera/combate en su fila y libera origen al morir.
**Criterio independiente**: última bala mata único→espera; si queda frontal→sale a40 propios, contacto detiene sin atravesar y ambos reciben daño real.

- [X] T018 [US2] project-orchestrator: tras integración humana del PR conjunto T017, preparar rama breve `codex/005-i2-machete` desde main actualizado y declarar alcance/IDs; no iniciar I2 durante la transición; depende de T017 integrado y su QA funcional vigente.
- [X] T019 [US2] dev-godot: disponer interfaces de estado/movimiento invocables y campos propios `advance_speed/return_speed` de `resources/schemas/unit_stats.gd`/`resources/units/soldado_base_stats.tres`,40/40 según modelo; no implementar salida/contacto/retorno ni modificar pruebas; depende de T018.
- [X] T020 [P] [US2] godot-tester RED: escribir `tests/unit/units/test_soldado_lane_motion.gd` para última bala→machete, único blanco muerto→espera, siguiente frontal→avance, perder blanco→espera/reanudar y excluir detrás/otras filas; medir40 propios con ticks y dos velocidades EnemyStats distintas; depende de T019.
- [X] T021 [P] [US2] godot-tester RED: escribir `tests/unit/units/test_soldado_mobile_contact.gd` para dos cuerpos realmente móviles, bloqueo sin atravesar, alcance/daño mutuo/cooldowns y múltiples atacantes sin duplicación; origen reservado/muerte libera y blanco reciclado inválido; depende de T019.
- [X] T022 [US2] qa-validator: validar fallo semántico y cobertura de T020/T021 contra `specs/005-cinco-carriles/contracts/horizontal-combat.md`, sin aceptar callbacks simulados como contacto real; depende de T020 y T021.
- [X] T023 [US2] dev-godot: convertir raíz de `scenes/units/Soldado.tscn`/`soldado.gd` a cuerpo móvil y estados de salida/espera/contacto de misma fila; usar velocidades propias, buscar solo frontal y conservar vida/moral/arma/plaza de origen; depende de T022 aprobada.
- [X] T024 [US2] dev-godot: implementar consulta física puntual/filtros y contacto real en `scenes/units/soldado.gd`/`scenes/enemies/enemigo.gd`, conservando daño/cadencias, exclusión de blancos inactivos/generación y bloqueo entre cuerpos sin cambio de fila; liberar origen desde `scenes/levels/nivel_monte_calvo.gd`; depende de T023.
- [X] T025 [US2] godot-tester GREEN: confirmar T020/T021 y regresión de `tests/unit/{units,enemies,levels,systems}/` sobre movimiento/contacto real, targeting, salud/moral/carga, muerte fuera, pool/efectos y terminales; depende de T024.
- [X] T026 [US2] qa-validator: revisión funcional parcial de T023–T025 contra `specs/005-cinco-carriles/spec.md`, con suficiencia para continuar y gates pendientes; sin APROBADO de implementación/entrega; depende de T025.
- [X] T027 [US2] godot-tester: gate funcional I2 de `specs/005-cinco-carriles/quickstart.md`, Web/APK/.app disponibles con machete/contacto por filas, gestos/resize/partida y playtest espacial; comparar base/candidato y declarar diferencias/riesgos. Certificación física/renderer/paquete final se conserva en T071; depende de T025.
- [X] T028 [US2] qa-validator: APROBADO PARA INTEGRACIÓN de I2 sólo tras gate funcional T027 y conformidad código/RED/GREEN/contrato; evaluar diferencias/riesgos y conservar publicación en T071 sin extrapolar emulación a hardware; depende de T026, T027 completas y T014 aprobada.
- [X] T029 [US2] docs-writer: documentar movimiento/contacto aprobados y evolución de soldado estático en `docs/ARCHITECTURE.md`/`docs/SPEC.md`, conservando hallazgos históricos y recarga I3 pendiente; depende de T028 aprobada.
- [X] T030 [US2] qa-validator: revisar resultado/documentación final I2 y vigencia del estado probado en `docs/ARCHITECTURE.md`/`docs/SPEC.md` y fuentes T023/T024; depende de T029.
- [X] T031 [US2] project-orchestrator: actualizar `specs/005-cinco-carriles/tasks.md` solo tras aprobaciones y preparar PR I2 en borrador `Refs #22` con base/tamaño/QA/TDD; nunca entrega aprobada con gates pendientes; depende de T030 aprobada.

## Fase 5 — US3: Administrar plazas y munición (P2) · I3

**Objetivo**: seleccionar dueño de trinchera, recargar una sola vez y retornar sin romper economía/picking.
**Criterio independiente**: solo vivo/vacío/fondos acepta; cobra una vez, conserva vida/moral y regresa vulnerable sin ofensiva; gesto de caja no dispara otra acción.

- [X] T032 [US3] project-orchestrator: tras integración humana del PR I2 T031, preparar rama breve `codex/005-i3-recarga` desde main actualizado, conservando alcance/IDs y publicación pendiente en T071; depende de T031 integrado y su QA funcional vigente.
- [X] T033 [US3] dev-godot: preparar interfaces mínimas invocables de estado/elegibilidad/intención en `scenes/units/soldado.gd`, `scenes/ui/HUD.tscn`/`hud.gd` y `scenes/levels/nivel_monte_calvo.gd`; sin aceptar/cobrar recarga ni implementar UI/ruta nueva antes de RED; depende de T032.
- [X] T034 [P] [US3] godot-tester RED: escribir `tests/unit/units/test_soldado_reload_return.gd` para vivo/carga0/fondos/PLAYING, rechazo parcial/llena/muerto, bloqueo antes de callbacks de gasto y un cobro por retorno; vida/moral conservadas,40/s, sin ofensiva/vulnerable, muerte cancela/libera y fusil solo al llegar; depende de T033.
- [X] T035 [P] [US3] godot-tester RED: escribir `tests/unit/levels/test_trench_selection_input.gd` y ampliar `tests/unit/ui/test_hud.gd` para selección dueño fuera/panel/botón, acción capturada→muerte→reemplazo sin cobrar nuevo, pickup sobre libre/ocupada/actor y solapadas, mouse emulado/toque sin doble orden y terminal; depende de T033.
- [X] T036 [US3] qa-validator: validar T034/T035 contra `specs/005-cinco-carriles/contracts/horizontal-combat.md`; comprobar RED semántico y no solo botón deshabilitado como protección económica; depende de T034 y T035.
- [X] T037 [US3] dev-godot: implementar transacción de recarga/guard de reentrada y retorno físico en `scenes/units/soldado.gd`, con carga completa al aceptar, salud/moral iguales, sin fusil/machete antes de HOME y daño entrante vigente; depende de T036 aprobada.
- [X] T038 [US3] dev-godot: integrar selección por origen/identidad actual y HUD mínimo en `scenes/levels/nivel_monte_calvo.gd`/`scenes/levels/Nivel_MonteCalvo.tscn` y `scenes/ui/HUD.tscn`/`hud.gd`, usando señales/contenedores, consumo GUI y precedencia de picking vigente; depende de T037.
- [X] T039 [US3] godot-tester GREEN: confirmar T034/T035 y regresión pertinente de `tests/unit/{units,levels,ui,systems,enemies}/`, incluidas economía/solapadas, daño en retorno, selección obsoleta, input y terminales; depende de T038.
- [X] T040 [US3] qa-validator: revisión funcional parcial de T037–T039 frente a `specs/005-cinco-carriles/spec.md`, suficiente para continuar pero con gates de entrega pendientes, sin APROBADO de implementación; depende de T039.
- [X] T041 [US3] godot-tester: gate funcional I3 de `specs/005-cinco-carriles/quickstart.md` en Web/APK/.app disponibles con ratón/toque de SO, panel/recarga/retorno/daño y saldo, resize/partida; comparar base/candidato y declarar diferencias/riesgos. Medición física/renderer/paquete final queda en T071; depende de T039.
- [X] T042 [US3] qa-validator: APROBADO PARA INTEGRACIÓN de I3 con verificaciones funcionales T041 y contrato satisfechos; evaluar diferencias/riesgos y declarar certificaciones pendientes en T071, sin inferir otro renderer; fallos reales de fuente/build/función bloquean; depende de T040, T041 completas y T028 aprobada.
- [X] T043 [US3] docs-writer: documentar interacción/recarga aprobadas y límites en `docs/SPEC.md`/`docs/ARCHITECTURE.md`, sin resultados simulados o registros de validación; depende de T042 aprobada.
- [X] T044 [US3] qa-validator: revisar documentación y diff final I3 de `docs/SPEC.md`/`docs/ARCHITECTURE.md` con fuentes T037/T038 y estado probado vigente; depende de T043.
- [X] T045 [US3] project-orchestrator: registrar aprobaciones en `specs/005-cinco-carriles/tasks.md` y preparar PR I3 en borrador `Refs #22`, con base/tamaño/TDD/QA y sin entrega si falta gate obligatorio; depende de T044 aprobada.

## Fase 6 — Composición/presentación transversal · I4

**Objetivo**: trincheras y poses laterales de referencia, estados legibles y cinco filas utilizables en las vistas afectadas.
**Criterio independiente**: filas1/3/5 distinguen fusil dentro, salida/espera/golpe, regreso/daño y derrota; resize no cambia plazas ni mapping de gestos.

- [X] T046 project-orchestrator: tras integración humana del PR I3 T045, preparar rama breve `codex/005-i4-presentacion` desde main actualizado, conservando alcance/IDs y publicación pendiente en T071; depende de T045 integrado y su QA funcional vigente.
- [X] T047 dev-godot: preparar solo interfaz observadora mínima de desplazamiento/retorno en `scenes/units/soldado_visual.gd` y `scenes/enemies/enemigo_visual.gd` para RED invocable, sin nuevas poses/transiciones o autoridad jugable; depende de T046.
- [ ] T048 godot-tester: ampliar `tests/unit/units/test_soldado_visual.gd`, `tests/unit/enemies/test_enemigo_visual.gd` y `tests/unit/ui/test_hud.gd` con RED solo de conducta adicional nueva de I4 (presentación de estados/última bala/retorno, snapshot/reset y adaptación de HUD); ejecutar como regresión GREEN el centrado/resize/mapping de I1 en `tests/unit/levels/test_monte_calvo_framing.gd`/`tests/unit/levels/test_horizontal_board.gd`, sin reconstruir o fabricar RED histórico; sin assertions de píxeles ni RED artificial de arte; depende de T047.
- [ ] T049 qa-validator: validar RED T048 y criterios visuales de `specs/005-cinco-carriles/references/visual-reference.md` contra contrato, separando cobertura existente y arte sin lógica; depende de T048.
- [ ] T050 dev-godot: preparar piezas/poses horizontales de trincheras, fusil/machete/marcha/retorno/caída en `assets/sprites/levels/monte_calvo/`, `assets/sprites/units/monte_calvo/` y `assets/sprites/enemies/monte_calvo/`, con importación/procedencia `SOURCES.md`; no incrustar actores/HUD en fondo ni añadir cobertura; depende de T049 aprobada.
- [ ] T051 dev-godot: integrar recursos/presentación observadora en `scenes/levels/MonteCalvoVisual.tscn`, `scenes/units/soldado_visual.gd`, `scenes/enemies/enemigo_visual.gd` y escenas de actor; adaptar `scenes/levels/monte_calvo_camera.gd`/`scenes/ui/HUD.tscn` sin mover geometría o stats; depende de T050.
- [ ] T052 godot-tester GREEN: confirmar T048 y regresión de `tests/unit/{units,enemies,levels,ui,systems}/`, snapshot/reset/material/generación y ausencia de autoridad de animaciones sobre combate/recursos/ocupación; depende de T051.
- [ ] T053 qa-validator: revisión funcional parcial de T050–T052 con `specs/005-cinco-carriles/references/visual-reference.md` y contrato; registrar suficiencia para consolidar y gates pendientes sin APROBADO de implementación/entrega; depende de T052.
- [ ] T054 godot-tester: gate funcional I4 Web/APK/.app disponibles, visual de estados/filas1/3/5, input real tras resize, carga/partida y comparación base/candidato; declarar diferencias/riesgos. Medición física/renderer/paquete final se conserva en T071, sin certificar hardware desde software; depende de T052.
- [ ] T055 qa-validator: APROBADO PARA INTEGRACIÓN de I4 con T054, criterios visuales y contrato satisfechos; evaluar diferencias/riesgos y conservar certificaciones de publicación en T071; fallos reales de fuente/build/función bloquean; depende de T053, T054 completas y T042 aprobada.
- [ ] T056 docs-writer: consolidar composición/estados aprobados y procedencia útil en `docs/SPEC.md`, `docs/ARCHITECTURE.md` y `assets/sprites/{levels,units,enemies}/monte_calvo/SOURCES.md`, sin logs/evidencias Git; depende de T055 aprobada.
- [ ] T057 qa-validator: revisar documentación/recursos/diff final I4 contra `specs/005-cinco-carriles/references/visual-reference.md` y estado probado, sin ampliar aprobación a entornos no verificados; depende de T056.
- [ ] T058 project-orchestrator: registrar aprobaciones I4 en `specs/005-cinco-carriles/tasks.md` y preparar PR en borrador `Refs #22` con base, binarios/generados aparte y límites; sin promote/merge automático; depende de T057 aprobada.

## Fase 7 — Consolidación y cierre transversal · I5

**Objetivo**: verificar integración sin repetir rutina o trasladar gates anteriores a esta fase.

- [ ] T059 project-orchestrator: tras integración humana del PR I4 T058, preparar rama breve `codex/005-i5-validacion` desde main actualizado; revisar vigencia de evidencia tras integrar y conservar publicación pendiente en T071; depende de T058 integrado y su QA funcional vigente.
- [ ] T060 godot-tester: ejecutar suite completa mediante el comando del quickstart con `tools/ci/run_gut.py` y ruta real al binario Godot y smoke de producción en `scenes/levels/Nivel_MonteCalvo.tscn`; preservar100/población y99/WON, recorrer inicio→terminal y victoria determinista separada; defecto nuevo se devuelve al ciclo TDD, sin rebalance silencioso; depende de T059.
- [ ] T061 godot-tester: consolidar controles funcionales de `specs/005-cinco-carriles/quickstart.md`/SC-001–SC-006, reusar evidencia válida y repetir pendientes/invalidados en sus destinos; declarar SC-007 y certificaciones de publicación pendientes en T071 sin sustituir físico por emulación; depende de T060.
- [ ] T062 qa-validator: evaluar 12 FR y SC funcionales/coherencia integrada T060/T061; emitir APROBADO PARA INTEGRACIÓN sólo con gates funcionales I1–I4 completos. Publicación/SC-007 se evalúa en T071, sin heredar cierre de 004; depende de T014, T028, T042, T055 aprobadas y T061 completa.
- [ ] T063 docs-writer: consolidar comportamiento aprobado/limitaciones útiles en `README.md`, `docs/SPEC.md` y `docs/ARCHITECTURE.md`, sin nuevos archivos de evidencias ni crónicas; depende de T062 aprobada.
- [ ] T064 qa-validator: revisar diff/documentación finales de `README.md`, `docs/SPEC.md` y `docs/ARCHITECTURE.md` contra estado integrado probado y trazabilidad de `specs/005-cinco-carriles/tasks.md`; depende de T063.
- [ ] T065 project-orchestrator: registrar aprobaciones funcionales, revisar bases/tamaño/checklists y preparar PR I5 en borrador Refs #22; usar Closes #22 sólo si además T071 y todos los criterios completos. Con publicación pendiente conservar Issue abierto y declarar integrado funcionalmente, sin promover/mergear ni distribuir; depende de T064 aprobada.

## Transición autorizada — integración y publicación separadas

- [X] T066 docs-writer: preparar enmienda constitucional 4.0.0 y alinear planes/flujo/roles/documentación activa con integración y publicación separadas; conservar historia y SC-007 sin afirmar aceptación; decisión explícita de la persona del 2026-10-19.
- [X] T067 godot-tester RED: escribir y ejecutar pruebas de los workflows Android/iOS que exijan ausencia de deploy por push/merge, workflow_dispatch sólo main, approval_status PENDIENTE por defecto frente a APROBADO PARA PUBLICACIÓN, human_authorized false por defecto y guard antes de checkout/secrets; exigir versionado también manual, sin bypass. Registrar fallo semántico; depende del contrato de T066, no de T068.
- [X] T068 dev-godot: implementar guards de distribución Android/iOS guiados por T067, sin alterar gameplay ni ejecutar pruebas; no distribuir artefactos; depende de RED T067 válido.
- [X] T069 godot-tester GREEN: confirmar T067, regresión de workflows/versionado y vigencia de regresión del juego; ejecutar sólo comprobaciones invalidadas por cambios y declarar estado/errores/límites; sin ejecutar deploy externo; depende de T068.
- [X] T070 qa-validator: revisar enmienda T066, TDD/guards T067–T069 y estado conjunto; APROBADO PARA INTEGRACIÓN sólo con documentación/build/CI/función conformes, conservando pendientes en T071 y 004/T039. No sustituye aceptación funcional 005/T014 y 004/T020; depende de T066, T069, T014, 004/T020 y documentación revisada T016 y 004/T021. Precede a 004/T022, sin dependencia circular.
- [ ] T071 godot-tester y qa-validator, secuenciales: gate abierto de publicación de 005, con artefacto/revisión exactos, renderer y empaquetado final, firma/instalación/versionado, matriz y medición física SC-007/60 FPS de constitución IV. QA sólo emite APROBADO PARA PUBLICACIÓN con requisitos aplicables completos; sin hardware permanece pendiente, sin heredar Xiaomi de 004 ni pedir reconexión. El orquestador exige además autorización humana antes de distribuir; no depende de aprobar publicación para integrar I1–I5.

## Dependencias y oportunidades de paralelo

Ruta funcional: T001→T002→T003→T004→{T005,T006,T007}→T008→T009→T010→T011→T012
→T018→T019→{T020,T021}→T022→T023→T024→T025→T026→T032→T033→{T034,T035}
→T036→T037→T038→T039→T040→T046→T047→T048→T049→T050→T051→T052→T053
→T059→T060→T061. Esta secuencia de comportamiento omite los gates de integración
que se intercalan abajo. T018/T032/T046/T059 requieren el PR anterior integrado
por la persona y main actualizado; una revisión parcial no abre otra rama pendiente.

Rutas de aceptación: I1 T013→T014→T015→T016→T017; I2 T027→T028→T029→T030→T031;
I3 T041→T042→T043→T044→T045; I4 T054→T055→T056→T057→T058. Conservan sus
prerrequisitos GREEN/QA parcial y bases aprobadas indicados en tareas. Cierre
I5 requiere T014/T028/T042/T055 más T061→T062→T063→T064→T065.
La transición añade T066→T067→T068→T069→T070 y revisión conjunta T014/004-T020;
publicación y cierre completo mantienen T071 pendiente por separado.

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
| SC-007 | T071 publicación; T013/T027/T041/T054/T061 aportan muestras disponibles sin acreditar físico |

MVP parcial: I1/US1 da tablero horizontal funcional conservando lo demás
pendiente; se integra sólo con su gate funcional completo; publicación requiere T071. I2 añade machete,
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
