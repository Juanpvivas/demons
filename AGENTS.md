# Demonios de las Trincheras — Guía para agentes de IA

Este archivo reúne las instrucciones compartidas para cualquier asistente que
trabaje en este repositorio: un juego 2D de defensa por carriles en Godot 4.x,
con GDScript y pruebas GUT, orientado a Web y aplicaciones Android/iOS.
Web se publica y prueba solo en navegadores de computador; Android/iOS se
prueban como apps instaladas (APK/IPA o `.app` nativa de iOS Simulator).
No continuar pruebas Web en navegadores móviles. itch.io es el primer portal
Web previsto. La ejecución nativa en PC se conserva para desarrollo y pruebas,
sin instaladores Windows/macOS/Linux como destino de publicación.

Mantén aquí el flujo común. `CLAUDE.md` importa esta guía y solo contiene la
adaptación a Claude; no dupliques las reglas entre ambos archivos. El nombre
es `AGENTS.md`, en plural. Su lectura automática depende de la herramienta:
si no lo descubre, referencia este archivo desde su punto de entrada o
cárgalo explícitamente al iniciar el trabajo.

## Antes de empezar

1. **Comprueba el acceso real al repositorio:** verifica el directorio de
   trabajo y ejecuta `git status --short`. No afirmes haber editado o probado
   archivos si solo tienes una conversación o documentos adjuntos. Conserva
   los cambios locales de la persona.
2. **Revisa qué se ha hecho:** ejecuta `git log --oneline -20`. Los commits
   de tareas usan el formato `T00X: descripción`; contrasta el progreso
   documentado con el historial real.
3. **Identifica la feature:** usa el identificador indicado por la persona;
   si no lo indicó, consulta `.specify/feature.json` cuando exista y contrasta
   con `specs/`. Lee `specs/<feature>/tasks.md`: `[X]` significa verificado y
   aprobado por `qa-validator`, no solo implementado; `[ ]` significa pendiente
   o en progreso. Si hay trabajo a medio completar, conserva ese contexto y
   confirma el cambio de prioridad antes de iniciar otra feature.
4. **Lee las referencias aplicables.** No cambies mecánicas, balance o
   alcance sin una tarea que lo contemple.
5. **Distingue el destino probado:** una prueba en el editor/ejecutable local,
   en Web o en Android/iOS nativos acredita solo ese entorno. Conserva las
   evidencias históricas y registra las verificaciones Web por navegador y
   computador, y las nativas por app/dispositivo o emulador/simulador. No
   conviertas pruebas Web móviles históricas en pruebas nativas ni cierres
   pendientes de una feature anterior por cambiar las plataformas del producto.

## Documentos de referencia

| Documento | Contenido | Cuándo leerlo |
|---|---|---|
| [Constitución](.specify/memory/constitution.md) | Principios de calidad, testing, UX y rendimiento; tiene precedencia sobre otras prácticas del proyecto | Siempre |
| [Diseño del juego](docs/SPEC.md) | Mecánicas, economía, contexto histórico y alcance del MVP | Antes de tocar diseño o mecánicas |
| [Arquitectura](docs/ARCHITECTURE.md) | Carpetas, nombres, patrones Godot y convenciones de pruebas | Antes de escribir o revisar código |
| `specs/<feature>/spec.md`, `plan.md`, `tasks.md` | Requisitos, plan y tareas de cada feature | Antes de implementar una tarea |
| [Flujo de desarrollo](docs/DEVELOPMENT_WORKFLOW.md) | Preparación Spec Kit, TDD, tipos de tarea y evidencias de aprobación | Antes de coordinar o ejecutar una feature |
| [.claude/agents/](.claude/agents/) | Responsabilidades y procedimientos de los roles del proyecto | Antes de ejecutar o delegar un rol |

Las referencias antiguas a `constitution.md` se refieren a
`.specify/memory/constitution.md`; no hay una copia en la raíz.

## Spec Kit y flujo de implementación

**Spec Kit se usa para especificar, aclarar, planear, generar tareas y analizar
los documentos. La ejecución corresponde a los agentes.** El workflow de
Spec Kit termina al revisar las tareas; `speckit-implement` es un aviso de
compatibilidad sin ejecución. No lo precargues en los agentes ni uses sus
instrucciones genéricas para implementar, probar, validar o marcar tareas.

La referencia operativa es [docs/DEVELOPMENT_WORKFLOW.md](docs/DEVELOPMENT_WORKFLOW.md).
La fuente de los comandos y plantillas de preparación está en
`tools/speckit/presets/demons-agent-tdd/`. El preset genera las skills en
`.claude/skills/speckit-*/` y resuelve las plantillas desde su copia instalada
en `.specify/presets/`; conserva las convenciones de `specs/<feature>/`.
El workflow del proyecto se llama `demons-preparation` y termina al revisar
las tareas; no uses el workflow bundled `speckit` como punto de ejecución.

