# Research — 011

- Fuente: perfil confirmado por la persona el 2026-10-24; base `main` 74d1a3a tras PR #41. No quedan decisiones UX críticas abiertas.
- Elegir ProgressBar compartida: ya ofrece valor/máximo/visibilidad observables y estilo mate mediante StyleBoxFlat; evita dibujado/API de prueba adicionales.
- Salud existente: `_current_health` en cada actor; `UnitStats.max_health` y `EnemyStats.max_health` aportan el máximo. No migrar datos ni crear stats.
- Llamadas directas desde puntos de cambio existentes; no polling, bus global, HealthComponent ni tween: el perfil exige descenso inmediato.
- El hijo del root sigue al cuerpo; separarlo del sprite evita cambios de color/inversión y no exige CanvasLayer ni conversión de coordenadas.
- Riesgo principal: pool prewarm antes de ready y derrota con reuso síncrono; limpiar antes de señales y restaurar desde prepare.
- Referencias aplicadas a diseño: GodotPrompter `using-godot-prompter`, `hud-system` y `godot-ui`; prevalecen contrato local y alcance confirmado.
- La preparación no ejecuta pruebas ni acredita QA; rendimiento #30 y publicación siguen pendientes.
