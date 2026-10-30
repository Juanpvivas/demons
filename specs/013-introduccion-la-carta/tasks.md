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

## Revisión autorizada 013-I1-R2 — cinco correcciones

**Alcance vigente**: ambas entradas→Comenzar→partida, sin textos superiores,
ambiente original separado y Menú principal activo/pausado, con integración
técnica de Ald sólo como preview provisional. La persona prefiere grabar su
voz: T026/SC-009 quedan pendientes del archivo, sin bloquear las cuatro correcciones.
Mismo Issue #53/PR #54 en borrador y rama; T001–T013 conservan aprobación de I1
y su contrato de replay anterior. No reiniciar ni modificar esa historia.
T014 sigue pendiente de publicación, fuera del incremento.

- [X] T015 project-orchestrator con qa-validator: revisar spec/plan/contrato/datos/guion/quickstart/checklist R2 de `specs/013-introduccion-la-carta/`, confirmar cinco correcciones y Comenzar explícito en ambas rutas, cobertura y ausencia de ampliación; aprobar antes de tocar comportamiento.
- [X] T016 [US1] godot-tester: escribir/ejecutar RED válido en `tests/unit/ui/test_intro_player.gd` y `tests/unit/game/test_game_root.gd` de final/omisión de ambas aperturas→Comenzar sin menú/autoinicio, ausencia de contador/captions/aviso superior y reproducción/ciclo separado de ambiente. Usar APIs/recursos existentes y búsqueda segura de nodos para aserciones; sin parser roto ni WAV inexistente. Cubrir pausa/foco/continuación/cierre/omisión y reproducción siguiente sin solapamiento. Depende T015.
- [X] T017 [US4] godot-tester: escribir/ejecutar RED válido en `tests/unit/ui/test_hud.gd`, `tests/unit/game/test_game_root.gd` y fixtures de nivel pertinentes para Menú principal visible/usable en PLAYING y PAUSED, cierre único de oleadas/audio/inputs/pools, callbacks viejos, Jugar limpio posterior y Retry/resultado conservados. No modificar implementación; depende T016.
- [X] T018 qa-validator: revisar RED T016–T017 y controles positivos contra contrato R2; aprobar sólo fallo por comportamiento ausente y calidad de pruebas. Voz/mezcla perceptual y cambio de medios no requieren RED artificial. Depende T017.
- [X] T019 [US1] dev-godot: implementar cuatro correcciones R2 en `scenes/ui/IntroPlayer.tscn`, `intro_player.gd`, `scenes/game/game_root.gd`, `scenes/ui/HUD.tscn`, `hud.gd`, nivel y Resources pertinentes; integrar ocho WAV Ald sólo como preview provisional y ambiente original de root en `assets/audio/narrative/la_carta/` con procedencia/licencia portable. Mantener siete PNG/guion/recuerdo, dos canales/limpieza, prompt Comenzar en ambas entradas, sólo subtítulos/controles sobre imágenes y retorno activo sin modal. Si llega archivo humano, coordinar T026 antes de GREEN. Sin tests ni cambios de balance/renderers/releases/publicación. Depende T018; aprobación requiere T020–T021, no aprueba voz final/naturalidad/fluidez.
- [X] T020 [US1] godot-tester: confirmar GREEN T016–T017 y regresión completa GUT/import/build/export/CI aplicables; ejecutar quickstart R2 de cuatro correcciones e integración técnica provisional: audio/ambiente separado, pausa/cierre, siete cuadros sin cabecera, controles/resize/foco, ambas rutas y Menú principal PLAYING/PAUSED con cierre/reinicio limpio. Distinguir destinos/gestos/audio no disponibles, fixture/producción y límites; no aprobar voz final, naturalidad o fluidez mientras T026 siga pendiente ni heredar audición de I1. Si se incorpora archivo humano, verificar medios T026 proporcionalmente sin RED artificial. Depende T019.
- [X] T021 qa-validator: contrastar cuatro cambios e integración técnica de voz provisional con spec, fuente/medios/licencias, RED/GREEN y visual/input R2; aprobar sólo alcance suficientemente verificado, devolver fallos al dueño y conservar límites físicos/paquete/publicación y riesgo previo de precarga. T026/SC-009 quedan pendientes sin archivo humano; si llega antes de GREEN, revisar además medios/escucha T026 con su alcance explícito. Depende T020, sin ciclo con T026 ni aprobación de voz definitiva desde Ald preview.
- [X] T022 docs-writer: consolidar únicamente cambios R2 aprobados en `README.md`, `docs/SPEC.md`, `docs/ARCHITECTURE.md` y specs013, distinguiendo versión actual de historia I1 y manteniendo T014/pausa006/pendientes004–005. No modificar tareas, fuente o pruebas; sin nuevos logs/evidencias Git. Depende T021.
- [X] T023 project-orchestrator con godot-tester: publicar revisión en la misma rama/PR #54, comprobar diff y CI de head exacto, reutilizando evidencia aún válida y repitiendo sólo comprobaciones invalidadas. Sin promoción/merge/distribución ni reescribir historial aprobado. Depende T022.
- [X] T024 qa-validator: revisar documentación consolidada R2 y CI/revisión exacta de T023, emitir APROBADO PARA INTEGRACIÓN sólo con fuente, GREEN/regresión, visual/escucha/build suficientes y límites explícitos; no aprobar publicación T014. Depende T023.
- [X] T025 project-orchestrator: actualizar título/cuerpo del PR #54 e Issue #53 para cuatro correcciones con voz preview provisional y T026/SC-009 pendientes si falta grabación humana; no presentar 5/5 ni voz final aprobada. Conservar trazabilidad I1 y RED/GREEN R2; `Refs #53`, PR en borrador, marcar sólo tareas aprobadas. Sin promoción/merge/distribución. Depende T024.
- [ ] T026 [US1] dev-godot con godot-tester y qa-validator: al recibir el archivo humano elegido por la persona, incorporar siete narraciones segmentadas en `assets/audio/narrative/la_carta/` y el compañero humano sólo si incluye su frase; conservar textos completos, ajustar tiempos sin cortes y actualizar procedencia/licencia portable. Tester verifica reproducción/mezcla/escucha de timbre y fluidez, QA emite veredicto proporcional de medios/SC-009, sin RED artificial. Dependencias: archivo externo y coordinación después de T018; puede ejecutarse durante T019 antes de GREEN y revisarse en T020–T021, sin esperar T025 ni crear ciclo. Si no llega el archivo, permanece pendiente y no bloquea las cuatro correcciones ni su PR parcial.