| Rol | Responsabilidad | Límites |
|---|---|---|
| `project-orchestrator` | Coordina Issue, rama, tipos de tarea, reportes y PR en borrador | No implementa, escribe pruebas ni sustituye a QA; es el único que marca `[X]` tras `APROBADO` |
| `godot-tester` | Escribe y verifica RED antes del cambio; confirma GREEN y regresión después | No modifica la implementación ni marca tareas |
| `dev-godot` | Implementa las tareas asignadas a partir del spec y de RED cuando aplique | No escribe, modifica o ejecuta pruebas; no marca tareas ni crea ramas |
| `qa-validator` | Valida de forma independiente spec, código, pruebas y evidencia | Solo emite veredicto; no modifica el checkout ni marca tareas |
| `docs-writer` | Documenta comportamiento aprobado o prepara borradores de tareas documentales para QA | No modifica gameplay ni ejecuta pruebas; no marca tareas |

Lee la definición de cada rol en `.claude/agents/<rol>.md`. Consulta las
memorias en `.claude/agent-memory/project-orchestrator/`, contrastándolas con
el código, las tareas y el flujo vigente.

Para cambios de comportamiento, conserva TDD:
**tester RED → desarrollo → tester GREEN → QA → documentación**.
El orquestador asigna las tareas de pruebas directamente al tester. Una tarea
RED puede aprobarse por su fallo esperado válido, sin dar por entregada la
implementación relacionada. La implementación solo se completa con GREEN y
`APROBADO`. No reconstruyas ni inventes evidencia RED de tareas históricas.
Para arte o documentación sin lógica nueva, usa criterios visuales o
verificaciones documentales apropiadas, sin exigir pruebas artificiales.

Una feature de Spec Kit puede entregarse en **varios PR pequeños**. El
orquestador define incrementos coherentes con sus IDs y dependencias, reutiliza
un Issue por feature y prepara una rama por incremento. Cada PR funcional
incluye su ciclo TDD completo, QA y documentación; aprobar RED no autoriza
fusionarlo con implementación pendiente. Arte y documentos conservan su
validación proporcional. No esperes a terminar toda la feature para entregar
un incremento aprobado.

El flujo detalla el tamaño orientativo y los commits por resultado. Para futuros
PR, no añadas archivos de evidencias a Git: reporta brevemente resultados,
comandos, límites y veredicto QA en el cuerpo del PR; usa logs de CI o temporales
durante la ejecución. Las pruebas, specs, planes, tareas y documentación útil
del producto siguen versionados, sin usarlos para volcar registros. Conserva
las evidencias históricas existentes.
Los PR intermedios usan `Refs #<issue>`; solo el último, cuando todos los
criterios estén cumplidos, usa `Closes #<issue>`.

El orquestador revisa checklists y mantiene la rama durante cada ciclo.
Ante `RECHAZADO`, devuelve el trabajo al rol
responsable; al tercer rechazo consecutivo de una tarea o ante `AMBIGUO`,
escala a la persona. Al entregar cada incremento, consolida documentación y
verificaciones, publica la rama y crea un PR **en borrador**, con descripción
breve y vinculado al Issue. Solo una petición explícita de la persona permite
promoverlo a revisión; nunca se fusiona automáticamente. Recomienda a la
persona `Squash and merge` para dejar un commit por PR en `main`, conservando
la trazabilidad RED/GREEN en el cuerpo del PR; no reescribas historial compartido o
aprobado sin autorización.

Según la constitución 4.1.1, **integración y publicación tienen gates distintos**.
`main` recibe incrementos funcionales con TDD/GREEN, compilación, CI,
documentación y `APROBADO PARA INTEGRACIÓN` independiente. Hardware físico,
renderer o paquete final sin certificar permanecen pendientes de publicación;
no se convierten en resultados aprobados ni bloquean por sí solos integración.
Los fallos reales de fuente, build o funcionalidad sí la bloquean. QA debe
examinar y declarar las caídas de rendimiento observadas y sus límites.

Distribuir a testers externos, Firebase, TestFlight, itch.io o tiendas exige
además `APROBADO PARA PUBLICACIÓN`, los requisitos físicos/60 FPS aplicables,
artefacto/renderer/versionado de destino y autorización explícita de la persona.
Un merge no publica: los workflows de distribución requieren gate explícito.
Solo el orquestador marca el alcance aprobado; una tarea que también contenga
publicación mantiene pendiente esa parte y no se marca completa por integración.

