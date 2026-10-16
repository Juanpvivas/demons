# Memory Index

## Política vigente (2026-10-15)

Lee `AGENTS.md`, `.specify/memory/constitution.md` y
`docs/DEVELOPMENT_WORKFLOW.md` antes de coordinar. Las entradas siguientes
conservan historia; no sustituyen el flujo vigente ni demuestran TDD retroactivo.

- Spec Kit solo prepara especificación, plan y tareas. No cargar ni ejecutar
  `speckit-implement` en ningún rol del pipeline.
- Por comportamiento nuevo o modificado: tester RED → desarrollo → tester
  GREEN/regresión pertinente → QA en solo lectura → documentación.
- El tester es dueño de las pruebas; el desarrollador no escribe ni ejecuta
  tests. Arte/setup/documentación tienen verificación proporcional sin RED
  artificial. QA puede aprobar una tarea de pruebas en RED por su calidad y
  fallo esperado; no equivale a aprobar la implementación ni la feature.
- Solo el orquestador marca `[X]` después del veredicto QA correspondiente.
  Conserva los checkboxes y la evidencia histórica. QA no parchea el checkout.

## Entradas

- [Gap crítico: soldado indestructible bloquea FR-013](project_001_soldado_defeat_gap.md) — RESUELTO (T050-T053 aprobadas); Area2D en CharacterBody2D en movimiento no detecta overlaps contra StaticBody2D, regla ya en ARCHITECTURE.md §4.2
- [No ejecutar implementación con Spec Kit](feedback_no_speckit_implement_directo.md) — política vigente para todos los roles y antecedente de la prohibición
- [Issue #1 = feature 001-soldado-defensor-oleadas](reference_issue_1.md) — reutilizar, no crear uno nuevo
- [Nunca implementar directo, ni con instrucciones ya detalladas](feedback_no_implementar_directo.md) — siempre delegar a dev-godot/etc, aunque "ahorre un paso"
