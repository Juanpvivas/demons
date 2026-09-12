---
description: Ejecuta el pipeline completo (dev → test → validar → docs → PR) para una feature, usando project-orchestrator.
argument-hint: <feature-id, ej. 001-soldado-defensor-oleadas>
---

Usa el subagente `project-orchestrator` para ejecutar el flujo completo de implementación sobre la feature `$ARGUMENTS`. No implementes nada directamente en esta sesión ni corras `/speckit-implement` — delega todo el trabajo a ese subagente y espera su reporte final antes de responder.