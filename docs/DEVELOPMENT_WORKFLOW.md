# Desarrollo con Spec Kit y agentes

Esta es la referencia operativa compartida del proyecto. Se aplica junto con
[AGENTS.md](../AGENTS.md) y la
[constitución](../.specify/memory/constitution.md). Las definiciones de los
roles están en [`.claude/agents/`](../.claude/agents/), también para entornos
que usen otros mecanismos de delegación.

## Preparación y entrega a los agentes

**Spec Kit prepara; los agentes implementan, prueban y validan.**

1. Spec Kit produce `spec.md`, aclaraciones, `plan.md`, contratos y `tasks.md`.
   Sus herramientas de constitución, checklists y análisis ayudan a preparar
   y revisar esos documentos. No ejecutan código del juego, pruebas ni la
   implementación; tampoco aprueban tareas o marcan sus checkboxes.
2. El workflow del proyecto, **`demons-preparation`**, termina al revisar las
   tareas; usa ese ID y no el workflow bundled `speckit`. La
   ejecución se inicia mediante `/implementar-feature <feature-id>` en
   Claude Code o delegando al `project-orchestrator` equivalente en otro
   entorno. El comando heredado `speckit-implement` solo informa de esta
   separación; no implementa ni dispara la orquestación por su cuenta.
3. El orquestador comprueba alcance, documentos y checklists. Si estos tienen
   pendientes, los presenta y obtiene la decisión de la persona antes de
   implementar. Reutiliza el Issue de la feature, incluidos los cerrados
   (`gh issue list --state all --search "<feature-id> in:title"`), y prepara
   la rama una sola vez. Los agentes reciben la rama Git real esperada.
4. El orquestador clasifica las tareas y ordena sus dependencias. Una tarea
   de pruebas no se asigna primero a quien tiene prohibido escribir pruebas.
   Al delegar, entrega IDs, criterios de aceptación, archivos, rama esperada,
   instrucciones del rol y reportes previos completos.

La lectura de un documento, su generación por Spec Kit y una aprobación de
checklist de especificación no equivalen a validación de una implementación.
Las consultas y correcciones documentales puntuales mantienen su alcance;
no disparan por sí solas la implementación de una feature, Issues o un PR.

## Responsabilidades y tipos de tarea

| Trabajo | Agente responsable | Evidencia para QA |
|---|---|---|
| Prueba de un comportamiento nuevo o corrección de un bug | `godot-tester`, fase RED | Prueba contra el spec que falla por el comportamiento esperado ausente |
| Implementación de ese comportamiento | `dev-godot`, después de RED | Cambios acotados y reporte de desarrollo; GREEN y regresión confirmados por el tester |
| Verificación de código ya implementado | `godot-tester`, fase GREEN | Resultado de pruebas pertinentes, regresión y verificaciones manuales aplicables |
| Recursos, escenas, arte o configuración sin comportamiento nuevo comprobable automáticamente | `dev-godot` | Criterios del plan y comprobaciones de integración/visuales pertinentes |
| Tarea exclusivamente documental | `docs-writer`, autoría de borrador | Documento contrastado con sus fuentes, sin afirmar resultados no verificados |
| Validación independiente | `qa-validator` | Veredicto sobre la tarea y la evidencia; nunca modifica el checkout validado |
| Coordinación y estado | `project-orchestrator` | Registra reportes y marca `[X]` únicamente después de `APROBADO` |

La lógica de daño, munición, moral, oleadas y victoria/derrota exige pruebas
automatizadas aunque la solicitud no las enumere. Para arte, comentarios o
documentos sin lógica nueva, justifica la verificación apropiada; no crees
pruebas artificiales que solo repitan la implementación ni un fallo RED
fabricado. El tester puede hacer comprobaciones manuales o de integración;
QA contrasta de forma independiente lo que se afirma haber verificado.

## TDD para cambios de comportamiento

El ciclo se aplica por comportamiento o grupo de tareas relacionadas:

**Tester RED → desarrollo → tester GREEN → QA → documentación.**

1. **RED — `godot-tester`:** lee primero el spec, los contratos y los casos
   de aceptación. Escribe la prueba y la ejecuta antes de la implementación.
   Registra comando, resultado y aserción que falla por el requisito ausente.
   Errores de entorno, importación, sintaxis o un test incorrecto no demuestran
   RED. Si falta un contrato o esqueleto mínimo para ejecutar la prueba, se
   prepara como trabajo de setup explícito, sin implementar el comportamiento.
2. **Desarrollo — `dev-godot`:** recibe las pruebas y el reporte RED y realiza
   la implementación necesaria. No escribe o modifica pruebas ni las ejecuta.
   Reporta qué cambió y devuelve al tester la verificación de GREEN.
