# Tasks: Personajes y munición de Monte Calvo

**Estado**: I1 y corrección UX T031–T038 aprobados e integrados en `main`. I2 en curso; I3 pendiente.
**Issue**: [#18](https://github.com/Juanpvivas/demons/issues/18).
**Incremento de esta entrega**: I2 / US2, enemigo, contacto y reutilización (T014–T022), sin iniciar I3.
**Execution Branch**: `codex/004-i2-enemigo`, desde `main` en `2dc532d`.
**Base del PR funcional**: `main`, con I1 del [PR #20](https://github.com/Juanpvivas/demons/pull/20)
y la preparación del [PR #19](https://github.com/Juanpvivas/demons/pull/19) ya integrados;
la rama de ejecución se mantiene durante el ciclo de I2. El historial y las
aprobaciones de I1 conservan su alcance original.
El Xiaomi 11T Pro físico `2107113SG` es la referencia provisional exclusiva
de 004 por decisión de la persona, según la constitución 2.2.0. Las aprobaciones
de T001–T013 corresponden a `87a39c6` y conservan su evidencia histórica. La
corrección solicitada por la persona requiere sus propios gates antes de actualizar
la entrega; iOS sigue distinguiendo simulador y hardware. Los incrementos
posteriores conservan sus verificaciones propias.
**Input**: [spec](spec.md), [plan](plan.md), [research](research.md),
[modelo](data-model.md), [contrato](contracts/visual-presentation.md) y
[quickstart](quickstart.md).
**Flujo**: [DEVELOPMENT_WORKFLOW.md](../../docs/DEVELOPMENT_WORKFLOW.md).

Spec Kit prepara. La ejecución posterior pertenece a los roles del proyecto.
El orquestador proporciona la rama real y asigna cada tarea; solo él marca
`[X]` tras `APROBADO` de QA. Desarrollo no escribe, modifica ni ejecuta pruebas.
El tester conserva RED → desarrollo → GREEN/regresión; arte y documentos usan
verificación proporcional sin RED artificial. Todos consultan las skills
GodotPrompter aplicables antes de escribir/revisar sistemas de Godot.

Los resultados se entregan al orquestador para el PR; logs, mediciones, capturas
e informes nuevos permanecen en temporales o CI, nunca en Git ni volcados en
estos documentos. Las pruebas, arte, procedencia y documentación útil sí se
versionan. Cada incremento incluye sus verificaciones, QA y documentación.

## Fase 1: Preparación de la ejecución

**Objetivo**: fijar incremento, entorno y acceso a la referencia constitucional.

- [X] T001 project-orchestrator: comprobar `AGENTS.md`, `specs/004-personajes-municion-monte-calvo/checklists/requirements.md`, historial y checkout; buscar Issues de la feature en todos los estados y crear o reutilizar un único Issue, delimitar I1–I3 y preparar solo la rama del incremento activo. Identificar el Xiaomi físico provisional autorizado para 004, navegadores y destino iOS de la matriz; sin acceso, mantener pendientes sus gates, sin heredar resultados de 002/003.

## Fase 2: Línea base y contratos ejecutables mínimos

**Objetivo**: permitir aserciones semánticas antes de implementar presentación.

- [X] T002 godot-tester: establecer baseline con `tools/ci/run_gut.py`, `scenes/levels/Nivel_MonteCalvo.tscn` y `specs/004-personajes-municion-monte-calvo/quickstart.md`: reglas/transformaciones protegidas, carga, capturas comparables y rendimiento por entorno. Registrar revisión, duración, FPS/frame times/memoria y límites para comparar cada incremento; depende de T001.
- [X] T003 dev-godot: definir firmas mínimas de ataque confirmado, impacto, observación de modo/movimiento y reset en `scenes/units/soldado_visual.gd`, `scenes/enemies/enemigo_visual.gd`, `scenes/visuals/combat_visual_effects.gd` y `scenes/visuals/death_visual_effect.gd`; preparar `scenes/visuals/DeathVisualEffect.tscn` cargable y la señal `defeat_visual_requested(snapshot: Dictionary)` en ambos actores. Solo esqueleto sin poses, emisión efectiva, efectos, conexiones o reset resueltos. godot-tester verifica carga; qa-validator revisa firmas y límites antes de RED; depende de T002.

**Gate**: el tester escribe pruebas contra esas interfaces revisadas; si falta
una firma, vuelve a T003. Importación, método ausente o fixture roto no son RED.
Los valores de arte de prueba no certifican la estética de producción.

## Fase 3: I1 / US1 — Soldado reconocible y estados de combate (P1)

**Objetivo independiente**: soldado inicial y desplegado pictóricos, con fusil,
machete, acciones, daño/moral y derrota, aunque enemigo/caja sigan provisionales.
**Prueba independiente**: ejecutar los cinco escenarios US1 y sus bordes;
recarga por ruta existente, sin incorporar controles.

- [X] T004 [US1] dev-godot: producir el diseño y poses mediante la skill de imagen aplicable en `assets/sprites/units/monte_calvo/soldado_atlas.png`, `soldado_frames.tres` y `SOURCES.md`; incluir importación conforme al contrato, procedencia/permisos, apoyo estable y armas legibles. Inspección artística posterior, sin RED artificial; depende de T003.
- [X] T005 [US1] godot-tester: escribir y ejecutar RED en `tests/unit/units/test_soldado_visual.gd` para modo inicial, disparo/golpe reales, última bala, interrupción por modo, recarga conservando moral, daño/moral superpuestos, muerte prioritaria y dos instancias independientes. Verificar que ninguna animación aplica daño, gasta recursos o altera cadencia; depende de T003, no de T004/T008.
- [X] T006 [US1] godot-tester: escribir y ejecutar RED en `tests/unit/systems/test_combat_visual_effects.gd` para snapshot neutro por valor anterior al retiro, efecto independiente 0,40 s sin física/input, pooling y callbacks obsoletos, diez reutilizaciones y muerte jugable sin listener/servicio. Cubrir liberación inmediata de celda/actor y una sola solicitud visual; depende de T003, no de T008.
- [X] T007 [US1] qa-validator: revisar `tests/unit/units/test_soldado_visual.gd`, `tests/unit/systems/test_combat_visual_effects.gd` y resultados T005/T006; aprobar únicamente RED semántico ejecutado, sin errores de infraestructura ni implementación anticipada. El orquestador puede marcar solo las tareas RED aprobadas; depende de T005 y T006.
- [X] T008 [US1] dev-godot: implementar presentación del soldado en `scenes/units/Soldado.tscn`, `soldado.gd`, `soldado_visual.gd` y servicio/efecto de `scenes/visuals/`; registrar soldados iniciales/nuevos desde `scenes/levels/nivel_monte_calvo.gd`. Aplicar tiempos/prioridades del contrato y pool visual mínimo, preservando retiro y consecuencias inmediatos. Sin escribir/ejecutar pruebas; depende de T004 y T007.
- [X] T009 [US1] godot-tester: confirmar GREEN de T005/T006 y regresión pertinente en `tests/unit/units/test_soldado.gd`, `test_soldado_enemigo_integration.gd`, `tests/unit/levels/test_nivel_montecalvo.gd`, `test_pickup_input_routing.gd` y sistemas afectados. Comprobar ausencia de listener, independencia y callbacks sin debilitar RED; depende de T008.
- [X] T010 [US1] godot-tester: verificar arte/estados de `scenes/units/Soldado.tscn` y procedencia, gestos reales de economía, resize, smoke hasta terminal observado y rendimiento base/candidato según `specs/004-personajes-municion-monte-calvo/quickstart.md` en cada entorno afectado. Incluir Xiaomi provisional de 004/60 FPS y Web separado; no diferirlo a I3; depende de T009.
- [X] T011 [US1] qa-validator: validar I1 en `scenes/units/`, `scenes/visuals/` y `scenes/levels/nivel_monte_calvo.gd` contra US1, FR-002–004/006–007/009–012, arte, RED/GREEN y T010; comprobar alcance/tamaño del diff, retiro inmediato y límites reales de plataforma. Solo aprobar el incremento con verificaciones pertinentes completas; depende de T010.
- [X] T012 [US1] docs-writer: documentar únicamente el soldado/servicio aprobados en `docs/SPEC.md` y, si corresponde graduar un patrón, `docs/ARCHITECTURE.md`; conservar enemigo, caja y otros pendientes. Preparar resumen útil para PR sin registros de verificación versionados; depende de T011 aprobado.
- [X] T013 [US1] qa-validator: revisar documentación T012 y diff final de `docs/SPEC.md`, `docs/ARCHITECTURE.md` y archivos I1, confirmando vigencia de GREEN/visual/rendimiento. Tras APROBADO, project-orchestrator publica la rama y crea PR en borrador con `Refs` al Issue y trazabilidad RED/GREEN; depende de T012, sin promoverlo ni fusionarlo.

## Corrección de I1 tras revisión de la persona: legibilidad y encuadre

**Origen**: la persona reporta un soldado demasiado pequeño y confundido con el
suelo, y composición descentrada con exceso de espacio a la derecha en Xiaomi;
la distribución del iPad debe conservarse. Es una corrección del PR #20, no I2.
Las casillas históricas T001–T013 no acreditan por sí solas la corrección;
su aprobación corresponde a T031–T038.

**Alcance**: ampliar únicamente la presentación del soldado y su separación
visual del entorno; centrar horizontalmente el encuadre y cubrir sus márgenes
con decorado existente. Conservar posiciones jugables, grid, cuerpos/detectores,
economía, InputMap, semántica de interacción, oleadas y composición vertical del
iPad. La enmienda documental delimita las excepciones a cámara/huella visual.

- [X] T031 docs-writer: redactar la enmienda preparatoria de `spec.md`, `plan.md`, `research.md`, `data-model.md`, `contracts/visual-presentation.md` y `quickstart.md` para legibilidad/localización del soldado, escala visual aproximada de 72 frente a cuerpo 48, estilo mate y preservación de material autorado en snapshot/reset, encuadre horizontal y cobertura decorativa, sin ampliar las reglas jugables. Conservar los resultados históricos como baseline, sin presentar la corrección como implementada; depende de T013 y de la observación de la persona.
- [X] T032 qa-validator: revisar coherencia de la enmienda T031 y este bloque antes de implementar. Confirmar límites, criterios observables, matriz afectada y separación entre ajuste artístico y comportamiento que requiere RED; no aprobar código nuevo ni marcar tareas; depende de T031.
- [X] T033 godot-tester: escribir y ejecutar RED semántico para eje mundo 576 centrado con distintos aspectos y resize, origen vertical efectivo del canvas en 0, cobertura de fondo y correspondencia pantalla/mundo con recogida/despliegue reales. Cubrir material autorado neutro en snapshot y limpieza al reutilizar efectos si se integra ese estilo, sin referencias al actor ni progreso compartido. No fabricar RED de color/archivos y no alterar evidencia histórica; depende de T032.
- [X] T034 dev-godot: corregir presentación del soldado mediante escala/offset y contraste mate sobre los recursos existentes; mantener pies y collider, feedback y derrota coherentes. Implementar encuadre local sin zoom y cobertura decorativa que elimine el margen asimétrico, con reset/snapshot de estilo inmutable cuando aplique. Sin mover trincheras, actores o grid, ni escribir/ejecutar pruebas; depende de T033 y su revisión RED por QA.
- [X] T035 godot-tester: confirmar GREEN de T033 y regresión pertinente de presentación, efectos, nivel y routing. Verificar inicial/desplegado, fusil/machete, daño/moral y derrota en tamaño de juego sin overlays, contraste también en grises, pies/huellas y márgenes equilibrados en Xiaomi nativo/Web, escritorio e iPad Simulator. Corroborar cuatro resultados de economía bajo el nuevo canvas, resize y cobertura, y mediciones base/candidato pertinentes sobre el estado corregido; reutilizar solo evidencia no invalidada, sin extrapolar versiones ni entornos. Depende de T034.
- [X] T036 qa-validator: validar la corrección de I1 contra la enmienda, RED/GREEN, arte/contraste, geometría efectiva, entrada y mediciones afectadas; comprobar que mantiene la composición iPad y reglas protegidas. Emitir veredicto independiente, sin modificar checkout; depende de T035.
- [X] T037 docs-writer: consolidar únicamente la corrección aprobada en `docs/SPEC.md`, `docs/ARCHITECTURE.md` y procedencia/transformaciones de `SOURCES.md` cuando corresponda, conservando I2/I3 e interfaz pendientes. Entregar resumen para actualizar el PR #20, sin versionar registros nuevos; depende de T036 aprobado.
- [X] T038 qa-validator: revisar documentación y diff final de la corrección y vigencia de sus verificaciones. Tras APROBADO, project-orchestrator marca sus tareas y actualiza el PR #20 en borrador con Refs al Issue #18, límites y trazabilidad de la corrección, sin promover ni fusionar; depende de T037.

I2 comienza tras el cierre aprobado de T038 y la integración de I1 en `main`.

## Fase 4: I2 / US2 — Enemigo, contacto y reutilización (P1)

**Objetivo independiente**: enemigo pictórico que comunica movimiento real,
contacto, daño y derrota sin alterar su combate; reutiliza el servicio de I1.
**Prueba independiente**: cinco escenarios US2, diez ciclos y dos instancias;
la caja puede continuar provisional. I2 depende de I1 aprobado.

- [X] T014 [US2] dev-godot: producir diseño/avance/contacto/derrota con la skill de imagen aplicable en `assets/sprites/enemies/monte_calvo/enemigo_atlas.png`, `enemigo_frames.tres` y `SOURCES.md`; respetar paleta, silueta, huella, importación y procedencia del contrato, sin RED de archivos/estética; depende de T013 y T038.
- [X] T015 [US2] godot-tester: escribir y ejecutar RED en `tests/unit/enemies/test_enemigo_visual.gd` y ampliar `tests/unit/systems/test_combat_visual_effects.gd`: desplazamiento real tras física frente a enemigo bloqueado por Soldado real, daño/contacto sin ataques ficticios, snapshot antes del release síncrono, diez reusos, dos instancias y callbacks stale tras reacquire. Conservar drop/baja/orden aun sin listener; depende de T003, T013 y T038, no de T017.
- [X] T016 [US2] qa-validator: revisar RED y cobertura de `tests/unit/enemies/test_enemigo_visual.gd` y `tests/unit/systems/test_combat_visual_effects.gd`; exigir fallo semántico y bloqueo físico real, no asumir que velocidad deseada implica avance. Aprobar solo pruebas RED; depende de T015.
- [ ] T017 [US2] dev-godot: implementar en `scenes/enemies/EnemigoBase.tscn`, `enemigo.gd`, `enemigo_visual.gd` y `scenes/levels/wave_spawner.gd` el avance/contacto observado, impacto, snapshot previo y reset total por generación; registrar una vez cada instancia física creada con el servicio I1, sin cambiar `core/object_pool.gd` ni el orden jugable. Sin pruebas; depende de T014 y T016.
- [X] T018 [US2] godot-tester: confirmar GREEN de T015 y regresión I1/enemigo/spawner/oleadas en `tests/unit/enemies/`, `tests/unit/units/`, `tests/unit/levels/test_wave_spawner.gd` y `tests/unit/systems/test_combat_visual_effects.gd`; comprobar diez ciclos y aislamiento tras reutilización antes de terminar feedback; depende de T017.
- [ ] T019 [US2] godot-tester: comparar enemigo integrado y `assets/sprites/enemies/monte_calvo/SOURCES.md`, combate/gestos reales y rendimiento base/candidato por entorno con `specs/004-personajes-municion-monte-calvo/quickstart.md`. Verificar legibilidad/resize y smoke terminal, Xiaomi provisional de 004/60 FPS, Web separado e iOS identificado; pendientes no se presentan aprobados; depende de T018.
- [ ] T020 [US2] qa-validator: validar I2 en `scenes/enemies/`, `scenes/levels/wave_spawner.gd` y servicio visual contra US2, FR-002–003/005–007/009–012, arte, RED/GREEN y T019; comprobar que contacto/animación no gobiernan daño y que no hay residuos ni cambio de pool; depende de T019.
- [ ] T021 [US2] docs-writer: actualizar `docs/SPEC.md` y los patrones aprobados que correspondan de `docs/ARCHITECTURE.md`, conservando la caja y el cierre como pendientes; entregar resumen del alcance I2 para PR sin evidencias nuevas en Git; depende de T020 aprobado.
- [ ] T022 [US2] qa-validator: revisar documentación T021 y estado final de `docs/SPEC.md`, `docs/ARCHITECTURE.md` y archivos I2. Tras APROBADO y verificación de base/diff, project-orchestrator publica la rama del incremento y crea PR en borrador con `Refs` al mismo Issue; depende de T021, sin promoverlo ni fusionarlo.

## Fase 5: I3 / US3 — Caja de munición e integración final (P2)

**Objetivo independiente**: caja reconocible y recolección idéntica, sin tocar
picking; cierra la coherencia visual de los tres elementos. Depende de I2.
**Prueba independiente**: tres escenarios US3 y cuatro resultados de economía
con clic/toque, conservando radio 20 y la precedencia recoger/desplegar.

- [ ] T023 [US3] dev-godot: producir con la skill de imagen aplicable `assets/sprites/pickups/monte_calvo/caja_municion.png`, importación y `SOURCES.md`; integrar solo el sprite de `scenes/levels/AmmoPickup.tscn`, arte/motivo opaco dentro de 32×32 y radio 20 intacto. Sin lógica ni RED artificial; depende de T022.
- [ ] T024 [US3] godot-tester: inspeccionar caja/procedencia y confirmar regresión existente en `tests/unit/levels/test_pickup_input_routing.gd`, `test_nivel_montecalvo.gd` y `tests/unit/systems/test_economy_manager.gd`; verificar picking real, cuatro gestos y cajas solapadas según `specs/004-personajes-municion-monte-calvo/quickstart.md`. No añadir tests que solo enumeren archivos/frames ni reconstruir RED histórico; depende de T023.
- [ ] T025 [US3] godot-tester: completar comparación de las tres representaciones, armas sin depender del tinte, resize y medición final base/candidato según `specs/004-personajes-municion-monte-calvo/quickstart.md`: Web Chrome 1152×648/960×540 y Android horizontal, app Android en el Xiaomi provisional de 004 y app iOS distinguiendo hardware/simulador. Registrar 60 FPS estables, carga y memoria por entorno; ausencias siguen bloqueando su aceptación; depende de T024.
- [ ] T026 [US3] godot-tester: ejecutar suite completa con `tools/ci/run_gut.py`; jugar `scenes/levels/Nivel_MonteCalvo.tscn` con oleadas de producción hasta terminal usando observador temporal de solo lectura del estado y corroboración de producción. Verificar victoria/derrota por separado y recarga por ruta existente; no sustituir la partida por recursos cortos ni inferir estado oculto por sprites; depende de T025.
- [ ] T027 [US3] qa-validator: validar los tres elementos, diff y T024–T026 contra `specs/004-personajes-municion-monte-calvo/spec.md` completo, sus 12 FR y 8 SC. Exigir suite/partida, matriz, procedencia, pooling/reset, neutralidad jugable y rendimiento; pendientes de plataforma/referencia física de 004 o resultado terminal sin oráculo impiden aprobar cierre; depende de T026.
- [ ] T028 [US3] docs-writer: consolidar comportamiento aprobado y límites en `docs/SPEC.md`, `docs/ARCHITECTURE.md` y `README.md` cuando corresponda; resolver solo acabado de estos tres elementos, conservando HUD/controles y resto del MVP pendientes. Preparar resumen final para PR sin volcar mediciones o informes; depende de T027 aprobado.
- [ ] T029 [US3] qa-validator: revisar documentación T028 y diff final de `docs/SPEC.md`, `docs/ARCHITECTURE.md`, `README.md` y archivos I3; confirmar vigencia de los resultados anteriores y aceptación completa de `specs/004-personajes-municion-monte-calvo/spec.md`. Cualquier cambio posterior vuelve a la verificación pertinente; depende de T028.

## Fase final: Entrega del incremento aprobado

- [ ] T030 project-orchestrator: revisar `specs/004-personajes-municion-monte-calvo/tasks.md`, aprobación T029, diff/base, tamaño y trazabilidad del Issue; comprobar política de versiones de `docs/ARCHITECTURE.md` antes de distribución. Publicar rama I3 y PR en borrador, con `Closes` solo si todos los SC están cumplidos; resumir resultados/comandos/límites/QA en el PR. Recomendar Squash and merge a la persona; no promover ni fusionar; depende de T029 aprobado.

## Dependencias y oportunidades de paralelismo

La cadena de entrega es **T001 → T002 → T003 → I1 → corrección UX (T031–T038) → I2 → I3 → T030**.
Dentro de I1: T004 y T005/T006 parten de T003; T007 valida RED; T008 reúne
arte y RED aprobado; T009 → T010 → T011 → T012 → T013 cierra el incremento.
I2 sigue T014/T015 → T016 → T017 → T018 → T019 → T020 → T021 → T022.
I3 es T023 → T024 → T025 → T026 → T027 → T028 → T029.

Ningún RED depende de su implementación. QA puede aprobar RED, pero no el
comportamiento asociado sin GREEN. Los IDs de QA/documentación forman parte
del incremento, no son verificaciones opcionales pospuestas hasta el cierre.

No se marca `[P]` por defecto: ejecución y runner comparten checkout/importación,
y los efectos compartidos se modifican en ambas historias. Hay oportunidades
de preparar arte T004 frente a autoría de pruebas T005/T006, o arte T014 frente
a autoría T015, solo si el orquestador asegura archivos independientes; carga,
ejecución de pruebas e integración sobre archivos compartidos son secuenciales.

## Cobertura y estrategia de entrega

| Requisitos/resultados | Tareas principales |
|---|---|
| FR-001–003/011; SC-001/008 | T004/T010, T014/T019, T023–T025 y QA respectivo |
| FR-004/006/009; SC-002/004 | T005–T011 y regresión T018/T024/T026 |
| FR-005–007; SC-002/003 | T006–T011, T015–T020 |
| FR-008–010; SC-004/005 | T010/T019/T024–T025 |
| FR-009/010; SC-006 | T010/T019/T026–T027 |
| Constitución IV; SC-007 | T001–T002, T010/T019/T025 y QA respectivo |
| FR-012; SC-008 y documentación | T011–T013, T020–T022, T027–T030 |

MVP de este acabado: I1 completo, con soldado y pool visual mínimo validado.
Cada PR conserva RED/desarrollo/GREEN, arte aprobado, verificación de sus
entornos, QA y documentación; no se entrega una implementación pendiente tras
aprobar únicamente RED. La guía orientativa es 400 líneas manuales/20 archivos
por incremento, declarando binarios/generados aparte; justificar indivisibilidad
o dividir un resultado independiente con QA sin fragmentar el ciclo TDD.

El orquestador prepara una rama por incremento; si la base es otro PR pendiente,
declara la dependencia y revalida diff/QA al integrarla. Intermedios usan `Refs`;
solo el cierre completo usa `Closes`. La preparación de Spec Kit terminó con la revisión de tareas y análisis.
La ejecución posterior se registra en las casillas y en el PR de cada
incremento; esta entrega no inicia I2/I3.
