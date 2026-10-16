---
description: "Plan de tareas Web/itch.io con roles, conservación de gameplay y QA"
---

# Tasks: Monte Calvo Web para itch.io

**Input**: `specs/003-web-itchio/spec.md` y `plan.md`; `research.md`,
`data-model.md`, `contracts/web-delivery.md` y `quickstart.md`.
**Flujo**: `docs/DEVELOPMENT_WORKFLOW.md` desde la raíz del repositorio.
**Execution Branch**: `codex/003-web-itchio`, preparada una sola vez por el
orquestador desde `b670d86`.
**Issue**: [#14](https://github.com/Juanpvivas/demons/issues/14).
**Estado**: preparación Spec Kit aprobada por `qa-validator`; ejecución por
agentes en curso. La prioridad Web no cierra ni reescribe 002.

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

- [ ] T007 [US2] godot-tester: ejecutar W02–W10 en navegador visible con clic OS y Chrome Xiaomi horizontal, incluyendo cuatro casos controlados, resize con clic posterior, iframe local, regreso de pestaña, recarga y partida manual hasta terminal; documentar `specs/003-web-itchio/evidence/web-interaction.md`, matriz/capturas y victoria/derrota GUT separadas; depende de T006 aprobada; si detecta bug, registrar reproducción y detener la corrección hasta nuevas tareas RED/dev/GREEN, sin parchear implementación.
- [ ] T008 [US2] qa-validator: revisar spec, hashes y `specs/003-web-itchio/evidence/web-interaction.md` por W02–W10/FR-003/004/005; distinguir toque físico, clic OS y pruebas automatizadas, verificar rechazo por ocupación con fondos y sin fondos en celda libre; emitir PASS/FAIL/NOT RUN por caso, sin modificar checkout; depende de T007 y de la aprobación de cualquier corrección añadida.

## Fase 4: Historia de usuario3 — Paquete listo para cargar (Prioridad: P2)

**Objetivo**: generación repetible, ZIP correcto y guía para carga manual.
**Criterio independiente**: W11, reexportación limpia y juego servido desde ZIP
extraído; CI entrega artefacto sin publicación. US3 usa el exportador de US1,
pero puede prepararse mientras US2 se prueba al no compartir archivos.

- [ ] T009 [P] [US3] dev-godot: crear `tools/web/export.sh` y `.github/workflows/export-web.yml` con Godot estándar 4.7.1, salida limpia, ZIP raíz con index.html y manifiesto exterior de SHA/revisión/dirty/tamaño; CI reutiliza el comando y adjunta artefacto sin butler/credenciales/publicación, conservando `ci.yml` GUT+import y deploys móviles; depende de T006 aprobada, sin ejecutar verificaciones por desarrollo.
- [ ] T010 [US3] godot-tester: comprobar `tools/web/export.sh` y `.github/workflows/export-web.yml` mediante generación desde copia limpia, listado exterior+PCK, extracción/servidor y manifest/hashes; registrar `specs/003-web-itchio/evidence/web-package.md`, límites portal/licencias/exclusiones y resultado local o run CI remoto real claramente separado; depende de T009 entregada, sin editar herramientas.
- [ ] T011 [US3] docs-writer: redactar `docs/WEB_EXPORT.md` con requisitos y pasos locales/CI realmente verificados, archivo ZIP obtenido, itch.io HTML Game/Click to play/iframe 1152×648/Mobile Friendly condicionado a evidencia y estado de navegadores; enlazar desde `README.md`, sin afirmar subida/publicación ni intervenir cuenta; depende de T008 y T010 disponibles para QA, y conserva alcance de sus veredictos.

## Fase final: Regresión, rendimiento y cierre

- [ ] T012 godot-tester: verificar estado final en `specs/003-web-itchio/evidence/final-validation.md` con importación limpia/GUT completo, hashes de reglas/arte/nativos y W12 medido en escritorio+Chrome Android (carga, duración, condiciones y frame times/cadencia/memoria disponible); repetir smoke si el paquete cambió desde T007, registrar Firefox/Safari/Web iOS según disponibilidad y gates constitucionales pendientes sin adjudicarles PASS; depende de T008, T010 y T011 entregada, sin revalidación histórica ficticia de 002.
- [ ] T013 qa-validator: revisar conjunto final y trazabilidad FR-001–012/SC-001–007 en `specs/003-web-itchio/`, `tools/web/`, `.github/workflows/export-web.yml` y `docs/WEB_EXPORT.md`; contrastar reporte final, ZIP/PCK, licencia, invariantes y matriz real, distinguiendo artefacto WIP, aceptación web acotada y gates de difusión/rendimiento; depende de T012, no marca tareas ni corrige archivos.
- [ ] T014 docs-writer: consolidar solo decisiones/evidencia aprobadas de 003 en `docs/WEB_EXPORT.md`, `README.md`, `docs/ARCHITECTURE.md` y `specs/003-web-itchio/evidence/implementation-status.md`, con vínculoIssue #14, ruta/hashZIP, matriz y pendientes exactos; depende del veredicto T013, qa-validator revisa este diff documental y confirma que no cambió el build probado antes del marcado por el orquestador.

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
- US1 contiene 3 tareas, US2 contiene 2, US3 contiene 3; setup 3 y cierre 3: **14**.
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