La única excepción autorizada para la beta 1.0.1 (build 4) está delimitada en
la [constitución V](.specify/memory/constitution.md#excepción-autorizada-beta-101-build-4).
No convierte las pruebas físicas diferidas en aprobadas ni dispensa QA o la
verificación de firma/empaquetado/versionado previa al upload.

Las consultas y correcciones documentales puntuales conservan su alcance;
no disparan automáticamente la implementación de una feature.

### Adaptación a la herramienta de IA

- **Claude Code:** `/implementar-feature <feature-id>` es el punto de entrada
  definido en `.claude/commands/implementar-feature.md`; delega al orquestador.
- **Otras herramientas:** usa sus mecanismos de delegación para reproducir
  los roles y el orden anteriores, proporcionando sus instrucciones y contexto.
  Los comandos `/...`, la herramienta `Skill` y los campos `model`, `tools`
  y `memory` de los archivos de Claude no son configuración universal.
- Si el entorno no permite subagentes o no dispone de una herramienta
  necesaria, informa la limitación antes de la etapa afectada. No presentes
  una auto-revisión como validación independiente ni marques tareas aprobadas
  sin evidencia de `qa-validator`.

## Mantenimiento del preset

Mantén las personalizaciones de Spec Kit en `tools/speckit/`, no editando las
skills generadas ni los templates core. El procedimiento de instalación,
actualización y recuperación está en [tools/speckit/README.md](tools/speckit/README.md).
Comprueba la fuente, la resolución y la materialización con
`python3 tools/speckit/verify.py` antes y después de actualizar la integración.
El preset y el workflow propio conservan sus fuentes; una actualización debe
verificarse antes de volver a usar los comandos. No actualices ni reinstales
Spec Kit automáticamente durante una tarea del juego.

## GodotPrompter

El proyecto habilita `godot-prompter@skillsmith` en `.claude/settings.json`;
las skills del plugin no están versionadas en este repositorio.
**Antes de implementar cualquier sistema de Godot, consulta y aplica la skill
correspondiente.** También aplica a todos los subagentes que escriban o
revisen código; incluye sistemas pequeños, Resources, autoloads, señales, UI,
animaciones y detección de enemigos.

El índice es `using-godot-prompter`. Algunos ejemplos:

| Sistema | Skills |
|---|---|
| Datos y arquitectura | `resource-pattern`, `state-machine`, `event-bus`, `component-system` |
| Escenas y arte 2D | `2d-essentials`, `scene-organization`, `assets-pipeline` |
| IA y movimiento | `ai-navigation`, `input-handling` |
| Animaciones | `animation-system`, `tween-animation` |
| Interfaz | `godot-ui`, `hud-system`, `responsive-ui` |
| Pruebas y revisión | `godot-testing`, `godot-debugging`, `godot-code-review` |

En Claude, consulta las skills del plugin mediante su mecanismo nativo. En
otras herramientas, descubre la instalación disponible y lee sus `SKILL.md`
y las referencias necesarias. No fijes rutas personales de instalación en el
repositorio. Si una skill requerida no está disponible, informa cuál falta;
no afirmes haberla aplicado ni sustituyas su consulta por conocimiento genérico.

## Historial de esta guía

| Fecha | Cambio |
|---|---|
| 2026-09-11 | Contexto original creado en `CLAUDE.md`; se documentaron los cinco agentes y el punto de entrada de implementación |
| 2026-09-12 | Se agregó la consulta obligatoria de GodotPrompter, también para subagentes |
| 2026-10-15 | Instrucciones comunes trasladadas a `AGENTS.md`, con adaptación a otras herramientas y ruta real de la constitución |
| 2026-10-15 | Spec Kit limitado a preparación; ejecución por agentes con TDD RED → desarrollo → GREEN → QA y guía operativa compartida |
| 2026-10-15 | Personalizaciones trasladadas al preset local `demons-agent-tdd`, con workflow propio `demons-preparation` y verificador de instalación |
| 2026-10-15 | Destinos Web + Android/iOS; navegador de computador incluido y PC nativo reservado a desarrollo/pruebas, sin convertir evidencia histórica en validación Web |
| 2026-10-16 | Entregas por incrementos con PR pequeños, TDD y QA completos, evidencia proporcional y cierre del Issue solo al completar la feature |
| 2026-10-16 | Futuros PR sin archivos nuevos de evidencias en Git; resultados y QA en el PR, manteniendo pruebas y documentación útil |
| 2026-10-19 | Por decisión de la persona y constitución 3.0.0, Web solo en computador; Android/iOS solo apps instaladas, sin continuar pruebas de navegador móvil y conservando evidencias históricas y requisitos nativos |
| 2026-10-19 | Constitución 4.0.0: gates separados de integración funcional y publicación; requisitos físicos conservados para publicar, sin distribución automática por merge |
| 2026-10-29 | Constitución 4.1.0: referencia a la excepción autorizada y acotada de la beta 1.0.1/build 4, conservando pendientes físicos y verificaciones de publicación no eximidas |
| 2026-10-29 | Constitución 4.1.1: trazabilidad de la corrección acotada de empaquetado de la misma beta, con nueva QA/CI antes de reintentar y sin ampliar la excepción |
