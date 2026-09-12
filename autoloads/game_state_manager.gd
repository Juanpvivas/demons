extends Node
## Autoload: único dueño de la condición de victoria/derrota y del estado
## general de la partida (`docs/ARCHITECTURE.md` §4.1). `Soldado`/`Enemigo`/
## `WaveManager` solo reportan hechos vía señal — nunca cambian el estado de
## partida directamente (`contracts/signals.md`, Invariantes de contrato).
##
## T009 (Foundational): solo la estructura base. La lógica de escuchar
## `Enemigo.reached_defended_position` y `WaveManager.all_waves_completed`
## para disparar `game_lost`/`game_won` se agrega en T044 — no implementada
## todavía.

## Estados posibles de la partida.
enum GameState { PLAYING, PAUSED, WON, LOST }

## Estado actual de la partida. Arranca en `PLAYING`.
var _current_state: GameState = GameState.PLAYING

## Emitida cuando `WaveManager.all_waves_completed` se recibe y el estado
## era `PLAYING`. Escucha: HUD/UI (pantalla de victoria).
signal game_won

## Emitida cuando algún `Enemigo.reached_defended_position` se recibe y el
## estado era `PLAYING` (FR-013). Escucha: HUD/UI (pantalla de derrota).
signal game_lost

## Emitida ante cualquier transición de `GameState`. Escucha: HUD, pausa
## de `_process`/`_physics_process` de gameplay.
signal game_state_changed(new_state: GameState)
