# Tasks: Menú de inicio y nueva partida

**Feature**: `007-menu-inicio-reinicio` · **Issue**: [#32](https://github.com/Juanpvivas/demons/issues/32) · **Input**: [spec](spec.md), [plan](plan.md), [research](research.md), [modelo](data-model.md), [contrato](contracts/match-flow.md), [quickstart](quickstart.md).
**Estado**: 007-I1 en ejecución en `codex/007-i1-menu`, desde `main` actualizado `a97affd` tras PR #33. T001–T022 aprobadas por QA hasta el ciclo lógico completo US1–US3 y su guía; suite/build, matriz visual y de rendimiento, consolidación final, CI y publicación pendientes.
**Flujo**: [desarrollo con agentes](../../docs/DEVELOPMENT_WORKFLOW.md). Tester escribe/ejecuta pruebas; dev implementa sin escribir/ejecutarlas; QA sólo revisa. Sólo el orquestador marca `[X]` tras `APROBADO`. RED aprobado no aprueba implementación.
**Entrega**: un I1 funcional con US1–US3 completas, `Refs #32`, PR en borrador y publicación pendiente. No entregar sólo el menú. Logs/capturas/resultados nuevos quedan en temporales/CI y se resumen en el PR, no en Git.

## Fase 1: Prerrequisitos y contrato invocable

**Objetivo**: preparar una interfaz cargable sin resolver el comportamiento que guiará RED; nunca considerar importación rota como RED.

- [X] T001 project-orchestrator: revisar `specs/007-menu-inicio-reinicio/checklists/requirements.md`, documentos, Issue/base y roles; preparar rama funcional estable, conservar pendientes 004/005/006 y declarar gate de integración, sin distribución.
- [X] T002 dev-godot: crear sólo esqueleto de `scenes/game/GameRoot.tscn`, `scenes/game/game_root.gd`, `scenes/ui/MainMenu.tscn`, `scenes/ui/main_menu.gd` y APIs no-op nuevas de Managers según `specs/007-menu-inicio-reinicio/contracts/match-flow.md`; declarar MENU al final del enum sin activarlo; sin flujo, reset/cancelación, nivel instanciado ni cambio de `project.godot`; depende de T001.
- [X] T003 godot-tester: verificar importación/carga del esqueleto y runner de `tests/unit/` con `tools/ci/run_gut.py`; caracterizar base sin crear RED artificial ni modificar gameplay; depende de T002.
- [X] T004 qa-validator: revisar límite de setup, contratos y carga en `scenes/game/game_root.gd`/`scenes/ui/main_menu.gd` y Managers; aprobar sólo invocabilidad sin resolver conducta, confirmando entrada original intacta; depende de T003.

## Fase 2: US1 — Menú inerte e inicio explícito (P1)

**Criterio independiente**: apertura real sin partida; «Jugar» inicia una sola con condiciones vigentes. Cubre FR-001–003/008–010 y SC-001/004–006.

- [X] T005 [US1] godot-tester RED: crear `tests/unit/game/test_game_root.gd` y `tests/unit/ui/test_main_menu.gd`, ampliar `tests/unit/systems/test_game_state_manager.gd`; ejecutar aserciones de entrada real todavía automática, menú sin nivel/oleadas, MENU inicial sin resultado, inicio único, foco y gesto no propagado; fallo semántico, no import/parser; depende de T004.
- [X] T006 [US1] qa-validator: revisar pruebas y RED de T005 contra `specs/007-menu-inicio-reinicio/spec.md`; aprobar sólo calidad/fallo esperado, sin dar por entregado menú o inicio; depende de T005.
- [X] T007 [US1] dev-godot: implementar raíz/menú pictórico en `scenes/game/` y `scenes/ui/MainMenu.tscn`, conectar intención de inicio y cambiar `project.godot`; activar MENU/enter_menu en `autoloads/game_state_manager.gd` sin renumerar PLAYING/PAUSED/WON/LOST ni cambiar combate; depende de T006 aprobado.
- [X] T008 [US1] godot-tester GREEN: repetir T005 y regresión de `tests/unit/{systems,ui,levels}/`, incluyendo consumidores/fixtures que asumían PLAYING inicial, entrada real, cinco soldados/reserva cero y exclusión de gesto; adaptar sólo expectativas legítimamente modificadas, sin fingir RED histórico; depende de T007.
- [X] T009 [US1] qa-validator: contrastar menú/inicio, fuente, RED/GREEN y arte reutilizado con `specs/007-menu-inicio-reinicio/contracts/match-flow.md`; validar sólo US1, sin entregar aún I1; depende de T008.
- [X] T010 [P] [US1] docs-writer: documentar únicamente inicio/menú aprobados en `docs/SPEC.md` y notas útiles de `docs/ARCHITECTURE.md`, manteniendo repetición aún pendiente; revisión documental en T031; depende de T009 aprobado.

## Fase 3: US2 — Resultado y repetición limpia (P1)

**Criterio independiente**: WON y LOST → «Volver a jugar», tres ciclos por resultado, sin estado ni actividad anterior. Cubre FR-004–008/011 y SC-002–004/006.

- [X] T011 [P] [US2] godot-tester RED: ampliar `tests/unit/game/test_game_root.gd`, `tests/unit/ui/test_hud.gd`, `tests/unit/systems/test_wave_manager.gd` y `test_game_state_manager.gd`; probar cancelación sin señales de victoria/progreso, teardown efectivo antes de nuevos wave_started, reset y retry desde ambos resultados reales del fixture; depende de T009 aprobado, nunca de T013.
- [X] T012 [US2] qa-validator: revisar RED T011 y oráculos de reset/liberación en `tests/unit/game/test_game_root.gd`; rechazar esperas ciegas o enum terminal forzado como sustituto del recorrido; depende de T011.
- [X] T013 [US2] dev-godot: implementar retry y cierre idempotente en `scenes/game/game_root.gd`, `scenes/levels/nivel_monte_calvo.gd`, `wave_spawner.gd`, `scenes/ui/HUD.tscn`/`hud.gd` y `autoloads/wave_manager.gd`; cancelar sin start_waves([]), desconectar/retirar/liberar árbol antes de rearmar, bloquear reentrada/orígenes viejos y añadir intenciones de botones; depende de T012 aprobado.
- [X] T014 [US2] godot-tester GREEN: repetir T011 y comprobar tres retries consecutivos desde cada resultado en `tests/unit/game/test_game_root.gd`, sin heredar salud/carga/moral, reserva, plazas, selección, órdenes, cajas, efectos, cursor o callbacks; regresión de HUD/Managers/spawners y entrada pertinente; depende de T013.
- [X] T015 [US2] qa-validator: revisar fuente y RED/GREEN de retry con `specs/007-menu-inicio-reinicio/data-model.md`, confirmando generación antigua aislada, liberación observable y reglas 1 inicial + 99 WAVE intactas; depende de T014.
- [X] T016 [P] [US2] docs-writer: documentar repetición aprobada y límite fixture/producción en `docs/SPEC.md`/`docs/ARCHITECTURE.md`, sin declarar regreso al menú entregado; revisión documental en T031; depende de T015 aprobado.

## Fase 4: US3 — Volver al menú y completar el ciclo (P2)

**Criterio independiente**: WON y LOST → «Menú principal» → espera → «Jugar», tres ciclos por resultado. Completa FR-005/007–011 y SC-001–005.

- [X] T017 [P] [US3] godot-tester RED: ampliar `tests/unit/game/test_game_root.gd`/`tests/unit/ui/test_hud.gd` para regreso al menú desde ambos resultados, inactividad y nuevo inicio, alternancia de botones y origen/avisos tardíos; depender sólo de contratos e implementación US2 aprobada en T015, no de T019.
- [X] T018 [US3] qa-validator: revisar RED T017 contra `specs/007-menu-inicio-reinicio/contracts/match-flow.md`, comprobando gesto/UI y estado, sin aceptar sólo conteo de nodos; depende de T017.
- [X] T019 [US3] dev-godot: completar destino menú y conexiones de UI en `scenes/game/game_root.gd`, `scenes/ui/main_menu.gd` y `scenes/levels/nivel_monte_calvo.gd`; mismo cierre compartido, foco, márgenes/aspectos y bloqueo de tablero, sin pausa ni APIs paralelas de reset; depende de T018 aprobado.
- [X] T020 [US3] godot-tester GREEN: repetir T017 y el conjunto `tests/unit/game/test_game_root.gd`/`tests/unit/ui/`; cubrir las cuatro combinaciones terminal × acción con tres ciclos cada una, menú sin actividad y gesto consumido, sin duplicar conexiones/partidas; depende de T019.
- [X] T021 [US3] qa-validator: revisar ciclo completo y RED/GREEN con `specs/007-menu-inicio-reinicio/spec.md`; confirmar equivalencia de inicio directo/desde menú y ninguna herencia residual; depende de T020.
- [X] T022 [US3] docs-writer: documentar regreso/flujo completo aprobado en `docs/SPEC.md` y guía de usuario de `README.md`, conservando verificaciones/plataformas aún pendientes; revisión documental en T031; depende de T021 aprobado.

## Fase final: Verificación y entrega de I1

- [ ] T023 godot-tester: ejecutar suite completa de `tests/unit/` con `tools/ci/run_gut.py`, importación y exportaciones/build aplicables usando `tools/web/export.sh` y procedimientos nativos vigentes; no cambiar renderer/presets/versiones; reportar fallos y revisión exacta; depende de T021.
- [ ] T024 godot-tester: ejecutar `specs/007-menu-inicio-reinicio/quickstart.md` por UI en Chrome de computador y apps Android/iOS disponibles: 60 s en apertura/menú tras cada resultado, cuatro rutas × tres ciclos, foco/ratón/teclado/toque, resize, clicks-through y estilo; fixture separado del smoke de producción y sin equiparar WON reducido a victoria manual de100; depende de T023.
- [ ] T025 godot-tester: comparar base/candidata y carga/transición/gameplay equivalentes según `specs/007-menu-inicio-reinicio/quickstart.md`, con repeticiones/entornos/poblaciones y límites; reportar caídas sin atribución causal ni certificar 60 FPS físicos; restaurar apps normales/datos y limpiar sólo procesos propios; depende de T024.
- [ ] T026 qa-validator: revisar código, T023–T025 y cobertura FR/SC de `specs/007-menu-inicio-reinicio/spec.md`; dictaminar alcance funcional/visual y riesgos, diferenciando fixture, producción, integración y publicación; CI exacta y documentación final se revisan en T031; depende de T025.
- [ ] T027 docs-writer: consolidar sólo alcance aprobado en `README.md`, `docs/SPEC.md`, `docs/ARCHITECTURE.md` y documentos `specs/007-menu-inicio-reinicio/`, sin editar checkboxes/tareas o volcar logs; conservar pendientes anteriores y publicación; depende de T010, T016, T022 y T026 aprobado.
- [ ] T028 godot-tester: comprobar vigencia de pruebas/build de T023 tras consolidación `specs/007-menu-inicio-reinicio/` y repetir sólo verificaciones invalidadas por cambios; reportar estado exacto para QA; depende de T027.
- [ ] T029 qa-validator: revisar consistencia final de documentación/código y T028 contra `specs/007-menu-inicio-reinicio/spec.md`, sin aprobar todavía CI no ejecutada ni publicación; devolver defectos al rol responsable; depende de T028.
- [ ] T030 project-orchestrator: revisar diff/base de `specs/007-menu-inicio-reinicio/`, publicar rama funcional y crear PR en borrador `Refs #32`; esperar CI automática de revisión exacta, sin promover/fusionar o distribuir y sin reescribir historial compartido; depende de T029 aprobado.
- [ ] T031 qa-validator: revisar estado final, documentación de `specs/007-menu-inicio-reinicio/`, reportes RED/GREEN/build/matriz y CI exacta del PR; emitir APROBADO PARA INTEGRACIÓN sólo si cumplen, declarando variantes/riesgos y publicación pendiente; depende de T030 y CI correcta.
- [ ] T032 project-orchestrator: registrar sólo tareas/alcance aprobados en `specs/007-menu-inicio-reinicio/tasks.md`, resumir resultados/límites en PR en borrador y entregar enlace; conservar Issue y publicación pendientes, recomendar Squash and merge sin ejecutarlo; depende de T031 aprobado.

## Dependencias, paralelismo y estrategia

- Cadena funcional: T001–T009 → T011–T015 → T017–T021 → T023–T032. RED no depende de su implementación; QA de RED sólo aprueba el fallo esperado. Arte estático usa revisión visual, sin RED artificial.
- `[P]` permite T010 con T011, o T016 con T017, tras su QA común: documentación y pruebas usan archivos distintos. No paralelizar los cambios a `game_root.gd`, Managers, HUD, pruebas compartidas o ejecuciones sobre el mismo dispositivo.
- T027 reúne esos borradores documentales y T031 valida su estado final. Los tests pertenecen al tester; dev no los modifica/ejecuta. Las correcciones vuelven al dueño y repiten sólo evidencia invalidada.
- La preparación no ejecuta ninguna tarea. Las tres historias forman un solo I1; QA de una historia o de RED no autoriza un PR funcional incompleto. Gate físico/60 FPS/artefacto final y autorización de publicación permanecen separados, sin tarea de distribuir en este alcance.
