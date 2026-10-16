# Implementation Plan: Monte Calvo Web para itch.io

**Feature ID**: `003-web-itchio` | **Planned Branch**: `codex/003-web-itchio` | **Date**: 2026-10-15 | **Spec**: [spec.md](spec.md)

**Input**: `specs/003-web-itchio/spec.md`.
**Issue**: [#14](https://github.com/Juanpvivas/demons/issues/14).

**Note**: Spec Kit prepara este documento; la ejecución pertenece a los agentes
según `docs/DEVELOPMENT_WORKFLOW.md`. No se ejecutaron builds o pruebas desde
esta preparación. El orquestador ya preparó la rama desde `b670d86`, que
contiene el arte WIP de 002 y depende de la integración Spec Kit de PR #12.

## Summary

Entregar Monte Calvo actual como un paquete Web descargable, listo para cargar
manualmente en itch.io. Añadir preset Web de un hilo y renderer Compatibility
solo para Web, exportación local repetible y artefacto CI; conservar Mobile,
Android/iOS nativos, gameplay, arte e InputMap. Comprobar arranque, interacción
real por clic/toque, resizing y partida, y documentar la matriz efectivamente
probada. No publicar, operar cuenta o configurar monetización.

La persona confirmó el cambio de prioridad hacia Web. 002 continúa abierta:
su evidencia histórica PC/Android nativo y sus gates iOS/rendimiento no se
reescriben, heredan como cerrados ni convierten en aceptación Web.

## Technical Context

**Language/Version**: GDScript de Godot 4.7.1; utilidades pequeñas Bash/Python
para exportar/inspeccionar y YAML para CI. Sin dependencia C# del juego.

**Primary Dependencies**: Godot estándar 4.7.1 stable y templates Web de igual
versión; GUT 9.7.1 ya versionado para regresión; Python 3 y ZIP; GitHub Actions
existente. Entorno Mono local se conserva para pruebas/desarrollo nativo.

**Storage**: No persistencia nueva ni backend. `build/` ignorado para salida,
ZIP y manifest; `specs/003-web-itchio/evidence/` para reportes versionables,
excluido de importación mediante `.gdignore`.

**Testing**: Suite GUT existente, importación limpia, inspección de export/PCK,
navegador visible con clic mediante CUA del navegador, Chrome en Xiaomi físico con toque, smoke manual
de producción y pruebas separadas de victoria/derrota. Si emerge lógica nueva,
RED específico antes de implementación, luego GREEN y QA independiente.

**Target Platform**: Web escritorio y móvil, más Android/iOS nativos conservados.
Aceptación inicial Web en Chromium escritorio y Chrome Android físico; Firefox,
Safari macOS y Web iOS se registran según disponibilidad, sin anunciar soporte
no comprobado. PC nativo continúa solo como entorno de desarrollo/prueba.

**Project Type**: Juego Godot 2D existente y paquete estático WebAssembly/WebGL2.

**Performance Goals**: Conservar el objetivo constitucional de 60 FPS estables
en Android de referencia; registrar además carga y rendimiento Web por sesión
real. Tiempo máximo de carga constitucional sigue TODO; no se inventa una
cifra ni se declara cumplimiento sostenido con una muestra corta. W12 exige
mediciones y límites explícitos; el gate constitucional no se elude.

**Constraints**: Sin cambios de mecánicas, balance, Resources, escenas, arte o
InputMap. Web usa `gl_compatibility`, un hilo, sin extensiones/PWA; Android/iOS
siguen con Mobile y su configuración/distribución. No modificar output HTML a
mano ni incluir herramientas de desarrollo en el PCK. No publicar a itch.io.

**Scale/Scope**: Un nivel existente con diez oleadas, una entrega ZIP y un
workflow de exportación; sin HUD/tutorial/menú nuevo, guardado, multijugador,
cuenta, pagos o catálogo de nuevos niveles. Máximo 14 tareas iniciales.

## Constitution Check

*GATE antes de investigación y reevaluado tras el diseño.*

La lectura inicial detectó la versión 1.1.0 con PC nativo y excepción C#:
**no autorizaba declarar el plan listo** con el alcance Web. La enmienda
**2.0.0**, escrita por docs-writer y revisada por QA durante la preparación,
resuelve ese gate antes de implementación; la lectura final de este plan usa
2.0.0 y conserva el Sync Impact Report de la enmienda.

| Principio/restricción | Cumplimiento previsto y evidencia de ejecución |
|---|---|
| I. Código/datos y separación | No alterar gameplay o datos; manifests antes/después. GDScript compartido sin dependencia .NET. |
| II. Testing/TDD y smoke | Setup/export sin RED artificial. Regresión GUT + clic/tap real + smoke hasta terminal; cualquier bug exige RED antes de corregirse. QA independiente. |
| III. Consistencia Web/Android/iOS | Matriz real Web ratón/toque; preservar nativos y describir plataformas no probadas. No agregar silenciosamente HUD o recarga. |
| IV. Rendimiento | W12 registra carga y rendimiento Web; 60 FPS Android de referencia y TODO de carga siguen vigentes. Resultados insuficientes dejan gate abierto. |
| Restricciones de plataforma | Web + Android + iOS; nada de instaladores nativos PC de producto. Override gráfico solo Web. |
| Governance y workflow | Enmienda 2.0.0 previa; Spec Kit solo prepara. Agentes con roles separados, solo orquestador marca tras QA. |

**Resultado postdiseño**: no se planifica excepción constitucional ni cambio de
juego. Preparación documental lista para revisión de QA del conjunto. El paso
a ejecución requiere su veredicto; implementación, mediciones y aceptación
continúan pendientes aunque la política documental ya esté aprobada.

**Aclaración del método de entrada (QA, 2026-10-15)**: las acciones de
escritorio se realizan mediante CUA del navegador, con coordenadas tomadas
de una captura del canvas real. Se registra la cadena evento de entrada →
Godot → resultado, contrastando saldo y celdas antes/después. No se usan
`HTMLElement.click()`, `dispatchEvent` ni llamadas a métodos del juego
para producir el resultado. Esto mantiene los casos funcionales y los
umbrales de evidencia; Android continúa con toque físico.

## Diseño técnico

1. **Entorno aislado**: verificar editor estándar y templates oficiales 4.7.1,
   versión y hashes. Mantener la instalación Mono actual; no guardar ejecutables
   ni rutas personales en el repo. La preparación de herramientas puede correr
   en paralelo con el baseline del tester sin tocar `.godot` ni abrir el proyecto.
2. **Preset mínimo**: añadir `Web` a `export_presets.cfg`, salida
   `build/web/index.html`, `variant/thread_support=false`,
   `variant/extensions_support=false`, `progressive_web_app/enabled=false`,
   `html/canvas_resize_policy=2`. Mantener shell estándar y opciones de textura
   compatibles con los PNG actuales. Seleccionar dependencias de las escenas
   de producción o filtros equivalentes; inspección de PCK obligatoria.
3. **Renderer Web**: explicitar `renderer/rendering_method.web="gl_compatibility"`
   bajo `[rendering]`. Ya es default del motor; no cambiar el valor Mobile
   global, ETC2/ASTC ni presets nativos. No añadir `runnable` heredado de 4.6.
4. **Presentación**: mantener primero stretch/base 1152×648 existentes y Adaptive.
   Probar 1152×648, 960×540 y Android horizontal. Solo ante fallo reproducible,
   aplicar ajuste de configuración `.web` con evidencia antes/después; no mover
   actores/cámara/tablero para encajar el export. Si el fallo exige lógica,
   detener ese tramo y crear nuevas tareas RED/dev/GREEN antes del cambio.
5. **Empaquetado**: `tools/web/export.sh` acepta `GODOT_WEB_BIN`, valida versión
   y exporta release en salida limpia bajo `build/`. Genera ZIP con inicio en
   raíz y manifest exterior con SHA/revisión/dirty/tamaños/hashes. Fallar con
   mensaje claro ante motor/templates ausentes o export incompleto. No empaquetar
   logs, manifests internos, ZIP anteriores, `.git` o credenciales.
6. **CI**: workflow nuevo `export-web.yml`, en PR y manual, fija Godot estándar
   4.7.1 con templates y llama al mismo comando. Conserva `ci.yml`, que **ya
   ejecuta GUT y luego importación**, más su notificación; no los sustituye con
   un mero export. No altera workflows Firebase/TestFlight. El artefacto puede
   generarse independientemente, pero su aceptación/entrega exige GUT/import
   aprobados. Sin `butler`, secretos itch o deploy. Validar localmente y registrar
   por separado si se dispone de un run remoto real.
7. **Validación**: [contrato W01–W12](contracts/web-delivery.md), hashes protegidos,
   matriz de entornos y evidencia. No reescribir historiales 001/002. QA distingue
   configuración/empaquetado aprobado de entrega Web y de cumplimiento global.

[Research](research.md) contiene decisiones, alternativas y fuentes oficiales;
[data-model](data-model.md) describe metadatos y registros, sin entidades nuevas
de gameplay. [Quickstart](quickstart.md) es guía ejecutable prevista, no resultados.

## Project Structure

### Documentation (this feature)

```text
specs/003-web-itchio/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── checklists/requirements.md
├── contracts/web-delivery.md
├── tasks.md
└── evidence/                  # creado por tester/documentación durante ejecución
```

### Source Code (repository root)

```text
project.godot                 # solo configuración Web explícita/aprobada
export_presets.cfg            # nuevo preset Web, nativos intactos
tools/web/export.sh           # generación y empaquetado
.github/workflows/export-web.yml
.github/workflows/ci.yml       # GUT+import existentes, conservar
docs/WEB_EXPORT.md            # guía de la entrega validada
build/                        # ignorado: web/, ZIP y manifest exterior
scenes/, core/, autoloads/, resources/, assets/  # conservar partida y arte
```

**Structure Decision**: Extender el proyecto existente sin backend, segundo
juego o framework Web. Herramientas bajo `tools/web/`, documentos transversales
en `docs/` y evidencia acotada en la feature. Sin cambios a templates core,
preset Spec Kit, skills generadas o archivos de 002.

## Organización de ejecución y gates

- `project-orchestrator`: Issue #14/rama ya preparados, entrega tareas a los roles,
  registra aprobaciones y prepara PR borrador al cumplir cierre. No código/tests.
- `dev-godot`: entorno/preset/export/CI; no ejecuta pruebas ni marca tareas.
- `godot-tester`: baseline, import/export de verificación, GUT, navegador y
  dispositivo; no modifica implementación. Solo él controla instancias Godot
  y UI durante validación para evitar carreras de importación.
- `qa-validator`: revisión independiente y solo lectura; veredicto acotado por
  tarea/evidencia. Ningún agente convierte disponibilidad limitada en PASS.
- `docs-writer`: borradores de política y documentación final de lo aprobado;
  no afirma resultados que aún no existen.

Una modificación de lógica no prevista requiere IDs nuevos en tasks, con RED
válido previo y gate QA; no se certifica retrospectivamente. Si no hay cambio
de comportamiento, inspección/import/export/manual son la validación apropiada.

## Complexity Tracking

No hay violaciones justificadas ni excepciones propuestas. Los requisitos de
plataformas se actualizaron por enmienda 2.0.0; los gates de smoke/rendimiento y
los pendientes históricos no se eliminan. Un paquete puede quedar generado
como WIP con límites explícitos, sin declararse listo para difusión externa.
