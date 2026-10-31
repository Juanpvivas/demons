# Tasks: Comandante con memoria — carriles V1

**Feature**: `017-comandante-memoria` · **Fecha**: 2026-10-31 · **Base documental**: `c227982`.
**Input**: [spec](spec.md), [plan](plan.md), [investigación](research.md),
[modelo](data-model.md), [contrato](contracts/commander.md), [guía](quickstart.md).
**Flujo**: [DEVELOPMENT_WORKFLOW](../../docs/DEVELOPMENT_WORKFLOW.md).
**Estado**: I1 (T001–T025) autorizado; marcado sólo tras QA del alcance. I2 y publicación continúan pendientes.
**Tracking**: [Issue #65](https://github.com/Juanpvivas/demons/issues/65); rama I1 `codex/017-i1-comandante-memoria` desde `main` / `e8407ec`.
No se reutiliza ni cierra el Issue #63 de016.

## Formato, autorización y límites

- Sólo project-orchestrator marca `[X]` después de APROBADO del qa-validator
  para el alcance exacto; RED aprobado no entrega su implementación.
- Leer instrucciones de cada rol en `.claude/agents/`, constitución, spec,
  contrato y esta lista antes de ejecutar. GodotPrompter se descubre localmente;
  no fijar rutas personales ni precargar speckit-implement.
- dev-godot no escribe/modifica/ejecuta pruebas. godot-tester no modifica
  implementación. qa-validator revisa en sólo lectura; docs-writer documenta.
- Todo RED requiere aserción semántica, no fallo de import/parser/API ausente.
  Setup nuevo sólo habilita llamadas neutrales, sin comportamiento o excepciones
  NotImplemented. Pruebas de regresión ya GREEN no se rompen para fabricar RED.
- Resultados/comandos/límites van al PR/CI y temporales, no a archivos nuevos
  de evidencias en Git. No usar estos documentos como crónica de ejecución.
- Ninguna tarea autoriza merge, promover PR o distribuir. Publicación conserva
  autorización humana, artefacto y gate distintos; beta1.0.3 no cubre017.
- Ningún cambio de tipos, cantidades, stats, tiempos, IA individual, Managers,
  project.godot, renderer o workflows está previsto. Conservar INITIAL central,
  diez oleadas/99 WAVE/A,A,R y bloque global5;006 sigue pausada y #61/#53 intactos.
- Todas las dependencias indicadas deben estar aprobadas para ejecutar la tarea.
  Las de coordinación/CI son prerrequisitos operativos; no constituyen permiso
  para omitir GREEN o revisión. Rechazos vuelven al dueño; tercer rechazo
  consecutivo o AMBIGUO escalan a la persona según el flujo.

## Fase 1: Preparación de ejecución I1

**Objetivo**: autorizar y aislar el incremento interno, sin activar gameplay.
Estas tareas se ejecutarán sólo tras una petición posterior de implementación.

- [X] T001 project-orchestrator: verificar Git y contexto en `specs/017-comandante-memoria/plan.md`, preservar `output/` y016/T009–T011; confirmar prioridad de ejecución si016 sigue pendiente, buscar/reusar un Issue único017 (incluidos cerrados), preparar rama I1 desde main actualizado o base explícita y registrar identidad de rama/Issue en documentos017. No implementar, probar ni cerrar016. Depende de autorización futura de ejecución. Cubre FR-016.
- [X] T002 qa-validator: revisar preparación completa en `specs/017-comandante-memoria/{spec,plan,tasks}.md`, `data-model.md`, `contracts/commander.md`, `quickstart.md` y checklist; contrastar constitución y decisiones Q1/Q2; emitir veredicto sólo documental para I1, sin aprobar código inexistente o publicación. Depende T001. Cubre FR-016.
- [X] T003 godot-tester: comprobar runner/importación y suite base no vacía con `tools/ci/run_gut.py` y GUT existente en `tests/unit/`; confirmar motor4.7.1/GUT9.7.1 y aislamiento de rutas de memoria. Reportar errores base sin atribuirlos a017 ni declarar RED; no crear infraestructura o cambiar CI si ya funciona. Depende T002. Cubre FR-016.

## Fase 2: Interfaz neutral I1

**Objetivo**: APIs importables que permitan RED por conducta ausente.

- [X] T004 dev-godot: declarar únicamente tipos/campos/firmas neutrales de `core/commander_session.gd`, `core/commander_memory_store.gd` y `resources/schemas/commander_config.gd`, siguiendo contrato y modelo, sin `.tres` de parámetros aún. Exportar campos neutrales, retornar null/false/datos vacíos según firma; sin RNG, selección, aprendizaje, validación/I/O o control de menú. No escribir/ejecutar tests. Depende T003. Skills: resource-pattern, save-load. Cubre FR-016.
- [X] T005 godot-tester: verificar carga/llamabilidad neutral de los tres scripts de T004 desde GUT y mantener `tests/unit/systems/` importable; contrastar que las pruebas futuras podrán fallar por conducta. No aprobar selección/aprendizaje ni fabricar RED desde retornos incompatibles con el parser. Depende T004. Skills: godot-testing. Cubre FR-016.
- [X] T006 qa-validator: revisar setup T004/T005 contra `specs/017-comandante-memoria/contracts/commander.md`; confirmar neutralidad, firmas y límites de datos sin comportamiento anticipado. Aprobar sólo infraestructura mínima. Depende T005. Skills: resource-pattern, godot-code-review. Cubre FR-016.

## Fase 3: US1 — selector acotado I1 (P1)

**Objetivo**: núcleo que propone carriles, sin conexión al juego todavía.
**Criterio independiente**: con snapshots inyectados, misma semilla/memoria
reproduce elecciones;0–255 produce variantes legales en99 apariciones.

- [ ] T007 [US1] godot-tester: escribir/ejecutar RED semántico en `tests/unit/systems/test_commander_session.gd` para configuración/rangos, contextos360, pendientes del bloque global5,19 permutaciones+4 distintos, pesos/p positivos y razón≤5/3, RNG independiente, m1, propuesta única, register idempotente y cancel_proposal con rollback. Usar semillas0–255, memoria neutral/extrema y oráculos analíticos del contrato; no importar datos de usuario. Depende T006. Skills: godot-testing, resource-pattern. Cubre FR-004–007/010; SC-002/003.
- [ ] T008 [US1] qa-validator: revisar RED T007 y APIs neutrales en `tests/unit/systems/test_commander_session.gd` y `core/commander_session.gd`; verificar aserción por comportamiento y no importación, independencia del oráculo y cobertura de frontera de bloques. No aprobar implementación. Depende T007. Skills: godot-testing, godot-code-review. Cubre FR-004–007/010.
- [ ] T009 [US1] dev-godot: implementar sólo configuración válida, contexto, copia inicial, selector/transacción propuesta/confirmación/cancelación y registros de aparición en `core/commander_session.gd`, `resources/schemas/commander_config.gd` y nuevo `resources/director/monte_calvo_commander.tres`. Usar valores/rangos del modelo, memoria sin mutar y máximo99 registros; no aprendizaje/cierre/Store real, nodos, timer o gameplay integrado aún. No tests/runs. Depende T008. Skills: resource-pattern. Cubre FR-004–007/010; SC-002/003.
- [ ] T010 [US1] godot-tester: confirmar GREEN T007 y regresión pertinente en `tests/unit/systems/test_commander_session.gd`; comprobar que contextos se derivan de datos suministrados y cambios de RNG cosmético no alteran secuencia. No usar coincidencia con un selector propio como oráculo. Depende T009. Skills: godot-testing. Cubre SC-002/003.
- [ ] T011 [US1] qa-validator: revisar selector/configuración y evidencia RED/GREEN en `core/commander_session.gd` y `resources/director/monte_calvo_commander.tres`; aprobar sólo núcleo US1, sin nivel/oleadas o equilibrio certificados. Depende T010. Skills: resource-pattern, godot-code-review. Cubre FR-004–007/010; SC-002/003.

## Fase 4: US2 — aprendizaje y persistencia I1 (P1)

**Objetivo**: experiencia contextual atribuible, guardada sólo desde terminales.
**Criterio independiente**: experiencias controladas cambian preferencias y se
recuperan del Store; abandonos, duplicados y vivos censurados no aprenden.

- [ ] T012 [US2] godot-tester: escribir/ejecutar RED en `tests/unit/systems/test_commander_session.gd` y nuevo `tests/unit/systems/test_commander_memory_store.gd`: avance normalizado/cruce, censura, INITIAL excluido, media por celda/partida, q0.575/n1 desde prior con r1, reversión/olvido/confianza, memoria congelada, finish una vez, abandono y cero muestras sin cambios. Cubrir esquema/hash/128KiB/360celdas/rangos, fingerprint de config+contenido+geometría, slots/generación/compatibilidad/conflicto y save/read/flush fallidos; TRANSIENT publica RAM sin I/O y saved=false. Inyectar rutas temporales/fakes sin tocar user:// real. No probar borrado aún. Depende T011. Skills: godot-testing, save-load, resource-pattern. Cubre FR-008–012/015; SC-004/005.
- [ ] T013 [US2] qa-validator: auditar RED T012 en `tests/unit/systems/test_commander_memory_store.gd` y pruebas de Session contra `contracts/commander.md`; comprobar crédito por activación, exclusión de censurados y fallos de disco reales/simulados declarados sin acreditar navegador. Depende T012. Skills: godot-testing, save-load, godot-code-review. Cubre FR-008–012/015.
- [ ] T014 [US2] dev-godot: implementar registro/cierre de resultados y candidato de aprendizaje en `core/commander_session.gd`, y load/save/fingerprint/validación/slots/TRANSIENT en `core/commander_memory_store.gd`, según fórmulas/esquema del contrato. Sólo WON/LOST con muestras cambia memoria; guard anterior a callbacks, media por celda y Store publica tras verificación. Borrado permanece neutral para US3. No tests/runs. Depende T013. Skills: resource-pattern, save-load. Cubre FR-008–012/015; SC-004/005.
- [ ] T015 [US2] godot-tester: verificar GREEN T012, llamadas duplicadas/otra generación, memoria inválida/ausente, cambio de balance incompatible, slot antiguo no resucitado por compatibilidad y regresión del selector en `tests/unit/systems/test_commander_session.gd` y `test_commander_memory_store.gd`; diferenciar pruebas de archivos reales temporales y dobles. Depende T014. Skills: godot-testing, save-load. Cubre SC-004/005.
- [ ] T016 [US2] qa-validator: revisar código y RED/GREEN de `core/commander_session.gd` y `core/commander_memory_store.gd`; confirmar rangos, idempotencia, aprendizaje efectivo y límites correlacionales/censura. Aprobar sólo módulo interno, no persistencia Web o partidas reales. Depende T015. Skills: resource-pattern, save-load, godot-code-review. Cubre FR-008–012/015; SC-004/005.

## Fase 5: US3 — borrado del almacén I1 (P1)

**Objetivo**: poder neutralizar experiencia sin recuperar una copia vieja.
**Criterio independiente**: clear persistente elimina ambos slots; clear
TRANSIENT sólo modifica RAM. Fallos no se comunican como éxito.

- [ ] T017 [US3] godot-tester: escribir/ejecutar RED de clear en `tests/unit/systems/test_commander_memory_store.gd`: inactivo antes de activo, ausencia comprobada de ambos, reinicio neutral, copias inválidas, fallos de eliminación/verificación con RAM preservada y disco revalidado, y TRANSIENT sin I/O/saved=false. Usar un archivo testigo ajeno para acreditar que clear no borra datos de intro u otros archivos. Depende T016. Skills: godot-testing, save-load. Cubre FR-011/012/015; SC-005.
- [ ] T018 [US3] qa-validator: revisar RED de `tests/unit/systems/test_commander_memory_store.gd` contra borrado persistente/TRANSIENT del contrato; validar fallos parciales y separación de datos ajenos sin tocar memoria real. Depende T017. Skills: godot-testing, save-load, godot-code-review. Cubre FR-011/012/015.
- [ ] T019 [US3] dev-godot: implementar clear en `core/commander_memory_store.gd`, sin backup recuperable ni reintentos que repueblen memoria, y resultados explícitos para éxito persistente/TRANSIENT/fallo. No UI ni tests/runs. Depende T018. Skills: save-load. Cubre FR-011/012/015; SC-005.
- [ ] T020 [US3] godot-tester: comprobar GREEN T017 y regresión de load/save/Session en `tests/unit/systems/test_commander_memory_store.gd` y `test_commander_session.gd`; cierre/reapertura temporal y archivo testigo intacto. Depende T019. Skills: godot-testing, save-load. Cubre SC-005.
- [ ] T021 [US3] qa-validator: revisar Store completo, datos autorados y RED/GREEN de `core/commander_memory_store.gd`; confirmar que el módulo I1 no tiene conexiones a gameplay ni se presenta como feature jugable terminada. Depende T020. Skills: save-load, godot-code-review. Cubre FR-011/012/015; SC-005.

## Fase 6: Entrega interna I1 y prerrequisitos I2

**I1** termina el módulo interno T001–T025, no la aceptación jugable de US1–US3.
No publicar un PR de implementación con RED o comportamiento interno pendientes.

- [ ] T022 docs-writer: documentar sólo módulo I1 aprobado y límites en `docs/ARCHITECTURE.md` y `specs/017-comandante-memoria/plan.md`; no afirmar que cambia las oleadas o que el menú ya borra memoria. Dependencia T021. No pruebas. Cubre FR-016.
- [ ] T023 project-orchestrator: publicar rama I1 y comprobar CI del head exacto en `.github/workflows/ci.yml` con reportes de godot-tester/GREEN y documentación T022; conservar workflows/guards existentes y solicitar revisión documental de docs por QA. No ejecutar pruebas ni modificar CI. Depende T022. Cubre FR-016.
- [ ] T024 qa-validator: revisar documentación T022, alcance I1, fuente, suites y CI del SHA exacto contra `specs/017-comandante-memoria/plan.md`; emitir APROBADO PARA INTEGRACIÓN sólo del núcleo aislado si procede, sin acreditar juego, móvil, hardware o distribución. Depende T023. Skills: godot-code-review. Cubre FR-016.
- [ ] T025 project-orchestrator: actualizar Issue017 y crear/adjuntar PR borrador I1 según `docs/DEVELOPMENT_WORKFLOW.md`, con Refs, IDs T001–T024, RED/GREEN/CI/QA/límites en cuerpo breve; todos los SC jugables/publicación pendientes conservados. No promover, fusionar, subir builds ni reescribir historia. Depende T024. Cubre FR-016.
- [ ] T026 project-orchestrator: preparar rama I2 y base en `specs/017-comandante-memoria/plan.md`; partir de main actualizado con I1 integrado por la persona o declarar explícitamente dependencia apilada/base SHA de su PR, sin merge automático. Verificar diff y transferir contexto aprobado a roles antes de continuar. Depende T025. Cubre FR-016.
- [ ] T027 dev-godot: añadir sólo firmas/propiedades/señales neutrales necesarias en `scenes/game/game_root.gd`, `scenes/levels/nivel_monte_calvo.gd`, `scenes/levels/wave_spawner.gd` y `scenes/ui/main_menu.gd` para inyección de Store/seed/Session y llamada de intención/feedback del contrato. No conectarlas, crear UI, cargar/escribir archivos o cambiar carril/Timer/terminal. Mantener firmas existentes compatibles; sin tests/runs. Depende T026. Skills: event-bus, resource-pattern, godot-ui. Cubre FR-016.
- [ ] T028 godot-tester: comprobar carga neutral y regresión base de I2 en `tests/unit/game/test_game_root.gd`, `tests/unit/ui/test_main_menu.gd` y `tests/unit/levels/test_horizontal_wave_spawner.gd`; confirmar APIs para RED semántico sin alterar fakes para simular conducta inexistente. Depende T027. Skills: godot-testing. Cubre FR-016.
- [ ] T029 qa-validator: revisar setup neutral T027/T028 en las rutas de `scenes/` anteriores contra `specs/017-comandante-memoria/contracts/commander.md`; no aceptar integración anticipada, callbacks productivos o I/O como prerrequisito de RED. Depende T028. Skills: godot-code-review, event-bus. Cubre FR-016.

## Fase 7: US1 — integración del reparto I2 (P1)

**Objetivo**: nivel real usa Session sólo para carril al vencer el Timer.
**Criterio independiente**: mismos tipos/99 WAVE/intervalos, INITIAL central;
variedad con semillas y bloques que no se reinician al cambiar oleada.

- [ ] T030 [US1] godot-tester: escribir/ejecutar RED de inyección y selección real en `tests/unit/levels/test_commander_integration.gd` (nuevo), `tests/unit/levels/test_horizontal_wave_spawner.gd` y `tests/unit/game/test_game_root.gd`. Contrastar Resources aplanados/tiempos/perfiles, contexto público al spawn, INPUT futuro excluido, carga antes de activar, INITIAL fuera del bloque, rollback si no activa, pausa/cierre y camino legado sin Session. Los invariantes existentes son regresión; RED corresponde a uso de comandante/variedad/inyección ausentes. Depende T029. Skills: godot-testing, resource-pattern. Cubre FR-001–007/013; SC-001–003.
- [ ] T031 [US1] qa-validator: revisar RED T030 y casos de regresión en `tests/unit/levels/test_commander_integration.gd` contra spec; exigir fallos por integración ausente, no romper el cursor legado o Timer para fabricar RED. Depende T030. Skills: godot-testing, godot-code-review. Cubre FR-001–007/013.
- [ ] T032 [US1] dev-godot: integrar Store/seed antes de add_child en `scenes/game/game_root.gd`, Session/contextos antes del primer WAVE en `scenes/levels/nivel_monte_calvo.gd` y choose/register/cancel en `scenes/levels/wave_spawner.gd`. Escena directa usa TRANSIENT; producción siempre instala Session. Mantener cola/pop/activación/rearme, orden A,A,R, stats, INITIAL y Managers. Aún no conectar aprendizaje a terminales ni menú de borrado; no tests/runs. Depende T031. Skills: resource-pattern, event-bus. Cubre FR-001–007/013; SC-001–003.
- [ ] T033 [US1] godot-tester: confirmar GREEN T030, calendario completo previsto y regresión de oleadas/combate/economía en `tests/unit/levels/test_commander_integration.gd`, `test_horizontal_wave_spawner.gd`, `test_nivel_montecalvo.gd` y suites existentes de `tests/unit/systems/`/`tests/unit/units/`; no acreditar victoria de partida completa desde aplanar Resources. Depende T032. Skills: godot-testing. Cubre SC-001–003/FR-013.
- [ ] T034 [US1] qa-validator: revisar selección integrada, source y RED/GREEN de `scenes/levels/wave_spawner.gd` y nivel; confirmar uso exclusivo del carril, ausencia de recolocación/delays y carga observada correcta. Aprobar alcance US1, sin entregar aún el PR jugable I2. Depende T033. Skills: resource-pattern, godot-code-review. Cubre FR-001–007/013; SC-001–003.

## Fase 8: US2 — resultados y ciclo real I2 (P1)

**Objetivo**: sólo terminales reales consolidan experiencia de actores propios.
**Criterio independiente**: última baja antes de WON y cruce antes de LOST;
Retry recuerda y abandono no aprende, sin doble conteo por pool o callbacks.

- [ ] T035 [US2] godot-tester: escribir/ejecutar RED de cableado real en `tests/unit/levels/test_commander_integration.gd` y `tests/unit/game/test_game_root.gd`: record_defeat antes de notify/release y cruce antes de reportar LOST, snapshot de posición/generación/origen, última baja, INITIAL causante, censura, sólo game_won/game_lost, abandono/close_match/MENU/Retry, nivel retirado y errores de save con siguiente partida no contaminada. Usar sistemas y pool reales donde se comprueba orden; rutas temporales/TRANSIENT para aislamiento. Depende T034. Skills: godot-testing, save-load, event-bus. Cubre FR-008–013/015; SC-004/005.
- [ ] T036 [US2] qa-validator: revisar RED y orden real previsto en `tests/unit/levels/test_commander_integration.gd`/`tests/unit/game/test_game_root.gd`; asegurar que dobles no ocultan WON síncrono ni reuso de actor. Depende T035. Skills: godot-testing, godot-code-review. Cubre FR-008–013/015.
- [ ] T037 [US2] dev-godot: conectar resultados/terminal/abandono en `scenes/levels/wave_spawner.gd`, `scenes/levels/nivel_monte_calvo.gd` y `scenes/game/game_root.gd`, siguiendo orden del contrato y guards antes de escritura/callbacks. Guardar candidato sólo con muestras, Store verificado o TRANSIENT explícito; desconectar al cerrar, no aprender desde MENU/Retry ni modificar Enemigo/Soldado/Managers. Conservar el error de save para feedback US3; sin tests/runs. Depende T036. Skills: event-bus, save-load, resource-pattern. Cubre FR-008–013/015; SC-004/005.
- [ ] T038 [US2] godot-tester: confirmar GREEN T035 y regresión en `tests/unit/levels/test_commander_integration.gd`, `tests/unit/game/test_game_root.gd` y `tests/unit/systems/test_commander_memory_store.gd`; verificar pool R→A→R, señales de terminal y memoria distinta entre neutral/acumulada sin cambiar otros recursos. Depende T037. Skills: godot-testing, save-load. Cubre SC-004/005/FR-013.
- [ ] T039 [US2] qa-validator: revisar fuente/ciclo, RED/GREEN e integridad en `scenes/levels/nivel_monte_calvo.gd` y `scenes/levels/wave_spawner.gd`; aprobar sólo comportamiento acreditado, no extrapolar archivos temporales a IndexedDB/nativos físicos. Depende T038. Skills: event-bus, save-load, godot-code-review. Cubre FR-008–013/015; SC-004/005.

## Fase 9: US3 — control de memoria y feedback I2 (P1)

**Objetivo**: menú permite borrar con confirmación, guardas y feedback fiel.
**Criterio independiente**: confirmar/cancelar/fallar tienen efectos distintos;
no aceptar mientras hay nivel, intro o transición ni alterar progreso narrativo.

- [ ] T040 [US3] godot-tester: escribir/ejecutar RED en `tests/unit/ui/test_main_menu.gd` y `tests/unit/game/test_game_root.gd` para intención de borrado, confirmación/cancelación/doble gesto, guardas MENU sin nivel/intro/transición, bloqueo set_start_enabled, feedback persistente/TRANSIENT/fallo y error de save terminal visible. Verificar señal/UI real, IntroProgress testigo intacto, foco y semántica de input; separar layout visual de conducta automatizable. Depende T039. Skills: godot-testing, godot-ui. Cubre FR-011–013/015; SC-005.
- [ ] T041 [US3] qa-validator: auditar RED T040 y textos/guardas del contrato en `tests/unit/ui/test_main_menu.gd` y `tests/unit/game/test_game_root.gd`; no exigir RED artificial para arte o disposición de controles. Depende T040. Skills: godot-testing, godot-ui, godot-code-review. Cubre FR-011–013/015.
- [ ] T042 [US3] dev-godot: implementar intención/confirmación/estado en `scenes/ui/main_menu.gd` y `scenes/ui/MainMenu.tscn`, y autorización/clear/feedback de Store en `scenes/game/game_root.gd`. Reutilizar Theme/safe area/64px, foco circular, consumir gesto y bloquear reentrada. Error terminal se muestra en resultado o menú según contrato sin rediseñar HUD; ningún control escribe disco por su cuenta. No tests/runs. Depende T041. Skills: godot-ui, responsive-ui, event-bus, save-load. Cubre FR-011–013/015; SC-005.
- [ ] T043 [US3] godot-tester: confirmar GREEN T040 y regresión de raíz/menú/intro en `tests/unit/game/test_game_root.gd`, `tests/unit/ui/test_main_menu.gd` y suites existentes; verificar visualmente legibilidad, foco y activación por ratón/teclado/toque en entornos disponibles, sin modificar código. Depende T042. Skills: godot-testing, godot-ui, responsive-ui. Cubre FR-011–013/015; SC-005.
- [ ] T044 [US3] qa-validator: revisar UI/raíz y RED/GREEN de `scenes/ui/MainMenu.tscn`, `scenes/ui/main_menu.gd` y `scenes/game/game_root.gd`; contrastar éxito y fallos reales, accesibilidad y datos ajenos. Aprobar sólo alcance disponible, sin gate de publicación. Depende T043. Skills: godot-ui, godot-code-review. Cubre FR-011–013/015; SC-005.

## Fase final: Regresión, equilibrio, documentación y gates I2

**Objetivo**: entregar I2 funcional con evidencia proporcional, separando
publicación física/artefacto final. No cerrar la feature desde un merge parcial.

- [ ] T045 godot-tester: ejecutar regresión completa con `tools/ci/run_gut.py`, importación/builds aplicables y recorridos de `specs/017-comandante-memoria/quickstart.md` en Web de computador y apps Android/iOS disponibles. Acreditar recarga real por origen/navegador, caso sin persistencia, terminal→Retry, abandono, borrado y controles; comparar carga/rendimiento observado con base en entornos disponibles, declarando caídas y límites sin campaña006 ni certificación60FPS física. Conservar renderer/presets y no distribuir artefactos. Depende T044. Skills: godot-testing, godot-debugging, save-load, godot-ui. Cubre FR-001–015; SC-001–005/007 funcional.
- [ ] T046 godot-tester: ejecutar exactamente el protocolo de balance de `specs/017-comandante-memoria/quickstart.md`: seis partidas terminales de entrenamiento real y doce comparables (42/43/44×S1/S2×neutral/acumulada) con snapshots restaurados por intento; comprobar al menos una victoria por condición y respuestas posibles, revisar derrotas tempranas y frontera entre bloques. Extremos sintéticos sólo acreditan límites. Si falta aprendizaje/muestra o falla criterio, reportar sin ajustar stats/tipos/cantidades/tiempos ni llamar PASS a datos ausentes. Depende T045. Skills: godot-testing. Cubre FR-014; SC-006.
- [ ] T047 qa-validator: revisar regresión, matriz funcional y playtesting T045/T046 contra `specs/017-comandante-memoria/spec.md` y `quickstart.md`; examinar peores observaciones de rendimiento, censura/experiencia y límites de muestra. Emitir veredicto de alcance funcional/equilibrio o rechazo con causa; hardware/artefacto no acreditados permanecen pendientes. Depende T046. Skills: godot-testing, godot-code-review. Cubre FR-001–015; SC-001–007 con gate explícito.
- [ ] T048 docs-writer: consolidar sólo comportamiento aprobado por T047 en `docs/SPEC.md`, `docs/ARCHITECTURE.md`, `README.md` si procede y documentos017; sustituir descripción actual de cursor1→5 sólo al quedar integrado/aprobado su reemplazo, distinguir I1/I2 y pendientes de publicación. No volcar logs/partidas ni afirmar60FPS sin medición. Depende T047. Cubre FR-016.
- [ ] T049 project-orchestrator: publicar head consolidado I2 y verificar CI exacto en `.github/workflows/ci.yml`, con reportes reales del tester y docs T048; reconciliar base/diff si cambió I1, sin merge automático o ejecutar pruebas por sí mismo. Depende T048. Cubre FR-016; SC-007 integración.
- [ ] T050 qa-validator: revisar documentación T048, CI y revisión exacta contra `specs/017-comandante-memoria/{spec,plan,tasks}.md`; emitir APROBADO PARA INTEGRACIÓN sólo si GREEN/build/funcional/equilibrio acreditados y no hay fallos reales. Precisar destinos/renderers pendientes y no declarar APROBADO PARA PUBLICACIÓN. Depende T049. Skills: godot-code-review. Cubre FR-016; SC-001–007 integración.
- [ ] T051 project-orchestrator: crear/adjuntar PR I2 en borrador y actualizar Issue017 según `docs/DEVELOPMENT_WORKFLOW.md`, con IDs/RED/GREEN/CI/QA/comandos/límites breves; usar Refs mientras SC-007/publicación estén pendientes, sin promover/fusionar/publicar automáticamente. Depende T050. Cubre FR-016.
- [ ] T055 dev-godot: únicamente tras autorización futura de la etapa y versión/build de producción definidos, preparar artefactos exactos Android/iOS/Web con presets y herramientas existentes de `docs/WEB_EXPORT.md`, `export_presets.cfg` y `tools/ci/verify_native_artifact.py` como referencia para la entrega al tester. Registrar SHA, versión, renderer y ubicación temporal externa de los paquetes; conservar firmas y guards, sin editar presets/workflows, subir/distribuir, probar o certificar hardware. Si el empaquetado no puede hacerse sin upload automático, detener ese camino y escalar, sin dispararlo. Depende T051. Skills: export-pipeline. Cubre FR-015/016; SC-007 publicación. Este ID nuevo precede operativamente a T052, sin renumerar tareas existentes.
- [ ] T052 godot-tester: sólo cuando haya artefactos de producción exactos disponibles y autorización humana para la etapa, verificar firma/paquete/versionado con `tools/ci/verify_native_artifact.py`, requisitos físicos, instalación/smoke, renderer, carga/rendimiento60FPS y matriz de publicación de `specs/017-comandante-memoria/quickstart.md` y constitución; declarar artefacto/versión/SHA y cada dispositivo. No sustituir hardware por simulación ni renovar excepciones beta o reabrir006. Ningún upload está incluido. Depende T055. Skills: godot-testing, export-pipeline. Cubre FR-015/016; SC-007 publicación.
- [ ] T053 qa-validator: revisar evidencia física/artefacto/firma/versionado de T052 contra `specs/017-comandante-memoria/spec.md` y constitución; emitir APROBADO PARA PUBLICACIÓN sólo sobre artefactos/destinos exactos con todos sus requisitos, o mantenerlos pendientes. Un fallo real bloquea ese gate; no autorizar envíos. Depende T052. Skills: godot-code-review, export-pipeline. Cubre FR-015/016; SC-007 publicación.
- [ ] T054 project-orchestrator: reconciliar alcance aprobado y pendientes en `specs/017-comandante-memoria/tasks.md` e Issue017; cerrar sólo cuando todos los SC se hayan cumplido, sin cerrar #61/#53 ni016. Conservar PR en borrador salvo petición expresa de la persona; distribución futura exige autorización separada y no forma parte de estas tareas. Depende T053. Cubre FR-016; SC-007 completo.

## Dependencias y ejecución

Cadena conservadora (sin ciclos):

`T001→T002→T003→T004→T005→T006→T007→T008→T009→T010→T011→T012→T013→T014→T015→T016→T017→T018→T019→T020→T021→T022→T023→T024→T025→T026→T027→T028→T029→T030→T031→T032→T033→T034→T035→T036→T037→T038→T039→T040→T041→T042→T043→T044→T045→T046→T047→T048→T049→T050→T051`.

`T051→T055→T052→T053→T054` es la cola de publicación, con condición explícita de
artefactos y autorización; no bloquea el PR de integración T051 ni convierte
las tareas de publicación en completas. Un cambio posterior al head probado
invalida los veredictos afectados y exige GREEN/CI/QA pertinentes nuevos.

US1: T007–T011 y T030–T034. US2: T012–T016 y T035–T039.
US3: T017–T021 y T040–T044. Todas son P1 y completan aceptación jugable sólo
con I2 y la validación final, aunque cada módulo tenga comprobación independiente.

### Paralelismo por historia

No hay tareas `[P]`: comparten Session, Store, raíz, nivel o suites. Para US1,
RED→dev→GREEN es secuencial; para US2, no modificar Store mientras se prueba su
cierre; para US3, no cambiar UI/raíz durante QA. La inspección independiente de
contextos o lectura documental puede coincidir, sin abrir trabajo de fuentes
paralelo ni marcar un test RED y su implementación como independientes.

## Trazabilidad a requisitos y criterios

| Requisito | Tareas principales |
|---|---|
| FR-001 | T030–T034,T045,T047 |
| FR-002 | T030–T034,T045,T047 |
| FR-003 | T030–T034,T045,T047 |
| FR-004 | T007–T011,T030–T034 |
| FR-005 | T007–T011,T030–T034 |
| FR-006 | T007–T011,T030–T034 |
| FR-007 | T007–T011,T030–T034 |
| FR-008 | T012–T016,T035–T039 |
| FR-009 | T012–T016,T035–T039 |
| FR-010 | T007–T016,T030–T039 |
| FR-011 | T012–T021,T035–T044 |
| FR-012 | T012–T021,T035–T044 |
| FR-013 | T030–T044,T045,T047 |
| FR-014 | T046,T047 |
| FR-015 | T012–T021,T035–T045,T047,T052,T053,T055 |
| FR-016 | T001–T006,T022–T029,T048–T055 |
| SC-001 | T030–T034,T045,T047,T050 |
| SC-002 | T007–T011,T030–T034,T045,T050 |
| SC-003 | T007–T011,T030–T034,T045,T050 |
| SC-004 | T012–T016,T035–T039,T045,T050 |
| SC-005 | T012–T021,T035–T045,T050 |
| SC-006 | T046,T047,T050 |
| SC-007 | T045,T047,T049–T055 (integración y publicación separadas) |

## Estrategia de entrega

- **I1 interno**: T001–T025; núcleo funcional aislado con RED/GREEN/QA/docs/CI,
  Refs al Issue017 y sin activar el director. Tamaño orientativo≤400 líneas
  manuales/20 archivos por PR; dividir por resultado comprobable o justificar
  el tamaño si hace falta, conservando dependencias y ciclos completos.
- **I2 jugable**: T026–T051; integración de las tres historias P1. Es el mínimo
  jugable del comandante con memoria; no sustituirlo por US1 aislada sin memoria.
- **Publicación**: T055→T052–T054 pendientes propios. No inferir completado desde merge,
  emulador, software renderer o una excepción histórica.
- Commits por resultado con IDs; un Issue por feature, rama por incremento y PR
  borrador. Sólo el último que cumpla todo puede usar Closes. Recomendar Squash
  and merge a la persona; no ejecutar merge o reescribir historial.
- La próxima acción tras generación/análisis será revisar preparación y obtener
  autorización de ejecución. Esta lista no dispara agentes, pruebas o builds.
