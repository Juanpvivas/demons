# Demonios de las Trincheras

Tower defense / lane defense 2D en Godot 4.x, inspirado en la historia real
del Batallón Colombia en la Guerra de Corea (apodados "los demonios de las
trincheras" por su ferocidad en combate cuerpo a cuerpo tras quedarse sin
munición). Ver `docs/SPEC.md` para el diseño completo del juego y el
contexto histórico.

## Estado actual

La feature `001-soldado-defensor-oleadas` (`specs/001-soldado-defensor-oleadas/`)
está completa: un soldado defensor automático que dispara con fusil mientras
tiene munición y pasa a machete al quedarse sin ella (con daño escalado por
la moral acumulada), una economía de munición (los enemigos derrotados
sueltan munición recolectable, usable para recargar soldados existentes o
desplegar soldados nuevos), y un sistema de oleadas de enemigos crecientes en
dificultad con condiciones de victoria y derrota. Es el primer nivel jugable
de punta a punta del proyecto (`Nivel_MonteCalvo.tscn`).

## Requisitos

- Godot 4.7 (motor MIT, sin regalías).
- El proyecto se abre directamente con `project.godot` en la raíz del repo.

## Documentación del proyecto

| Documento | Contenido |
|---|---|
| `constitution.md` | Principios no negociables (calidad, testing, UX, rendimiento) |
| `docs/SPEC.md` | Diseño del juego: mecánicas, economía, contexto histórico, alcance del MVP |
| `docs/ARCHITECTURE.md` | Convenciones técnicas: estructura de carpetas, nombres, patrones |
| `specs/<feature>/` | Requisitos, plan técnico y tareas de cada feature (Spec Kit) |

## Testing

Los tests automatizados usan **GUT** (Godot Unit Testing), instalado en
`res://addons/gut/` y habilitado en Project Settings → Plugins. Viven en
`res://tests/unit/`, organizados por dominio (`units/`, `enemies/`,
`systems/`, `levels/`) — ver `docs/ARCHITECTURE.md` §6 para la convención
completa y las limitaciones conocidas de correr tests bajo `--headless`.

## Pipeline de desarrollo

Este proyecto usa un pipeline de subagentes especializados de Claude Code
(`dev-godot` → `godot-tester` → `qa-validator` → `docs-writer`, coordinados
por `project-orchestrator`). Ver `CLAUDE.md` para el punto de entrada
(`/implementar-feature <feature-id>`) y el flujo completo.
