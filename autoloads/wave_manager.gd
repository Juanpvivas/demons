extends Node
## Autoload: controla la secuencia de oleadas del nivel activo
## (`data-model.md` — "Oleada"; `docs/ARCHITECTURE.md` §4.1). Consume la
## secuencia autorada de `WaveData` fijada por `start_waves()` y decide,
## a partir de las notificaciones de `notify_enemy_defeated()`, cuándo una
## oleada se completa y cuándo arranca la siguiente (o se declara victoria).
##
## `WaveManager` NO instancia enemigos ni corre ningún `Timer`/cola de
## `spawn_interval` — esa temporización concreta es responsabilidad de
## `WaveSpawner` en el nivel (T042, `nivel_monte_calvo.gd`), que sí escucha
## `Enemigo.enemy_defeated` (T026) y llama a `notify_enemy_defeated()` una
## vez por cada enemigo derrotado perteneciente a la oleada activa.
## `WaveManager` solo necesita saber cuántos enemigos totales componen la
## oleada activa (suma de `count` de cada `WaveSpawnEntry` en
## `spawn_entries`) y cuántos de esos fueron derrotados.
##
## Sin `class_name`: se referencia por su nombre de singleton de autoload
## (`ARCHITECTURE.md` §4.1) — no registrado todavía en `project.godot`
## (eso es T040, tarea separada).

## Secuencia de oleadas consumida, fijada por `start_waves()`.
var waves: Array[WaveData] = []

## Índice dentro de `waves` de la oleada activa. `-1` antes de arrancar la
## secuencia (`start_waves()` no llamado todavía) o tras completarla
## (`all_waves_completed` ya emitido).
var current_wave_index: int = -1

## Total de enemigos que componen la oleada actualmente activa (suma de
## `count` de todas sus `spawn_entries`), calculado una vez al iniciar esa
## oleada para no recalcularlo en cada `notify_enemy_defeated()`.
var _total_enemies_in_current_wave: int = 0

## Cuántos de esos enemigos fueron derrotados hasta ahora en la oleada
## activa.
var _defeated_in_current_wave: int = 0

## Emitida al comenzar el spawn de una nueva oleada. Escucha: HUD ("oleada
## por llegar"), `ObjectPool` (prepara instancias).
signal wave_started(wave_number: int)

## Emitida cuando todos los enemigos de una oleada fueron derrotados.
## Escucha: HUD, `WaveManager` mismo (decide si hay siguiente oleada).
signal wave_completed(wave_number: int)

## Emitida cuando no quedan más oleadas configuradas para el nivel y todas
## fueron derrotadas (FR-012/SC-005). Escucha: `GameStateManager`
## (condición de victoria).
signal all_waves_completed()


## Fija la secuencia de oleadas a consumir y arranca la primera. Si
## `new_waves` está vacío (nivel sin oleadas configuradas), no hay ninguna
## oleada que iniciar: se emite `all_waves_completed()` directamente, sin
## ningún `wave_started`, para no dejar la partida colgada esperando una
## oleada que nunca llega.
func start_waves(new_waves: Array[WaveData]) -> void:
	waves = new_waves

	if waves.is_empty():
		current_wave_index = -1
		all_waves_completed.emit()
		return

	current_wave_index = 0
	_start_current_wave()


## Notifica que un enemigo perteneciente a la oleada activa fue derrotado.
## No-op defensivo si no hay ninguna oleada activa (antes de `start_waves()`
## o tras `all_waves_completed()`) o si se recibe más allá del total de la
## oleada activa (ej. doble disparo de señal) — no debe re-emitir
## `wave_completed`/`all_waves_completed` ni causar error.
func notify_enemy_defeated() -> void:
	if not _has_active_wave():
		return

	_defeated_in_current_wave += 1
	if _defeated_in_current_wave < _total_enemies_in_current_wave:
		return

	var finished_wave: WaveData = waves[current_wave_index]
	wave_completed.emit(finished_wave.wave_number)

	if current_wave_index + 1 < waves.size():
		current_wave_index += 1
		_start_current_wave()
	else:
		current_wave_index = -1
		all_waves_completed.emit()


## Retorna el `WaveData` activo, o `null` si no hay ninguna oleada en curso
## (antes de `start_waves()` o tras `all_waves_completed()`).
func get_current_wave() -> WaveData:
	if not _has_active_wave():
		return null
	return waves[current_wave_index]


## Inicializa los contadores de la oleada en `current_wave_index` y emite
## su `wave_started` con el `wave_number` literal autorado en el `.tres`
## (nunca un índice recalculado, para que el HUD coincida siempre con lo
## que diseño fijó).
func _start_current_wave() -> void:
	_defeated_in_current_wave = 0
	_total_enemies_in_current_wave = _count_enemies_in_wave(waves[current_wave_index])
	wave_started.emit(waves[current_wave_index].wave_number)


## Suma `count` de cada `WaveSpawnEntry` de `wave.spawn_entries` — total de
## enemigos que componen esa oleada, sin depender de temporización de spawn.
func _count_enemies_in_wave(wave: WaveData) -> int:
	var total := 0
	for entry: WaveSpawnEntry in wave.spawn_entries:
		total += entry.count
	return total


## `true` si `current_wave_index` apunta a una oleada válida dentro de
## `waves` (secuencia arrancada y todavía no completada por completo).
func _has_active_wave() -> bool:
	return current_wave_index >= 0 and current_wave_index < waves.size()