3. **GREEN — `godot-tester`:** vuelve a ejecutar las pruebas RED y la regresión
   pertinente. Solo declara GREEN cuando el comportamiento pasa y no introduce
   regresiones. Si falla la implementación, devuelve la evidencia a desarrollo;
   si el error es del test, corrige su propio test sin rebajar el requisito.
   Un refactor posterior vuelve a pasar por el tester.
4. **QA — `qa-validator`:** revisa de forma independiente spec, código,
   calidad de pruebas y reportes RED/GREEN. Puede repetir comprobaciones; no
   corrige código, tests o documentación ni marca tareas. Cualquier experimento
   que requiera mutaciones se hace en una copia temporal aislada, nunca sobre
   el checkout validado.
5. **Documentación — `docs-writer`:** después de la aprobación de la
   implementación, documenta únicamente el comportamiento validado y consolida
   decisiones cuando corresponda. Una tarea documental independiente usa el
   modo autoría de borrador y pasa por QA antes de marcarse completa; no necesita
   otro ciclo de documentación de sí misma.

Para una tarea que solo añade cobertura de un comportamiento ya existente,
el tester registra esa circunstancia y comprueba GREEN; no modifica el juego
para fabricar RED. TDD sigue siendo obligatorio para el comportamiento nuevo
o la corrección de un bug que esa prueba deba guiar.

## Dependencias y significado de completado

- Las tareas conservan el formato `[ID] [P?] [US?] Descripción` dentro de una
  lista con checkbox. Indica su naturaleza y dependencias en la descripción,
  sin crear etiquetas incompatibles con el formato de Spec Kit.
- Una tarea RED depende del contrato/setup necesario para ejecutarse, no de
  la implementación completa que debe guiar. La implementación depende de la
  evidencia RED. No describas ambos pasos como dependientes entre sí.
- QA puede aprobar una tarea exclusivamente RED si el test es válido y su
  fallo esperado está documentado. El orquestador puede marcar **esa tarea de
  pruebas**; la implementación relacionada permanece pendiente hasta GREEN y
  su propia aprobación. Un RED esperado no es una regresión ni un rechazo.
- Para implementar y completar comportamiento se exige GREEN más `APROBADO`.
  El orquestador es el único que marca `[X]`; ni el tester ni QA lo hacen.
- Al actualizar instrucciones, conserva IDs y checkboxes históricos. No
  inventes evidencia RED pasada ni interpretes `[X]` como prueba de que hoy se
  ejecutó una verificación. Si aparece una regresión, registra el hallazgo.
- Ejecuta secuencialmente trabajos sobre los mismos archivos, incluso si
  estaban marcados `[P]`. No cambies de rama entre etapas del ciclo.

## Rechazos, cierre y límites

`RECHAZADO` vuelve al agente responsable: errores de implementación a desarrollo,
errores de pruebas al tester y errores documentales a documentación. Ante
`AMBIGUO`, presenta la decisión faltante a la persona. Al tercer rechazo
consecutivo de una misma tarea, escala en lugar de seguir reintentando.

Al cerrar una feature, el tester confirma la suite completa de GUT y las
verificaciones manuales exigidas por la constitución. Documentación consolida
las decisiones y el orquestador publica la rama y crea el PR **en borrador**,
en español y vinculado al Issue. Comprueba además la política de versiones de
[ARCHITECTURE.md §7](ARCHITECTURE.md#7-consideraciones-multiplataforma) cuando
el cambio vaya a distribuirse a testers. La persona decide promover o fusionar
el PR; ningún agente lo hace automáticamente.

La adaptación a otra IA conserva estas responsabilidades, evidencias y orden.
Si falta delegación, GUT o una skill requerida, informa la limitación concreta
antes de esa etapa; no presentes una auto-revisión como QA independiente ni
ejecutes el flujo genérico de Spec Kit como sustituto.

## Fuente de las personalizaciones y actualizaciones

Los comandos y plantillas de preparación pertenecen al preset
`demons-agent-tdd`, cuya fuente versionada está en
[`tools/speckit/presets/demons-agent-tdd/`](../tools/speckit/presets/demons-agent-tdd/).
El workflow `demons-preparation` se instala por separado desde
[`tools/speckit/workflows/demons-preparation/`](../tools/speckit/workflows/demons-preparation/).
Las skills de Claude y las copias de `.specify/presets/` son salidas generadas;
los agentes, esta guía y la constitución siguen siendo archivos propios.

Consulta [tools/speckit/README.md](../tools/speckit/README.md) para mantener el
paquete. Antes y después de refrescar Spec Kit, ejecuta el verificador sin
iniciar el juego ni una feature. Mantener la fuente del preset no sustituye
comprobar que sus comandos y plantillas siguen activos tras una actualización.

## Historial

| Fecha | Cambio |
|---|---|
| 2026-10-15 | Separación explícita entre preparación Spec Kit y ejecución por agentes; ciclo TDD y tratamiento de tareas RED, arte y documentación |
| 2026-10-15 | Personalizaciones empaquetadas en un preset local y workflow independiente; mantenimiento fuera de los archivos core |
