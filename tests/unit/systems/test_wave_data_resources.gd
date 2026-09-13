extends GutTest
## T041: verificación de los 10 `WaveData` autorados en `resources/waves/`
## (`nivel_montecalvo_oleada_01.tres` .. `_10.tres`) — cubre SC-005 de
## `spec.md` ("Cada oleada sucesiva presenta un incremento medible en
## dificultad... perceptible a lo largo de al menos 10 oleadas consecutivas")
## y el requisito de `research.md` §4 de que las oleadas sean datos autorados
## (`.tres`), no generados por fórmula en código.
##
## Estos son recursos estáticos (no hay lógica nueva que testear más allá de
## `WaveData`/`WaveSpawnEntry`, ya cubiertos por `test_resource_schemas.gd`),
## pero se testean igual para que la progresión de dificultad quede protegida
## por la suite automática en vez de depender de una verificación manual: un
## futuro ajuste de balance que rompa el orden o la progresión debe fallar
## aquí, no descubrirse jugando.
##
## (T047: la observación de qa-validator en T041 sobre `wave_number`/`count`/
## `spawn_interval` implícitos en `_01`, `_03` y `_06` quedó resuelta — los
## tres `.tres` fijan ahora el valor explícitamente, sin depender de
## defaults del schema.)

const WAVE_COUNT := 10
const WAVE_PATH_FORMAT := "res://resources/waves/nivel_montecalvo_oleada_%02d.tres"


func _wave_path(n: int) -> String:
	return WAVE_PATH_FORMAT % n


func _load_wave(n: int) -> WaveData:
	return load(_wave_path(n))


func _total_enemy_count(wave: WaveData) -> int:
	var total := 0
	for entry in wave.spawn_entries:
		total += entry.count
	return total


## Intervalo de spawn "representativo" de la oleada: el mínimo entre sus
## entradas (la cadencia más agresiva presente), suficiente para comparar
## dificultad entre oleadas con una sola entrada de spawn cada una (caso
## actual del MVP, un único tipo de enemigo).
func _min_spawn_interval(wave: WaveData) -> float:
	var min_interval: float = INF
	for entry in wave.spawn_entries:
		min_interval = min(min_interval, entry.spawn_interval)
	return min_interval


## --- Existencia y carga de los 10 archivos ---

func test_ten_wave_resource_files_exist_on_disk() -> void:
	for n in range(1, WAVE_COUNT + 1):
		assert_true(
			FileAccess.file_exists(_wave_path(n)),
			"debe existir %s (T041 exige de 3 a 10 oleadas; el nivel usa 10)" % _wave_path(n)
		)


func test_each_wave_resource_loads_without_error_as_wave_data() -> void:
	for n in range(1, WAVE_COUNT + 1):
		var wave := _load_wave(n)
		assert_not_null(
			wave, "%s debe cargar sin error de parseo/referencia rota" % _wave_path(n)
		)
		assert_true(
			wave is WaveData,
			"%s debe instanciar como WaveData (script_class correcto)" % _wave_path(n)
		)


## --- wave_number en orden 1..10 ---

func test_wave_number_matches_file_order_for_each_wave() -> void:
	for n in range(1, WAVE_COUNT + 1):
		var wave := _load_wave(n)
		assert_eq(
			wave.wave_number, n,
			"%s debe reportar wave_number = %d" % [_wave_path(n), n]
		)


## --- spawn_entries no vacío y referencia válida a EnemyStats ---

func test_each_wave_has_at_least_one_spawn_entry() -> void:
	for n in range(1, WAVE_COUNT + 1):
		var wave := _load_wave(n)
		assert_gt(
			wave.spawn_entries.size(), 0,
			"%s no debe tener spawn_entries vacío" % _wave_path(n)
		)


func test_each_spawn_entry_references_a_valid_enemy_stats_resource() -> void:
	for n in range(1, WAVE_COUNT + 1):
		var wave := _load_wave(n)
		for entry in wave.spawn_entries:
			assert_not_null(
				entry.enemy_stats,
				"cada WaveSpawnEntry de %s debe referenciar un EnemyStats" % _wave_path(n)
			)
			assert_true(
				entry.enemy_stats is EnemyStats,
				"enemy_stats de %s debe ser una instancia de EnemyStats" % _wave_path(n)
			)
			assert_gt(
				entry.enemy_stats.max_health, 0,
				"el EnemyStats referenciado por %s debe tener max_health > 0" % _wave_path(n)
			)
			assert_gt(
				entry.count, 0,
				"count de cada WaveSpawnEntry en %s debe ser > 0" % _wave_path(n)
			)
			assert_gt(
				entry.spawn_interval, 0.0,
				"spawn_interval de cada WaveSpawnEntry en %s debe ser > 0" % _wave_path(n)
			)


## --- Progresión de dificultad creciente (SC-005) ---

func test_total_enemy_count_increases_on_every_successive_wave() -> void:
	# SC-005: "Cada oleada sucesiva presenta un incremento medible en
	# dificultad (cantidad...) respecto a la anterior" — se exige estricto,
	# no solo no-decreciente, para que la progresión sea perceptible oleada a
	# oleada y no solo en la tendencia general.
	var previous_total := -1
	for n in range(1, WAVE_COUNT + 1):
		var wave := _load_wave(n)
		var total := _total_enemy_count(wave)
		if n > 1:
			assert_gt(
				total, previous_total,
				"oleada %d (%d enemigos) debe tener más enemigos que la oleada %d (%d enemigos)"
					% [n, total, n - 1, previous_total]
			)
		previous_total = total


func test_spawn_interval_decreases_or_holds_on_every_successive_wave() -> void:
	# Cadencia de spawn más rápida (o igual) en cada oleada sucesiva: un
	# intervalo menor añade dificultad incluso a igual cantidad total.
	var previous_interval := INF
	for n in range(1, WAVE_COUNT + 1):
		var wave := _load_wave(n)
		var interval := _min_spawn_interval(wave)
		if n > 1:
			assert_lte(
				interval, previous_interval,
				"oleada %d (intervalo %.2fs) no debe tener spawns más lentos que la oleada %d (%.2fs)"
					% [n, interval, n - 1, previous_interval]
			)
		previous_interval = interval


func test_final_wave_is_measurably_harder_than_first_wave() -> void:
	# Chequeo extremo a extremo de SC-005 ("perceptible a lo largo de al
	# menos 10 oleadas consecutivas"): la última oleada debe ser claramente
	# más difícil que la primera, tanto en cantidad como en cadencia.
	var first_wave := _load_wave(1)
	var last_wave := _load_wave(WAVE_COUNT)

	assert_gt(
		_total_enemy_count(last_wave), _total_enemy_count(first_wave),
		"la oleada final debe tener más enemigos en total que la primera oleada"
	)
	assert_lt(
		_min_spawn_interval(last_wave), _min_spawn_interval(first_wave),
		"la oleada final debe spawnear más rápido que la primera oleada"
	)
