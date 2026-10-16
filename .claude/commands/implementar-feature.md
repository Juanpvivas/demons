---
description: Implementa una feature preparada con Spec Kit mediante agentes, con RED → desarrollo → GREEN/regresión → QA → documentación → PR en borrador.
argument-hint: <feature-id, ej. 001-soldado-defensor-oleadas>
---

Lee `AGENTS.md`, `.specify/memory/constitution.md` y
`docs/DEVELOPMENT_WORKFLOW.md`. Usa `project-orchestrator` para implementar la
feature `$ARGUMENTS`, proporcionándole las instrucciones compartidas y su rol.

Spec Kit solo prepara la especificación, el plan y las tareas. No cargues ni
ejecutes `/speckit-implement`. El orquestador clasifica las tareas y delega por
comportamiento: `godot-tester` demuestra RED, `dev-godot` implementa,
`godot-tester` verifica GREEN y regresión pertinente, `qa-validator` emite un
veredicto en solo lectura y `docs-writer` documenta el alcance aprobado. Arte,
setup y documentación usan verificaciones adecuadas sin RED artificial.

Solo el orquestador marca `[X]` tras QA. Aprobar una tarea de pruebas en RED no
significa que el comportamiento esté entregado. Conserva el historial y la
evidencia existentes, sin inventar TDD retroactivo. El Issue, la rama y el PR en
borrador siguen el procedimiento del orquestador; no se fusiona ni se promueve
el PR automáticamente.

No implementes directamente en esta sesión. Delega y espera el reporte final
del orquestador; si falta una capacidad necesaria, informa la limitación.
