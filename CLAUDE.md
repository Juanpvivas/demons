# Demonios de las Trincheras — Contexto de proyecto

Este archivo se carga automáticamente al inicio de cada sesión de Claude Code en este repo. Su único propósito es orientarte rápido sobre dónde va el proyecto, sin que la persona tenga que repetir contexto.

## Antes de hacer cualquier cosa

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
- **`godot-tester`**, **`qa-validator`**, **`docs-writer`**, **`project-orchestrator`**: en construcción (ver historial de esta conversación de diseño).

Si la persona pide "implementar la feature X", el flujo correcto es invocar `project-orchestrator` (cuando exista) — no correr `/speckit-implement` directo, que se salta todo el pipeline de test/validación propio del proyecto.

## Historial de cambios de este archivo

| Fecha | Cambio |
|---|---|
| 2026-09-11 | Versión inicial — creado para dar continuidad de contexto entre sesiones nuevas de Claude Code |