**Dependencias R2**: T015→T016→T017→T018→T019→T020→T021→T022→T023→T024→T025. T026 depende del archivo externo y coordinación tras T018; puede integrarse antes de T020, sin depender de T021/T025. Sin [P]: comparten escenas y fixtures. Interfaces existentes permiten RED sin nuevo setup neutral. Campos de ambiente se añaden durante desarrollo; tester comprueba ausencia actual por aserción, nunca por import fallido.

**Cobertura R2**: FR002/SC009→T026 (voz humana/escucha pendientes; T019–T021 sólo integración técnica preview); FR014→T016,T019–T021; FR003,010,016/SC005,010→T016,T019–T021; FR006,008/SC002,004→T016,T019–T021; FR015/SC011→T017,T019–T021; FR001,004–005,007,009,011–013/SC001,003,006→regresión T020 y QA T021; SC007→T020–T025. SC008 sigue únicamente en T014.

## Enmienda autorizada R3 — toma humana y Comenzar inferior

La persona eligió/autorizó `toma-3.wav`: T026 ya no espera archivo, sino su
incorporación técnica y QA proporcional durante esta revisión. Siete narraciones
humanas; compañero Ald único provisional identificado, sin atribuirlo a la
persona. Su elección ya aporta aceptación perceptual de toma3: no pedir otra ni
simular audición del agente. El único comportamiento UI nuevo es el prompt
inferior limpio. Preservar T001–T026/historia/checkboxes, preferencia actual,
ambiente y menú activo; T014 continúa pendiente de publicación.

