# Tasks: La carta — introducción narrativa

**Input**: [spec.md](spec.md), [plan.md](plan.md), [contrato](contracts/intro-flow.md), [guion](guion.md), [quickstart](quickstart.md).  
**Entrega**: 013-I1; rama `codex/013-introduccion-la-carta`; [Issue #53](https://github.com/Juanpvivas/demons/issues/53); [PR #54 en borrador](https://github.com/Juanpvivas/demons/pull/54).  
**Flujo**: Spec Kit prepara, roles ejecutan según [workflow](../../docs/DEVELOPMENT_WORKFLOW.md). Sólo orquestador marca [X] tras QA. Sin nuevas evidencias versionadas.

## Fase 1: Preparación e interfaces neutrales

- [X] T001 project-orchestrator con qa-validator: revisar preparación completa de `specs/013-introduccion-la-carta/`, decisiones confirmadas, cobertura FR/SC y dependencias; aprobar antes de modificar código.
- [X] T002 dev-godot: declarar únicamente interfaz neutral importable de `contracts/intro-flow.md` en `resources/schemas/intro_slide.gd`, `intro_sequence.gd`, `core/intro_progress.gd`, `scenes/ui/IntroPlayer.tscn`, `intro_player.gd`, `scenes/game/game_root.gd` y `scenes/ui/main_menu.gd`; sin reproducción/guardado/conexión de flujo. Tester comprueba carga y QA neutralidad; depende T001.

## Fase 2: RED de historias de usuario

- [X] T003 [US1] godot-tester: escribir/ejecutar RED válido en `tests/unit/ui/test_intro_player.gd` sobre orden/tiempo/voz-subtítulo, pausa/continuación/actividad, salida única por fin/omisión, cierre y callback viejo, prompt Comenzar; fixtures breves/audio válido y observación proporcional. Depende T002; fallo por aserción de comportamiento ausente, no parser/import.
- [X] T004 [US2] godot-tester: escribir/ejecutar RED válido en `tests/unit/systems/test_intro_progress.gd` y `tests/unit/game/test_game_root.gd` para primera entrada sin nivel, espera Comenzar, guardado por versión/final/omisión, lectura corrupta/error escritura, Jugar posterior y Retry directos, reentrada/gesto viejo. Usar almacenamiento temporal inyectado; depende T003, sin implementar comportamiento.
- [X] T005 [US3] godot-tester: escribir/ejecutar RED válido de botón/señal en `tests/unit/ui/test_main_menu.gd` y replay en `tests/unit/game/test_game_root.gd`: inicio escena1 y regreso menú tras fin/omisión sin nivel; controles/foco y callbacks viejos. Depende T004.
- [X] T006 qa-validator: revisar T003–T005 y controles positivos contra contrato/spec; aprobar sólo RED esperado válido y calidad de pruebas, no comportamiento entregado. Depende T005.

## Fase 3: Implementación y GREEN de 013-I1

- [X] T007 [US1] dev-godot: implementar US1–US3 según RED/contrato: Resources y `resources/narrative/la_carta.tres`, IntroPlayer, IntroProgress, GameRoot/MainMenu. Copiar siete PNG de propuesta a `assets/narrative/la_carta/` y clips provisionales autorizados a `assets/audio/narrative/la_carta/`, con SOURCES/licencias portables; conservar output/ y excluir copia local con `.gdignore` no versionado. Completar voz/compañero/texto/fundidos/encuadre, persistencia por versión, rutas y controles; sin tocar pruebas, balance/presets/versiones/publicación. Depende T006; aprobación requiere T008–T009.
- [X] T008 [US1] godot-tester: confirmar GREEN T003–T005, regresión y suite GUT completa vía `tools/ci/run_gut.py`; import/build/export Web y nativos disponibles, smoke de flujo hasta resultado/retry/menú con fixture declarado, visual/input/escucha de siete escenas y pausa/foco/resize/gestos/offline según `quickstart.md`. Comparar carga/coste disponible, declarar destino/renderer/audio no observados y límites físicos/paquete. Depende T007.
- [X] T009 qa-validator: revisar independientemente fuente/diff, arte/voz/licencias, RED/GREEN y matriz de T008 contra spec; aprobar funcionalidad sólo con evidencia suficiente, declarar anomalías/límites y devolver fallos al rol dueño. No certificar publicación. Depende T008.

## Fase final: Documentación, CI y entrega

- [X] T010 docs-writer: consolidar sólo comportamiento aprobado en `docs/SPEC.md`, `docs/ARCHITECTURE.md`, guía de usuario y `specs/013-introduccion-la-carta/`; resolver pregunta narrativa pertinente, conservar historia/pausa006/publicación004/005 y distinguir voz provisional/ficción. No volcar logs ni modificar tareas. Depende T009.
- [X] T011 project-orchestrator con godot-tester: comprobar diff/commits por resultado, publicar rama y verificar CI de revisión exacta; reutilizar GREEN válido, repetir sólo verificaciones invalidadas por cambios. Reportar en PR sin nuevas evidencias Git. Depende T010.
- [X] T012 qa-validator: revisar consolidación T010 y revisión exacta/CI T011; emitir APROBADO PARA INTEGRACIÓN sólo con fuente, GREEN/regresión, visual/build y CI suficientes, conservando publicación pendiente. Depende T011.
- [X] T013 project-orchestrator: consolidar Issue único y PR en borrador de 013-I1 con `Refs #<issue>`, trazabilidad RED/GREEN, QA y límites; marcar sólo alcance aprobado, adjuntar PR a chat, sin promoción/merge/distribución. Depende T012.
- [ ] T014 project-orchestrator con roles responsables: sólo ante autorización futura de publicación, completar SC-008 (artefacto exacto, firma/versión/renderer, hardware/smoke/60FPS y QA de publicación). Esta tarea permanece pendiente y no bloquea integración aprobada; no hereda excepciones beta.

## Dependencias y ejecución

Cadena T001→T002→T003→T004→T005→T006→T007→T008→T009→T010→T011→T012→T013. T014 es gate posterior independiente autorizado en el futuro. Sin [P]: los grupos comparten archivos y fixtures. US1,US2,US3 son verificables por separado pero esta entrega integra las tres; no fusionar RED sin GREEN. Setup no resuelve comportamiento; errores de importación no cuentan como RED.

**Cobertura**: FR001–004/SC001,005→T003,T007–009; FR005–007,009–010/SC002–003→T004,T007–009; FR008/SC004→T005,T007–009; FR011/SC006→T008–009; FR012–013→T001,T007,T009–010; SC007→T008–013; SC008→T014. La validación visual/escucha no se sustituye por tests artificiales de píxel.
