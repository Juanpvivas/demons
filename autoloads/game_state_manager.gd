extends Node
## Autoload: único dueño de la condición de victoria/derrota y del estado
## general de la partida (`docs/ARCHITECTURE.md` §4.1). `Soldado`/`Enemigo`/
## `WaveManager` solo reportan hechos vía señal — nunca cambian el estado de
## partida directamente (`contracts/signals.md`, Invariantes de contrato).
##
## T044: `Enemigo.reached_defended_position` es una señal de INSTANCIA — este
## autoload no puede conectarse a ella directamente en `_ready()` porque
## ningún `Enemigo` existe todavía cuando el autoload arranca
## (`docs/ARCHITECTURE.md` §4.2: toda conexión de señal ocurre en `_ready()`
## o en el punto de creación de la instancia dinámica). Se usa el mismo
## patrón ya resuelto para este problema en el codebase:
## `EconomyManager.notify_pickup_spawned()` (`autoloads/economy_manager.gd`)
## — un MÉTODO PÚBLICO que quien detecta el evento llama directamente. Aquí,
## `nivel_monte_calvo.gd._on_posicion_defendida_body_entered()` es quien
## llama a `report_reached_defended_position()` al detectar que un `Enemigo`
## entró en la `Area2D` "PosicionDefendida" (T043).
##
## `WaveManager.all_waves_completed` sí es una señal autoload-a-autoload:
## `WaveManager` ya existe cuando `GameStateManager._ready()` corre (ambos
## registrados en `project.godot`, T010/T040), así que esa conexión sí puede
## hacerse en `_ready()` por `docs/ARCHITECTURE.md` §4.2.
##
## Contrato exacto verificado por `tests/unit/systems/test_game_state_manager.gd`
## (sección T038): una vez que el estado es terminal (`WON`/`LOST`), tanto
## `report_reached_defended_position()` como `_on_all_waves_completed()` no
## hacen nada — ni cambian el estado ni emiten señales (Edge Case
## conservador, no especificado explícitamente en `spec.md`).

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


func _ready() -> void:
	WaveManager.all_waves_completed.connect(_on_all_waves_completed)


## Método público llamado directamente por quien detecta que un `Enemigo`
## alcanzó la posición defendida (`nivel_monte_calvo.gd`, T043/FR-013) — ver
## nota de cabecera sobre por qué no se conecta a la señal de instancia
## `Enemigo.reached_defended_position`. Si el estado actual es `PLAYING`,
## transiciona a `LOST` y emite `game_lost`/`game_state_changed`. Si la
## partida ya terminó (`WON`/`LOST`), no hace nada (Edge Case conservador).
func report_reached_defended_position() -> void:
	if _current_state != GameState.PLAYING:
		return
	_current_state = GameState.LOST
	game_lost.emit()
	game_state_changed.emit(_current_state)


## Handler privado de `WaveManager.all_waves_completed` (conectado en
## `_ready()`, autoload-a-autoload). Si el estado actual es `PLAYING`,
## transiciona a `WON` y emite `game_won`/`game_state_changed`. Si la
## partida ya terminó (`WON`/`LOST`), no hace nada (Edge Case conservador,
## simétrico a `report_reached_defended_position()`).
func _on_all_waves_completed() -> void:
	if _current_state != GameState.PLAYING:
		return
	_current_state = GameState.WON
	game_won.emit()
	game_state_changed.emit(_current_state)
