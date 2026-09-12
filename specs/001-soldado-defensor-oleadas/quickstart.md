# Quickstart: Validar Soldado Defensor con Munición y Moral

Guía de validación manual end-to-end una vez implementadas las tareas de
esta feature. No reemplaza los tests GUT (`constitution.md` Principio II) —
es el "smoke test" jugable que la misma constitución exige antes de
compartir un build.

## Prerrequisitos

- Godot 4.7 instalado, proyecto abierto (`project.godot` en la raíz del repo).
- Rama `001-soldado-defensor-oleadas` con las tareas de esta feature implementadas.
- `res://scenes/levels/Nivel_MonteCalvo.tscn` como escena principal para correr.

## Escenario 1 — Defensa automática (User Story 1, P1)

1. Ejecutar el nivel (`F6` o el botón de "correr escena actual" en el editor).
2. Desplegar un soldado en una celda vacía.
3. Esperar a que un enemigo entre en su carril frontal.
   - **Esperado**: el soldado dispara automáticamente (feedback visual/sonoro de disparo), sin ninguna acción adicional del jugador.
4. Provocar (o esperar) que un segundo enemigo entre por una diagonal adyacente mientras el primero sigue vivo en el carril frontal.
   - **Esperado**: el soldado sigue disparando solo al objetivo original — no divide fuego (FR-002, Acceptance Scenario 3 de `spec.md`).
5. Dejar que el soldado agote su munición.
   - **Esperado**: transición automática y visible a modo machete (`mode_changed` → HUD refleja el cambio, SC-002/SC-003).
6. Dejar que un enemigo llegue a rango melee.
   - **Esperado**: el soldado ataca con machete; el daño se nota mayor/menor según cuánta moral acumuló disparando (comparar dos corridas: una con muchas bajas antes de quedarse sin munición, otra con pocas).

## Escenario 2 — Recolección y reabastecimiento (User Story 2, P2)

1. Derrotar un enemigo (por disparo o por machete).
   - **Esperado**: aparece una pickup de munición recolectable en su posición (FR-007).
2. Recolectarla (tap/click sobre la pickup — ver `research.md` §3).
   - **Esperado**: el contador global de munición (HUD) sube (FR-015, señal `ammo_pool_changed`).
3. Con un soldado en modo machete (sin munición) en el tablero, usar munición recolectada para recargarlo.
   - **Esperado**: el soldado vuelve a modo fusil (FR-009) **conservando** la moral acumulada previamente (`spec.md` Assumptions — verificar que el daño de machete de una recarga posterior siga reflejando la moral vieja si vuelve a quedarse sin balas).
4. Con munición recolectada suficiente, desplegar un soldado nuevo en una celda vacía.
   - **Esperado**: se descuenta la munición (FR-010), aparece el soldado con munición inicial completa.
5. Intentar recargar o desplegar sin munición recolectada suficiente.
   - **Esperado**: la acción se rechaza y se informa al jugador (FR-011, señal `deploy_or_reload_rejected`) — no pasa nada silenciosamente.

## Escenario 3 — Oleadas crecientes (User Story 3, P3)

1. Completar la oleada 1 (todos sus enemigos derrotados).
   - **Esperado**: señal `wave_completed`, seguida de `wave_started` para la oleada 2, con feedback de "oleada por llegar" (Principio III).
2. Comparar composición/dificultad de la oleada 2 contra la oleada 1.
   - **Esperado**: más enemigos y/o enemigos más fuertes (FR-012, SC-005) — revisar los `WaveData` `.tres` usados.
3. Dejar deliberadamente que un enemigo llegue a la posición defendida.
   - **Esperado**: la partida termina en derrota inmediatamente (FR-013, señal `game_lost`), sin importar cuántos otros enemigos sigan vivos.
4. En una corrida limpia, derrotar todos los enemigos de todas las oleadas configuradas.
   - **Esperado**: condición de victoria (`game_won`) tras `all_waves_completed`.

## Criterio de aceptación del quickstart

Los tres escenarios completos, sin errores en la consola de Godot y sin
comportamiento no descrito arriba, equivalen al "smoke test" manual exigido
por `constitution.md` Principio II antes de compartir un build con testers
externos.
