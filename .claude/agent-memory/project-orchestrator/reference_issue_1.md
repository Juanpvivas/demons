---
name: reference-issue-1
description: Issue de GitHub #1 es el issue de trazabilidad para la feature 001-soldado-defensor-oleadas.
metadata:
  type: reference
---

El Issue #1 en el repo de GitHub corresponde a la feature
`001-soldado-defensor-oleadas`. Si un trabajo autorizado de esa feature requiere
un PR, su vínculo de trazabilidad es `Closes #1`. No crear un segundo Issue:
reutiliza el #1, abierto o cerrado. Comprueba el estado actual y los enlaces;
esta memoria no significa que exista un PR pendiente ni ordena reabrir trabajo
completado.

Para buscar otros Issues, usa `gh issue list --state all --search "<feature-id> in:title"`
o un equivalente que incluya cerrados. Lee `AGENTS.md`,
`.specify/memory/constitution.md` y `docs/DEVELOPMENT_WORKFLOW.md` antes de
coordinar. Conserva los checkboxes y la evidencia histórica; no atribuyas TDD
retroactivo al trabajo anterior.
