---
name: feedback-no-implementar-directo
description: Nunca usar Edit/Write/Bash para modificar código de gameplay directamente como project-orchestrator, ni siquiera cuando la dirección de la corrección ya viene dictada explícitamente por la persona.
metadata:
  type: feedback
---

Durante la corrección de T053 en `001-soldado-defensor-oleadas` (2026-09-12), el orquestador empezó a editar `enemigo.gd`/`soldado.gd`/`EnemigoBase.tscn` directamente con la herramienta `Edit`, en vez de delegar a `dev-godot` — a pesar de que el propio system prompt del rol dice explícitamente "No escribes código de gameplay, tests, ni documentación tú mismo". El error ocurrió incluso teniendo instrucciones muy detalladas y ya autorizadas por la persona sobre exactamente qué cambiar, lo cual hizo tentador "ahorrar un paso" e implementar directamente.

**Why:** El pipeline dev-godot → godot-tester → qa-validator existe para mantener una auditoría independiente y trazable de cada cambio, con reportes que se pasan entre agentes. Si el orquestador implementa directamente, rompe esa cadena de trazabilidad (no hay "reporte de dev-godot" real que citarle a `godot-tester`/`qa-validator`) y viola el límite de responsabilidades que la propia persona definió para este rol. Se detectó a tiempo (antes de commitear) gracias a un recordatorio explícito del sistema, se revirtió con `git checkout --` sin pérdida de trabajo, y se re-hizo correctamente delegando a `dev-godot` con el mismo nivel de detalle.

**How to apply:** Sin importar cuán detallada o ya-decidida esté la corrección (incluso si el usuario da instrucciones línea por línea de qué archivo tocar), el orquestador SIEMPRE debe empaquetar esa dirección en un prompt para `dev-godot` (o el subagente que corresponda) y esperar su reporte, nunca tocar código de gameplay/tests/documentación con `Edit`/`Write` él mismo. Las únicas escrituras propias legítimas del orquestador son: `tasks.md` (marcar `[X]`), archivos de memoria persistente, y el cuerpo de Issues/PRs. Ver también [[project-001-soldado-defeat-gap]] para el caso concreto donde ocurrió esto.
