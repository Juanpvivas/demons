---
name: feedback-no-implementar-directo
description: Nunca usar Edit/Write/Bash para modificar código de gameplay directamente como project-orchestrator, ni siquiera cuando la dirección de la corrección ya viene dictada explícitamente por la persona.
metadata:
  type: feedback
---

## Política vigente (2026-10-15)

Lee `AGENTS.md`, `.specify/memory/constitution.md` y
`docs/DEVELOPMENT_WORKFLOW.md`. El orquestador sigue sin implementar ni
ejecutar pruebas. El orden vigente por comportamiento es **tester RED →
desarrollo → tester GREEN/regresión → QA en solo lectura → documentación**.
El tester es dueño de pruebas; el dev no las escribe ni las corre; solo el
orquestador marca `[X]` tras el veredicto QA, distinguiendo prueba RED aprobada
de implementación GREEN aprobada. Arte/setup/documentación usan su validación
propia sin RED artificial.

El relato siguiente conserva un error y su corrección en el flujo anterior.
No modifica checkboxes históricos ni acredita TDD retroactivo. La orden de
delegar corresponde al rol `project-orchestrator`; una corrección documental
puntual expresamente autorizada conserva el alcance definido por `AGENTS.md`.

## Contexto histórico (2026-09-12)

Durante la corrección de T053 en `001-soldado-defensor-oleadas` (2026-09-12), el orquestador empezó a editar `enemigo.gd`/`soldado.gd`/`EnemigoBase.tscn` directamente con la herramienta `Edit`, en vez de delegar a `dev-godot` — a pesar de que el propio system prompt del rol dice explícitamente "No escribes código de gameplay, tests, ni documentación tú mismo". El error ocurrió incluso teniendo instrucciones muy detalladas y ya autorizadas por la persona sobre exactamente qué cambiar, lo cual hizo tentador "ahorrar un paso" e implementar directamente.

**Why:** El pipeline dev-godot → godot-tester → qa-validator existe para mantener una auditoría independiente y trazable de cada cambio, con reportes que se pasan entre agentes. Si el orquestador implementa directamente, rompe esa cadena de trazabilidad (no hay "reporte de dev-godot" real que citarle a `godot-tester`/`qa-validator`) y viola el límite de responsabilidades que la propia persona definió para este rol. Se detectó a tiempo (antes de commitear) gracias a un recordatorio explícito del sistema, se revirtió con `git checkout --` sin pérdida de trabajo, y se re-hizo correctamente delegando a `dev-godot` con el mismo nivel de detalle.

**Cómo se aplica hoy:** El orquestador empaqueta la dirección en un prompt para
el rol responsable y espera su reporte, respetando la etapa RED/GREEN que
corresponda. No edita gameplay, tests ni documentación de tareas. Sus escrituras
propias se limitan al seguimiento autorizado de `tasks.md`, memoria e Issues/PRs;
solo él marca `[X]` tras QA. No convierte trabajo adicional en tareas nuevas sin
aprobación de la persona. Ver [caso histórico](project_001_soldado_defeat_gap.md).
