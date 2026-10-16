@AGENTS.md

# Demonios de las Trincheras — Entrada para Claude

La guía compartida del proyecto se importa arriba desde [AGENTS.md](AGENTS.md).
Sigue esas instrucciones antes de trabajar. Mantén las reglas comunes allí;
este archivo solo contiene la adaptación a Claude.

- Para implementar una feature en Claude Code, usa
  `/implementar-feature <feature-id>` según
  `.claude/commands/implementar-feature.md`. `speckit-implement` solo informa
  del punto de entrada; no implementa ni inicia agentes. Sigue TDD y la
  clasificación de tareas de `docs/DEVELOPMENT_WORKFLOW.md`.
- Si usas Claude Desktop, comprueba que estás en un entorno con acceso real
  al repositorio. Una conversación con archivos adjuntos no confirma ese
  acceso; verifica las modificaciones y pruebas en el directorio de trabajo.
