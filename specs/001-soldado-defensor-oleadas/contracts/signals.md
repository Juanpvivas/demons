# Contrato de señales: Soldado Defensor con Munición y Moral

Este es el "contrato de interfaz" de esta feature (no hay API HTTP ni CLI —
en un proyecto Godot, la interfaz entre sistemas es el conjunto de señales
que cada nodo emite). Sigue las convenciones de `docs/ARCHITECTURE.md` §4.2
y §3 (nombres en tiempo pasado, `snake_case`). Todo cambio de estado
relevante para el jugador listado aquí existe precisamente porque
`constitution.md` Principio III prohíbe transiciones silenciosas — cada
señal es un punto de enganche obligatorio para HUD/audio/animación.

## `Soldado` (`scenes/units/soldado.gd`)

| Señal | Payload | Cuándo se emite | Quién debe escuchar |
|---|---|---|---|
| `ammo_depleted` | — | Munición llega a 0, justo antes de pasar a modo machete. FR-004. | HUD (icono de estado), `soldado.gd` mismo (transición interna). |
| `mode_changed` | `new_mode: SoldierMode` | Al cambiar entre `RIFLE` y `MELEE` (en cualquier dirección, incluida recarga). | HUD, sistema de animación. |
| `moral_changed` | `new_morale: float` | Cada vez que se acumula moral por eliminación (FR-006). | HUD (barra/indicador de moral). |
| `soldier_defeated` | `grid_cell: Vector2i` | El soldado es derrotado (`spec.md` Edge Case: pierde moral, libera celda). | `BoardManager` (libera la celda), HUD, `GameStateManager` si aplica. |
| `deploy_or_reload_rejected` | `reason: String` | Se intentó recargar/desplegar sin munición recolectada suficiente (FR-011). | HUD (mensaje al jugador). |

## `Enemigo` (`scenes/enemies/enemigo.gd`)

| Señal | Payload | Cuándo se emite | Quién debe escuchar |
|---|---|---|---|
| `enemy_defeated` | `ammo_dropped: int`, `position: Vector2` | Al llegar `_current_health` a 0, por disparo o machete. FR-007. | `EconomyManager` (spawnea pickup / suma al pool — ver `research.md` §3), soldado que dio el golpe final (suma moral, FR-006). |
| `reached_defended_position` | — | El `Enemigo` entra en la `Area2D` de la posición defendida. FR-013. | `GameStateManager` (termina partida en derrota). |

## `EconomyManager` (autoload)

| Señal | Payload | Cuándo se emite | Quién debe escuchar |
|---|---|---|---|
| `ammo_pool_changed` | `new_amount: int` | Cualquier cambio al pool de munición recolectada (recolección, gasto en recarga/despliegue). | HUD (contador global, FR-015). |
| `ammo_pickup_spawned` | `pickup_id`, `position: Vector2`, `amount: int` | Un enemigo derrotado generó una pickup recolectable en el tablero. | Sistema de recolección por tap/click (`research.md` §3). |

## `WaveManager` (autoload)

| Señal | Payload | Cuándo se emite | Quién debe escuchar |
|---|---|---|---|
| `wave_started` | `wave_number: int` | Comienza el spawn de una nueva oleada. | HUD ("oleada por llegar" — Principio III), `ObjectPool` (prepara instancias). |
| `wave_completed` | `wave_number: int` | Todos los enemigos de esa oleada fueron derrotados. | HUD, `WaveManager` mismo (decide si hay siguiente oleada). |
| `all_waves_completed` | — | No quedan más oleadas configuradas para el nivel y todas fueron derrotadas. FR-012/SC-005 contexto. | `GameStateManager` (condición de victoria). |

## `GameStateManager` (autoload)

| Señal | Payload | Cuándo se emite | Quién debe escuchar |
|---|---|---|---|
| `game_won` | — | `WaveManager.all_waves_completed` se recibió y el estado era `PLAYING`. | HUD/UI (pantalla de victoria). |
| `game_lost` | — | Algún `Enemigo.reached_defended_position` se recibió y el estado era `PLAYING`. FR-013. | HUD/UI (pantalla de derrota). |
| `game_state_changed` | `new_state: GameState` | Cualquier transición de `GameState` (`PLAYING`/`PAUSED`/`WON`/`LOST`). | HUD, pausa de `_process`/`_physics_process` de gameplay. |

## Invariantes de contrato

- Ninguna señal de esta tabla se conecta fuera de `_ready()` (o cableado en editor) — `ARCHITECTURE.md` §4.2.
- `EconomyManager.ammo_pool_changed` es la única fuente de verdad para el contador global; ningún nodo debe mantener su propia copia y compararla manualmente.
- `GameStateManager` es el único autoload que decide victoria/derrota — `Soldado`/`Enemigo`/`WaveManager` solo reportan hechos vía señal, nunca cambian el estado de partida directamente.
