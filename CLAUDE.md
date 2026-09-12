# Demonios de las Trincheras — Contexto de proyecto

Este archivo se carga automáticamente al inicio de cada sesión de Claude Code en este repo. Su único propósito es orientarte rápido sobre dónde va el proyecto, sin que la persona tenga que repetir contexto.

## Antes de hacer cualquier cosa

0. **Si estás en Claude Desktop, confirma que estás en la pestaña "Code", no en "Chat".** El modo Chat (con "Projects"/conocimiento subido) no tiene acceso real a este repo, aunque describa archivos con mucho detalle — cualquier edición ahí no toca disco. Señal de alerta: si una sesión dice "no tengo acceso a comandos de terminal aquí", no es este entorno. Ante la duda, verifica con `git status` que lo que se reporta como cambiado realmente aparece ahí.
1. **Revisa qué se ha hecho**: corre `git log --oneline -20` — los commits de tareas siguen el formato `T00X: descripción` (ver `dev-godot`). Esto es el registro más confiable de progreso real.
2. **Revisa qué falta**: abre `specs/<feature-activa>/tasks.md` y mira los checkboxes. `[X]` = verificado y aprobado por `qa-validator`, no solo implementado. `[ ]` = pendiente o en progreso.
3. Si hay una feature con tareas a medio marcar, asume que ese es el trabajo en curso — no empieces algo nuevo sin confirmar con la persona.

## Documentos de referencia (en orden de consulta)

| Documento | Qué contiene | Cuándo leerlo |
|---|---|---|
| `constitution.md` | Principios no negociables del proyecto (calidad, testing, UX, rendimiento) | Siempre — tiene precedencia sobre cualquier otro documento |
| `docs/SPEC.md` | Diseño del juego: mecánicas, economía, contexto histórico, alcance de MVP | Antes de tocar diseño o mecánicas |
| `docs/ARCHITECTURE.md` | Convenciones técnicas: estructura de carpetas, nombres, patrones (Resource, señales, autoloads) | Antes de escribir o revisar código |
| `specs/<feature>/spec.md`, `plan.md`, `tasks.md` | Requisitos, plan técnico y desglose de tareas de la feature activa | Antes de implementar cualquier tarea puntual |

## Subagentes del proyecto

Este proyecto usa un pipeline de subagentes especializados en `.claude/agents/`. No repitas su trabajo manualmente — invócalos:

- **`dev-godot`**: implementa una tarea ya asignada. No escribe tests, no marca tareas como completas, no crea ramas.
- **`godot-tester`**: escribe y corre tests (GUT) para una tarea que `dev-godot` ya implementó.
- **`qa-validator`**: audita de forma independiente (código + tests) contra el spec, `ARCHITECTURE.md` y `constitution.md`. No escribe ni edita nada — solo emite un veredicto (`APROBADO`/`RECHAZADO`/`AMBIGUO`).
- **`docs-writer`**: documenta una tarea ya aprobada, gradúa decisiones resueltas hacia `docs/SPEC.md`/`docs/ARCHITECTURE.md`, y consolida la documentación al final de la feature.
- **`project-orchestrator`**: coordina a los cuatro anteriores de principio a fin — crea el Issue de la feature, ejecuta el ciclo dev→test→validar→docs por cada tarea, y al final crea un PR en borrador que cierra ese Issue.

**Punto de entrada correcto**: si la persona pide "implementar la feature X", usa el comando `/implementar-feature <feature-id>` (en `.claude/commands/`) — invoca a `project-orchestrator` de forma determinista. **No corras `/speckit-implement` directo**: se salta todo el pipeline de test/validación propio del proyecto y no crea Issue ni PR.

## Historial de cambios de este archivo

| Fecha | Cambio |
|---|---|
| 2026-09-11 | Versión inicial — creado para dar continuidad de contexto entre sesiones nuevas de Claude Code |
| 2026-09-11 | Actualizado: los 5 subagentes están completos (ya no "en construcción"); se documenta el comando `/implementar-feature` como punto de entrada; se agrega advertencia sobre confirmar el entorno real (Code vs Chat de Claude Desktop) tras una confusión detectada en esta sesión de diseño. |