---
name: feedback-no-speckit-implement-directo
description: Spec Kit solo prepara documentos; ningún rol ejecuta ni precarga speckit-implement. Conserva el antecedente de la prohibición como contexto histórico.
metadata:
  type: feedback
---

## Política vigente (2026-10-15)

Lee `AGENTS.md`, `.specify/memory/constitution.md` y
`docs/DEVELOPMENT_WORKFLOW.md`. Spec Kit solo prepara especificación, plan y
tareas; ningún rol del pipeline debe cargar ni ejecutar `speckit-implement`.
Se eliminó su precarga de `dev-godot` y `project-orchestrator` para evitar
instrucciones opuestas sobre pruebas, alcance y marcado de tareas.

La implementación usa agentes y clasifica las tareas. Por comportamiento nuevo
o modificado: `godot-tester` demuestra RED, `dev-godot` implementa, el tester
verifica GREEN/regresión, QA emite un veredicto en solo lectura y se documenta
el alcance aprobado. Solo el orquestador marca `[X]` tras QA. Una prueba
aprobada en RED no significa funcionalidad entregada. Arte/setup/documentación
sin cambio de lógica no necesitan RED artificial. Conserva los `[X]` antiguos
y no inventes evidencia RED/GREEN retroactiva.

Si un harness carga por error la skill de implementación, no sigas su ejecución
genérica: informa el conflicto y usa las instrucciones vigentes del pipeline.
En Claude, el punto de entrada continúa siendo `/implementar-feature`; en
otras herramientas se reproducen los roles conforme a `AGENTS.md`.

## Contexto histórico (2026-09-12)

El siguiente registro explica por qué se restringió inicialmente el comando.
El antiguo orden dev → test era el vigente entonces; no prescribe el orden
TDD actual ni es evidencia de que la feature histórica lo haya seguido.

Aunque una sesión se invocara con el comando/skill `speckit-implement`, si se
asignaba el rol de `project-orchestrator` debía seguir el pipeline propio
(checklists → Issue → dev → test → QA → docs → PR en borrador), en lugar del
outline genérico, que no creaba Issue ni ejecutaba la validación independiente.

**Why histórico:** El antiguo `CLAUDE.md` decía: "No corras
`/speckit-implement` directo: se salta todo el pipeline de test/validación
propio del proyecto y no crea Issue ni PR." Esa regla ahora está en la guía
compartida, sin depender de un proveedor.

El registro antiguo ordenaba ignorar el outline genérico en ese caso. La
política vigente anterior reemplaza esa excepción limitada al orquestador.
Ver [gap histórico de derrota](project_001_soldado_defeat_gap.md).