- [X] T027 project-orchestrator con qa-validator: revisar enmienda mínima R3 de `spec.md`, `plan.md`, `contracts/intro-flow.md` y `quickstart.md`, toma3 elegida y alcance T026/SC-009, prompt sólo Comenzar inferior/SC-012 y dependencias sin setup nuevo. Aprobar preparación antes de RED, sin reiniciar historia previa.
- [ ] T028 [US1] godot-tester: escribir/ejecutar RED válido en `tests/unit/ui/test_intro_player.gd` y fixtures de `tests/unit/game/test_game_root.gd` para final natural/omisión de ambas entradas→sólo Comenzar centrado abajo en franja/estilo de Pausar/Omitir y mínimo52px, sin panel/banda/títulos/ficción/subtítulo/controles extra, última imagen visible y voz/ambiente detenidos. Cubrir resize/foco, espera sin autoinicio y gesto nuevo/doble→un nivel. Usar APIs actuales, no parser/setup roto ni acoplar GameRoot a nodos privados. Depende T027.
- [ ] T029 qa-validator: revisar calidad y RED T028 por aserción sobre comportamiento ausente; aprobación no entrega UI. Medios T026 se verifican proporcionalmente sin RED artificial y sin pedir aprobación perceptual humana repetida. Depende T028.
- [ ] T030 [US1] dev-godot: ajustar `scenes/ui/IntroPlayer.tscn` y `intro_player.gd` al contrato R3 usando show_start_prompt/señal existentes, sin acoplamiento privado de raíz; integrar T026 siete WAV segmentados de toma3 y SOURCES portables en `assets/audio/narrative/la_carta/`, manteniendo compañero Ald provisional y ambiente original. Ajustar datos de duración sin cortar texto/audio. Sin tests, metadatos/ASR/logs Git, balance/releases/versiones/publicación. Depende T029 y clips humanos disponibles; requiere T031–T032 para aprobación.
- [ ] T031 [US1] godot-tester: confirmar GREEN T028, regresión/suite GUT/importación y un export Web de revisión exacta para QA; probar prompt inferior limpio en final/omisión de ambas rutas, resize/foco/nuevo gesto, silencio residual, menú activo y preferencia conservados. Verificar T026 técnicamente por texto/duración/integridad/reproducción/mezcla, con aceptación perceptual atribuida a elección humana toma3; no fingir audición ni certificar compañero humano. Declarar entornos/límites y no duplicar exports de revisiones antiguas. Depende T030.
- [ ] T032 qa-validator: revisar fuente/medios, RED/GREEN, SC-012 y T026/SC-009 con evidencia proporcional técnica y elección humana ya dada; aprobar sólo alcance suficiente, compañero Ald explícitamente provisional, preservar publicación/físicos/FPS y devolver fallos al dueño. Depende T031.
- [ ] T033 docs-writer: consolidar únicamente R3 aprobado en `README.md`, `docs/SPEC.md`, `docs/ARCHITECTURE.md` y specs013 necesarios; distinguir narrador humano toma3 elegido por la persona de compañero Ald provisional y prompt inferior actual, conservar historia y T014/pausa006/pendientes004–005. No tocar tareas/fuente/tests ni crear evidencias Git. Depende T032.
- [ ] T034 project-orchestrator con godot-tester: publicar revisión de la misma rama/PR #54 y verificar CI del head exacto, reutilizando comprobaciones aún válidas y repitiendo sólo invalidadas por cambios. Sin promoción/merge/distribución. Depende T033.
- [ ] T035 qa-validator: revisar consolidación R3, CI/revisión exacta T034 y cumplimiento de T026/SC-009 y SC-012, emitir APROBADO PARA INTEGRACIÓN sólo con alcance suficiente y límites; no acreditar publicación/hardware. Depende T034.
- [ ] T036 project-orchestrator: actualizar PR #54 borrador e Issue #53 con alcance R3/toma3 humana y compañero provisional, trazabilidad RED/GREEN/QA y límites, `Refs #53`; marcar sólo tareas aprobadas, sin promoción/merge/distribución. Depende T035.

**Dependencias R3**: T027→T028→T029→T030→T031→T032→T033→T034→T035→T036. T026 se incorpora durante T030 y se verifica en T031–T032, sin depender de T036 ni crear ciclo. Sin [P] por archivos compartidos. FR017/SC012→T028–T032; FR002/SC009/T026→T030–T032; regresiones FR001–016/SC001–007,010–011→T031–T032; SC008 sigue sólo T014. La elección humana de toma3 no certifica otras voces o plataformas.
