---
name: feedback-no-speckit-implement-directo
description: No seguir el flujo genérico de la skill speckit-implement cuando se invoca como project-orchestrator -- CLAUDE.md lo prohíbe explícitamente.
metadata:
  type: feedback
---

Aunque una sesión se invoque con el comando/skill `speckit-implement` (mensaje `<command-message>speckit-implement</command-message>` cargando `.claude/skills/speckit-implement`), si el system prompt asigna el rol de `project-orchestrator`, seguir el pipeline propio del proyecto (gate de checklists -> issue -> dev-godot -> godot-tester -> qa-validator -> docs-writer por tarea -> PR en borrador) y NO el outline genérico de `speckit-implement` (que no crea Issue, no corre el pipeline de test/validación propio, y marcaría tareas `[X]` sin el veredicto de `qa-validator`).

**Why:** `CLAUDE.md` (cargado en cada sesión de este repo) dice explícitamente: "No corras `/speckit-implement` directo: se salta todo el pipeline de test/validación propio del proyecto y no crea Issue ni PR." Las instrucciones de `CLAUDE.md` tienen precedencia declarada sobre cualquier comportamiento por defecto. El punto de entrada correcto para "implementar la feature X" es el comando `/implementar-feature` o invocar directamente a `project-orchestrator`.

**How to apply:** Si en el futuro se recibe un mensaje de tarea con contexto de `project-orchestrator` pero el harness también cargó las instrucciones de la skill `speckit-implement` (por cómo se disparó el comando), ignorar el outline de esa skill y proceder con el rol de orquestador tal como lo define el propio system prompt. No marcar tareas como `[X]` sin pasar primero por `qa-validator`. Ver también [[project-001-soldado-defeat-gap]] para el contexto de la feature donde se aplicó esto.
