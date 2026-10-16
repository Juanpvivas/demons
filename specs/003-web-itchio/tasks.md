---
description: "Plan de tareas Web/itch.io con roles, conservación de gameplay y QA"
---

# Tasks: Monte Calvo Web para itch.io

**Input**: `specs/003-web-itchio/spec.md` y `plan.md`; `research.md`,
`data-model.md`, `contracts/web-delivery.md` y `quickstart.md`.
**Flujo**: `docs/DEVELOPMENT_WORKFLOW.md` desde la raíz del repositorio.
**Execution Branch**: `codex/003-web-itchio`, preparada una sola vez por el
orquestador desde `b670d86`; incorpora `main` del PR #16 mediante `7309d8f`.
**Issue**: [#14](https://github.com/Juanpvivas/demons/issues/14).
**Estado**: entrega Web acotada aprobada por QA, **18/18 tareas**. Integración
con `main` verificada en el [informe](evidence/main-integration.md); los Checks
del [PR #15](https://github.com/Juanpvivas/demons/pull/15) corresponden a cada
revisión publicada. 002 quedó cerrada por la fusión del PR #16; sus límites
nativos no se extrapolan a Web. Fusión y publicación siguen siendo pasos separados.

## Formato y aprobación

- `[X]` solo lo registra el orquestador tras `APROBADO` independiente de QA,
  con alcance y evidencia enlazados. Implementar o ejecutar no equivale a aprobar.
- Setup, configuración, empaquetado y documentación sin lógica de gameplay
  nueva usan inspección/import/export/manual apropiados; no RED artificial.
- Ante bug de comportamiento/input reproducible: el orquestador añade IDs
  nuevos, preservando los existentes, para tester RED válido → QA del RED →
  dev → tester GREEN/regresión → QA → documentación. El ajuste no se oculta
  en el preset ni se implementa antes de RED.
- Pruebas existentes se conservan y ejecutan como regresión. Headless no
  sustituye picking real. Falta de motor/templates no acredita RED.
- `[P]` únicamente para tareas independientes en archivos distintos. Un solo
  tester controla editor/imports/servidor/UI; no ejecutar dos Godot simultáneos
  sobre el mismo checkout.

## Fase 1: Preparación y prerrequisitos

**Objetivo**: aplicar la política autorizada y obtener baseline real. La
constitución 2.0.0 es el gate documental previo, no una prueba de exportación.

- [X] T001 docs-writer: preparar la enmienda de plataformas en `.specify/memory/constitution.md`, `AGENTS.md`, `README.md`, `docs/SPEC.md` y `docs/ARCHITECTURE.md` para Web+Android+iOS y GDScript compartido; qa-validator contrasta Sync Impact Report, versión2.0.0 y conservación histórica de 001/002; sin dependencia de implementación.
- [X] T002 [P] godot-tester: registrar línea base en `specs/003-web-itchio/evidence/baseline.md`, `.gdignore`, logs y manifest de hashes de escenas, gameplay, arte, Resources, InputMap y presets nativos; ejecutar importación/GUT existentes e inventariar navegadores/Xiaomi y versiones; depende de T001 aprobada y conserva por separado los pendientes de 002.
- [X] T003 [P] dev-godot: preparar Godot estándar 4.7.1 y templates Web oficiales fuera del repositorio, verificando versión/hash/procedencia sin reemplazar Mono ni abrir/importar el juego; entregar reporte de entorno para `specs/003-web-itchio/evidence/toolchain.md` mediante tester; depende de T001 aprobada, sin builds/pruebas por desarrollo; QA revisa instalación y reporte antes de usarla.

## Fase 2: Historia de usuario1 — Abrir Monte Calvo (Prioridad: P1)

**Objetivo**: primera exportación navegable con arte y combate actuales.
**Criterio independiente**: W01 y comparación visual del nivel; tres cargas
nuevas en Chromium escritorio. No se presenta todavía como validación táctil.

- [X] T004 [US1] dev-godot: añadir preset `Web` en `export_presets.cfg` y explicitar solo el override Web Compatibility en `project.godot`, con un hilo, sin extensiones/PWA, canvas Adaptive y salida `build/web/index.html`; seleccionar dependencias/exclusiones sin alterar Mobile, InputMap ni presets nativos; depende de T002/T003 aprobadas y del contrato `specs/003-web-itchio/contracts/web-delivery.md`.
- [X] T005 [US1] godot-tester: verificar importación/exportación Web reales y W01 en `specs/003-web-itchio/evidence/web-startup.md`, con tres cargas nuevas, consola/red, renderer real, capturas 1152×648/960×540 e inspección inicial ZIP/PCK/exclusiones; comparar hashes protegidos; depende de T004 entregada, sin modificar preset ni juego.
- [X] T006 [US1] qa-validator: revisar en solo lectura `export_presets.cfg`, `project.godot` y `specs/003-web-itchio/evidence/web-startup.md`, cobertura FR-001/002/009/011 y evidencia T004/T005; emitir veredicto acotado de arranque/conservación, sin aprobar US2 por extrapolación; depende de T005 y reporte de desarrollo.

## Fase 3: Historia de usuario2 — Clic y toque Web (Prioridad: P1)

**Objetivo**: comprobar las interacciones actuales en navegador de computador
y Android físico, sin cambiar reglas o añadir controles.
**Criterio independiente**: W02–W10 aplicables, con saldo/ocupación y estado
previo suficientes para distinguir cada rechazo; smoke manual hasta terminal.

- [X] T007 [US2] godot-tester: ejecutar W02–W10 en navegador visible con clic mediante CUA del navegador y Chrome Xiaomi horizontal, incluyendo cuatro casos controlados, resize con clic posterior, iframe local, regreso de pestaña, recarga y partida manual hasta terminal; documentar `specs/003-web-itchio/evidence/web-interaction.md`, matriz/capturas y victoria/derrota GUT separadas; depende de T006 aprobada; si detecta bug, registrar reproducción y detener la corrección hasta nuevas tareas RED/dev/GREEN, sin parchear implementación.
- [X] T008 [US2] qa-validator: revisar spec, hashes y `specs/003-web-itchio/evidence/web-interaction.md` por W02–W10/FR-003/004/005; distinguir toque físico, clic mediante CUA del navegador y pruebas automatizadas, verificar rechazo por ocupación con fondos y sin fondos en celda libre; emitir PASS/FAIL/NOT RUN por caso, sin modificar checkout; depende de T007 y de la aprobación de cualquier corrección añadida.

## Fase 4: Historia de usuario3 — Paquete listo para cargar (Prioridad: P2)

**Objetivo**: generación repetible, ZIP correcto y guía para carga manual.
**Criterio independiente**: W11, reexportación limpia y juego servido desde ZIP
extraído; CI entrega artefacto sin publicación. US3 usa el exportador de US1,
pero puede prepararse mientras US2 se prueba al no compartir archivos.

- [X] T009 [P] [US3] dev-godot: crear `tools/web/export.sh` y `.github/workflows/export-web.yml` con Godot estándar 4.7.1, salida limpia, ZIP raíz con index.html y manifiesto exterior de SHA/revisión/dirty/tamaño; CI reutiliza el comando y adjunta artefacto sin butler/credenciales/publicación, conservando `ci.yml` GUT+import y deploys móviles; depende de T006 aprobada, sin ejecutar verificaciones por desarrollo.
- [X] T010 [US3] godot-tester: comprobar `tools/web/export.sh` y `.github/workflows/export-web.yml` mediante generación desde copia limpia, listado exterior+PCK, extracción/servidor y manifest/hashes; registrar `specs/003-web-itchio/evidence/web-package.md`, límites portal/licencias/exclusiones y resultado local o run CI remoto real claramente separado; depende de T009 entregada, sin editar herramientas.
- [X] T011 [US3] docs-writer: redactar `docs/WEB_EXPORT.md` con requisitos y pasos locales/CI realmente verificados, archivo ZIP obtenido, itch.io HTML Game/Click to play/iframe 1152×648/Mobile Friendly condicionado a evidencia y estado de navegadores; enlazar desde `README.md`, sin afirmar subida/publicación ni intervenir cuenta; depende de T008 y T010 disponibles para QA, y conserva alcance de sus veredictos.

## Corrección necesaria de FR-003: recoger sin desplegar

Añadida durante T007 por fallo reproducido con saldo suficiente, conforme al
ciclo adicional previsto por el plan. Conserva reglas y balance; corrige la
ruta de entrada que permite recoger y desplegar con el mismo gesto. No es
trabajo adicional de gameplay. Los IDs iniciales y sus aprobaciones se conservan.

- [X] T015 godot-tester: reproducir W02 en el ZIP de producción y conservar observador de solo lectura y evidencia; escribir y ejecutar RED en `tests/unit/` con saldo suficiente, celda libre y pickup aislado usando la ruta real de eventos y picking, verificando recolección única, ausencia de gasto/despliegue y mouse/toque según el entorno; QA aprueba la prueba por su fallo esperado válido antes de T016. Sin modificar implementación.
- [X] T016 dev-godot: corregir únicamente el enrutamiento de recolección/despliegue en `scenes/levels/nivel_monte_calvo.gd` y, solo si es indispensable, `ammo_pickup.gd`, a partir de T015 RED aprobado y skills de input/2D; conservar cantidades, costos, ocupación, datos, InputMap y arte. No escribe ni ejecuta pruebas; depende de T015 aprobado.
- [X] T017 godot-tester: ejecutar GREEN de las mismas pruebas RED, regresión GUT completa y repetición real del gesto con fondos en navegador; reexportar el candidato tras el cambio, verificar hashes de invariantes permitiendo solo la corrección documentada y repetir verificaciones del paquete invalidadas por el nuevo código. Entregar evidencia RED/GREEN y limitaciones; depende de T016 entregada.
- [X] T018 qa-validator: revisar independientemente causa, diff mínimo, prueba RED válida, GREEN, regresión y evidencia del navegador; emitir veredicto sobre la corrección FR-003 antes de completar T007/T008. No modifica checkout ni marca tareas; depende de T017.

T007 se completa después de esta corrección y de sus casos físicos Android;
T008 conserva su revisión de toda US2. T011/T014 documentan el comportamiento
aprobado y el nuevo ZIP. Son **14 tareas iniciales + 4 de corrección requerida**.

## Fase final: Regresión, rendimiento y cierre

- [X] T012 godot-tester: verificar estado final en `specs/003-web-itchio/evidence/final-validation.md` con importación limpia/GUT completo, hashes de reglas/arte/nativos y W12 medido en escritorio+Chrome Android (carga, duración, condiciones y frame times/cadencia/memoria disponible); repetir smoke si el paquete cambió desde T007, registrar Firefox/Safari/Web iOS según disponibilidad y gates constitucionales pendientes sin adjudicarles PASS; depende de T008, T010 y T011 entregada, sin revalidación histórica ficticia de 002.
- [X] T013 qa-validator: revisar conjunto final y trazabilidad FR-001–012/SC-001–007 en `specs/003-web-itchio/`, `tools/web/`, `.github/workflows/export-web.yml` y `docs/WEB_EXPORT.md`; contrastar reporte final, ZIP/PCK, licencia, invariantes y matriz real, distinguiendo artefacto WIP, aceptación web acotada y gates de difusión/rendimiento; depende de T012, no marca tareas ni corrige archivos.
- [X] T014 docs-writer: consolidar solo decisiones/evidencia aprobadas de 003 en `docs/WEB_EXPORT.md`, `README.md`, `docs/ARCHITECTURE.md` y `specs/003-web-itchio/evidence/implementation-status.md`, con vínculoIssue #14, ruta/hashZIP, matriz y pendientes exactos; depende del veredicto T013, qa-validator revisa este diff documental y confirma que no cambió el build probado antes del marcado por el orquestador.

## Dependencias y ejecución

```text
T001 ─┬─ T002 ─┐
      └─ T003 ─┴─ T004 → T005 → T006 ─┬─ T007 → T008 ─┐
                                    └─ T009 → T010 ─┴─ T011 → T012 → T013 → T014
```

- T001 se realiza antes de implementación. T002/T003 pueden ir en paralelo;
  preparación de editor/templates no debe importar/editar el checkout.
- Después de T006, T007 y T009 pueden avanzar en paralelo: el tester opera el
  export actual/UI y el dev solo escribe herramientas/workflow. Serializar
  T010 con T007 al usar export/import/browser; no permitir ediciones de preset
  durante pruebas. El diagrama expresa dependencias, no permiso para carreras.
- US1 contiene 3 tareas, US2 inicialmente 2, US3 contiene 3; setup 3 y cierre 3: **14 iniciales**, más T015–T018 para la corrección necesaria de FR-003.
- Si surge comportamiento nuevo, añadir tareas sin renumerar: RED depende de
  contrato/harness disponible; dev depende de RED aprobado; GREEN/QA después.
  No paralelizar RED e implementación del mismo caso.

## Estrategia de entrega

1. Completar el incremento US1 con export mínimo y evidencia; después probar
   interacción US2 y preparar empaquetado US3 en archivos independientes.
2. Ante rechazo, devolver al rol responsable según el flujo vigente. QA
   aprueba por tarea/alcance; solo el orquestador marca los checkboxes.
3. Registrar los navegadores ausentes y gates pendientes exactamente. No
   anunciar soporte universal, publicación en itch.io o cierre de 002.
4. El orquestador coordina commits con formato T00X y PR en borrador en español
   vinculado aIssue #14 cuando los gates de cierre se cumplan. La persona decide
   promover/fusionar y publicar en el portal. La generación del ZIP no autoriza
   difusión externa antes del smoke constitucional.

## Registro de preparación Spec Kit

- `resolve-template.sh spec-template --json`: plantilla del preset activa.
- `setup-plan.sh --json`: FEATURE_DIR 003 e IMPL_PLAN correctos, con
  `SPECIFY_FEATURE_DIRECTORY=specs/003-web-itchio` explícito.
- `setup-tasks.sh --json`: plantilla activa desde
  `.specify/presets/demons-agent-tdd/templates/tasks-template.md`; se usó su
  contenido para la organización, roles y gates. El campo BRANCH del script
  representa el ID de feature, no crea ni demuestra una rama Git.
- Sin `.specify/extensions.yml`: no hay hooks pre/post que ejecutar.
- Preparación termina al revisar estas tareas; entrega a los agentes mediante
  el orquestador equivalente a `/implementar-feature 003-web-itchio`, sin
  invocar `speckit-implement`.

## Registro del orquestador

- 2026-10-15: `qa-validator` emitió **APROBADO** para T001 (los cinco documentos
  comunes y la enmienda 2.0.0) y para la preparación Spec Kit completa.
  Alcance documental; no acredita exportación, interacción ni rendimiento Web.
- 2026-10-15: `qa-validator` emitió **APROBADO T002/T003**: importación limpia,
  GUT 183/183 y 496 aserciones, 110/110 archivos protegidos idénticos a
  `b670d86`; hashes, versión y templates del toolchain estándar verificados.
  Evidencia: [baseline](evidence/baseline.md) y [toolchain](evidence/toolchain.md).
  Aprobación de prerrequisitos; compatibilidad Web todavía pendiente.
- 2026-10-15: primer intento T004/T005 **RECHAZADO** por QA: el filtro de
  escenas omitió dependencias cargadas desde GDScript; exportar con retorno 0
  no bastó para iniciar el combate. Dev corrigió el filtro de recursos y el
  tester repite la exportación. No hubo cambio de mecánicas ni RED artificial.
- 2026-10-15: segundo intento **APROBADO T004/T005/T006** por `qa-validator`: W01
  en 3/3 cargas Chrome, dos tamaños, PCK de 78 archivos con dependencias y
  exclusiones verificadas; 108/110 hashes intactos, solo dos configuraciones
  autorizadas difieren. [Arranque](evidence/web-startup.md). US2, Android Web,
  ZIP final, licencias y rendimiento siguen pendientes; habilitadas T007/T009.
- 2026-10-15: `qa-validator` emitió **APROBADO T009/T010** para generación local
  y W11: ambas salidas limpias, hashes de 12 miembros/ZIP, PCK de 78 recursos,
  licencias y arranque extraído verificados. [Paquete](evidence/web-package.md).
  No acredita CI remoto, US2, Android Web, smoke completo ni rendimiento;
  el ZIP sigue como candidato WIP hasta completar las verificaciones restantes.
- 2026-10-15: T007 detectó fallo W02 con reserva 12: un clic de recolección
  gastó 10 y desplegó además de recoger. Se abren T015–T018 como ciclo TDD
  requerido por FR-003/SC-007, sin cambiar reglas ni balance. No se aprueba
  el candidato para difusión; la prueba física espera la corrección.
- 2026-10-15: **APROBADO T015 (solo pruebas RED)** por `qa-validator`: dos
  controles de picking pasan y dos regresiones mouse normal/emulado fallan
  por saldo 5 en lugar de 15 y despliegue extra. Sin error de entorno;
  raw touch excluido del RED. [Prueba RED](evidence/t015-red.md). Implementación
  todavía pendiente; se autoriza T016, sin aprobar el comportamiento.
- 2026-10-15: T017 obtiene GREEN en las cuatro pruebas originales, pero QA
  detecta bloqueo estático T016: filtrar mouse emulado puede impedir W03 móvil
  porque ScreenTouch no coincide con las acciones actuales. Se conserva el RED
  histórico aprobado y se añade regresión W03 con mouse normal/emulado dentro
  de T017, antes de corregir el filtro. No se exporta esta versión ni se aprueba
  T016; primer rechazo de esta implementación por regresión de entrada.
- 2026-10-15: QA **APROBÓ la extensión RED W03 de T017**: control normal
  despliega con costo 10, mouse emulado queda incorrectamente bloqueado.
  Los cuatro tests T015 originales son byte idénticos; se añaden dos casos.
  [RED W03](evidence/t017-w03-red.md). Dev autorizado a retirar la guarda
  emulada antes del GREEN final de seis casos y la suite ampliada.
- 2026-10-15: tras la enmienda T016, T017 confirma **GREEN 6/6** (36 aserciones)
  y **189/189 GUT** (532 aserciones, tres avisos históricos). Importación
  estándar y UID de prueba correctos. Se guarda candidato para export limpio;
  T016/T017/T018 no se marcan aún: resta la repetición real Web y QA.
- 2026-10-15: **APROBADO T016/T017/T018** por QA, acotado a la corrección
  FR-003 en código y escritorio Web: RED/GREEN 6/6, GUT 189/189, paquete
  actualizado 4a2915c íntegro y W02/W03 durante PLAYING con repetición visual
  en producción. W04/W05 controlados conservados. Android físico, resize,
  iframe, smoke y rendimiento permanecen abiertos en T007/T008/T012.
- 2026-10-15: QA **APROBÓ el informe y la documentación de entrega parcial WIP**,
  no la aceptación global: matriz y métricas verificadas en
  [validación parcial](evidence/final-validation.md) y
  [estado de implementación](evidence/implementation-status.md). Permanecen
  **12/18 tareas aprobadas**; T007/T008/T011/T012/T013/T014 siguen abiertas.
  La prueba física espera respuesta de la persona; no se cierra la feature,
  se publica el juego ni se crea el PR final con gates pendientes.
- 2026-10-16: QA aprobó únicamente la evidencia de preparación Android:
  aviso de Chrome cerrado, pero pantalla aún en retrato y orientación 0/0
  bloqueada. El intento temporal de giro fue rechazado por Android con
  `WRITE_SETTINGS`; relectura 0/0, ningún cambio ni restauración necesaria.
  [Preflight](evidence/android-preflight-2026-10-16.json),
  [intento registrado](evidence/android-rotation-attempt.json).
  Sin gestos de gameplay nuevos; siguen 12/18 y T007 pendiente. La persona
  debe desbloquear el giro y volver a Chrome horizontal antes de iniciar.
- 2026-10-16: QA **APROBÓ W02–W05 y W07 de forma acotada** en Chrome Android
  físico horizontal, mediante la copia observada de solo lectura. Los eventos
  PRE/POST durante PLAYING confirman recolección sin despliegue, despliegue
  único con costo10 y rechazos por ocupación con fondos y por fondos
  insuficientes. Los pares touch/mouse pertenecen al mismo gesto y no duplican
  su efecto. [Evidencia Android](evidence/android-validation.md). La repetición
  visual en producción sin observador y el regreso real de pestaña siguen
  pendientes; no se completan T007/T008 ni el gate de rendimiento. Se mantienen
  **12/18 tareas aprobadas** y el mismo candidato de fuente `4a2915c`.

- 2026-10-16: **APROBADO T007/T008** por QA para Chrome escritorio y el Xiaomi
  horizontal. Los cuatro casos físicos observados quedan corroborados por la
  prueba humana en producción; W08 acredita partidas manuales hasta LOST con
  datos idénticos en copia de solo lectura, sin atribuir el terminal oculto al
  ZIP. W10 combina regreso Android en el mismo run sin recarga observada y
  recarga nueva de escritorio; foco de escritorio sigue NOT RUN. Evidencia:
  [interacción consolidada](evidence/web-interaction.md) y
  [producción Android](evidence/android-production-summary.json). **14/18**
  tareas aprobadas; rendimiento sostenido y aceptación global siguen pendientes.

- 2026-10-16: **APROBADO T011/T012** por QA: guía, README y seguimiento
  sincronizados con T007/T008; import limpio, GUT189/189 e invariantes del mismo
  candidato conservados, con medidas reales de escritorio/Android y métodos
  explícitos. W12 acredita el informe de medición, no certifica60FPS sostenidos,
  carga fría, memoria exclusiva ni entornos/CI remoto no ejecutados.
  [Guía](../../docs/WEB_EXPORT.md), [reporte final](evidence/final-validation.md).
  **16/18** tareas aprobadas; se abre T013 y se preserva la validación global
  pendiente, sin modificar el juego ni repetir ejecuciones por documentación.

- 2026-10-16: **APROBADO T013** por QA: trazabilidad FR001–012/SC001–007
  completa para la entrega Web acotada de003. SC006, el plan y el contrato
  permiten cerrar sus tareas con métodos y límites explícitos; esto no
  certifica60FPS sostenidos, el dispositivo constitucional de referencia,
  carga fría, memoria exclusiva ni los entornos/CI remoto NOT RUN. El smoke
  manual observado satisface el alcance acordado. **17/18**; habilitada T014
  y después PR en borrador. Sin cierre de002, merge ni publicación en itch.io.

- 2026-10-16: **APROBADO T014** por QA: README, guía de exportación,
  arquitectura, seguimiento y estado de SPEC sincronizados con la entrega
  acotada. ZIP, script y prueba mantienen sus hashes; no hubo nueva ejecución
  por los cambios documentales. **18/18 tareas de003 aprobadas**. Se prepara
  commit y PR en borrador sobre `codex/002-monte-calvo-terreno-trincheras`, con
  dependencia explícita; 002, rendimiento global, merge y publicación conservan
  sus límites y decisiones pendientes.

## Integración de main tras el PR #16 — 2026-10-16

La persona autorizó actualizar el PR #15 y dejarlo para revisión, sin fusionarlo.
Se incorporó `main` (`0cc19d0`) en `7309d8f`, conservando el historial y las
18 aprobaciones anteriores. QA aprobó la resolución documental: constitución
2.1.0 reúne Web/GDScript y la referencia Xiaomi exclusiva de 002; diseño y
arquitectura conservan el arte y el arreglo I4 aprobados. No hay lógica nueva,
por lo que no se fabrica otro RED ni se repite la matriz física por rutina.

Tester y QA confirmaron **364/364 fuentes protegidas idénticas** a ambos padres,
InputMap y presets nativos conservados. Importación y exportación limpias del
snapshot integrado terminaron con código 0. El ZIP contiene 12 miembros y 78 recursos;
solo difieren 51 identificadores internos generados en seis escenas compiladas,
sin cambios funcionales. QA rederivó el diagnóstico y aprobó el paquete y la
reutilización de la evidencia de interacción. [Informe compacto y manifiesto](evidence/main-integration.md).

Los dos archivos nuevos conservan 89 líneas de evidencia mínima reproducible;
los registros extensos quedan fuera del diff y se declara su retención. Este
registro no atribuye a la nueva revisión los éxitos de CI anteriores: el
orquestador comprobará GUT/importación y exportación de la última punta publicada
antes de promover el PR, y enlazará los resultados reales en su descripción.
Se mantienen los límites de navegadores, rendimiento y ausencia de publicación.
No se crean tareas ni se cambian checkboxes por esta sincronización documental.
