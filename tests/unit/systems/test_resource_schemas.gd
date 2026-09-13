extends GutTest
## T004/T005/T006/T007: verificación mínima pero real de los Resource schemas
## fundacionales (`resources/schemas/`) — no hay tarea de test GUT dedicada
## explícita en tasks.md para estos schemas (los tests de comportamiento
## que los consumen llegan en T015/T016), pero dependen de que
## Godot realmente reconozca `class_name UnitStats`/`EnemyStats`/
## `WaveSpawnEntry`/`WaveData` como tipos globales instanciables con los
## campos y tipos correctos. Este test valida esa base.


## --- UnitStats (T004) ---

func test_unit_stats_class_name_is_globally_registered() -> void:
	assert_true(
		ClassDB.class_exists("Resource"),
		"sanity: Resource debe existir en ClassDB"
	)
	var script := load("res://resources/schemas/unit_stats.gd")
	assert_not_null(script, "el script unit_stats.gd debe cargar sin error")
	assert_eq(
		script.get_instance_base_type(), "Resource",
		"UnitStats debe extender Resource"
	)


func test_unit_stats_instantiates_via_global_class_name() -> void:
	var stats := UnitStats.new()
	assert_not_null(stats, "UnitStats.new() debe instanciar vía class_name global")
	assert_true(stats is Resource, "una instancia de UnitStats debe ser un Resource")


func test_unit_stats_has_expected_fields_with_correct_types_and_defaults() -> void:
	var stats := UnitStats.new()
	assert_typeof(stats.max_ammo, TYPE_INT, "max_ammo debe ser int")
	assert_typeof(stats.damage_per_shot, TYPE_INT, "damage_per_shot debe ser int")
	assert_typeof(stats.fire_rate, TYPE_FLOAT, "fire_rate debe ser float")
	assert_typeof(stats.machete_base_damage, TYPE_INT, "machete_base_damage debe ser int")
	assert_typeof(stats.machete_moral_multiplier, TYPE_FLOAT, "machete_moral_multiplier debe ser float")
	assert_typeof(stats.moral_per_kill, TYPE_FLOAT, "moral_per_kill debe ser float")
	assert_typeof(stats.deploy_ammo_cost, TYPE_INT, "deploy_ammo_cost debe ser int")

	assert_gt(stats.max_ammo, 0, "max_ammo por defecto debe ser > 0")
	assert_gt(stats.damage_per_shot, 0, "damage_per_shot por defecto debe ser > 0")
	assert_gt(stats.deploy_ammo_cost, 0, "deploy_ammo_cost por defecto debe ser > 0")


func test_unit_stats_machete_base_damage_minimum_is_greater_than_zero() -> void:
	# Edge case de spec.md: daño de machete base > 0 incluso con moral cero.
	# El @export_range de machete_base_damage debe tener mínimo 1, no 0,
	# para que este invariante no pueda romperse ni siquiera por autoría de datos.
	var stats := UnitStats.new()
	var found_range := false
	for prop in stats.get_property_list():
		if prop.get("name") == "machete_base_damage":
			found_range = true
			var hint_string: String = prop.get("hint_string", "")
			var min_value := float(hint_string.split(",")[0]) if hint_string != "" else -1.0
			assert_gte(
				min_value, 1.0,
				"machete_base_damage debe tener un mínimo exportado >= 1 (edge case moral=0)"
			)
	assert_true(found_range, "machete_base_damage debe existir en la lista de propiedades exportadas")
	assert_gt(
		stats.machete_base_damage, 0,
		"el valor por defecto de machete_base_damage debe ser > 0"
	)


## --- EnemyStats (T005) ---

func test_enemy_stats_instantiates_via_global_class_name() -> void:
	var stats := EnemyStats.new()
	assert_not_null(stats, "EnemyStats.new() debe instanciar vía class_name global")
	assert_true(stats is Resource, "una instancia de EnemyStats debe ser un Resource")


func test_enemy_stats_has_expected_fields_with_correct_types_and_defaults() -> void:
	var stats := EnemyStats.new()
	assert_typeof(stats.max_health, TYPE_INT, "max_health debe ser int")
	assert_typeof(stats.move_speed, TYPE_FLOAT, "move_speed debe ser float")
	assert_typeof(stats.melee_damage, TYPE_INT, "melee_damage debe ser int")
	assert_typeof(stats.ammo_drop, TYPE_INT, "ammo_drop debe ser int")

	assert_gt(stats.max_health, 0, "max_health por defecto debe ser > 0")
	assert_gt(stats.move_speed, 0.0, "move_speed por defecto debe ser > 0")
	assert_gte(stats.ammo_drop, 0, "ammo_drop por defecto debe ser >= 0")


## --- WaveSpawnEntry (T006) ---

func test_wave_spawn_entry_instantiates_via_global_class_name() -> void:
	var entry := WaveSpawnEntry.new()
	assert_not_null(entry, "WaveSpawnEntry.new() debe instanciar vía class_name global")
	assert_true(entry is Resource, "una instancia de WaveSpawnEntry debe ser un Resource")


func test_wave_spawn_entry_has_expected_fields_with_correct_types() -> void:
	var entry := WaveSpawnEntry.new()
	assert_typeof(entry.count, TYPE_INT, "count debe ser int")
	assert_typeof(entry.spawn_interval, TYPE_FLOAT, "spawn_interval debe ser float")
	assert_gt(entry.count, 0, "count por defecto debe ser > 0")
	assert_gt(entry.spawn_interval, 0.0, "spawn_interval por defecto debe ser > 0")

	# enemy_stats es nullable por defecto (sin asignar) pero debe aceptar
	# una instancia de EnemyStats sin error de tipo.
	assert_null(entry.enemy_stats, "enemy_stats no debe tener un valor por defecto asignado")
	var enemy := EnemyStats.new()
	entry.enemy_stats = enemy
	assert_eq(
		entry.enemy_stats, enemy,
		"enemy_stats debe aceptar y conservar una referencia a EnemyStats"
	)


func test_wave_spawn_entry_enemy_stats_field_is_statically_typed_as_enemy_stats() -> void:
	# Verifica que el tipado @export enemy_stats: EnemyStats es real (no un
	# Resource genérico): GDScript debe reportar el tipo de la propiedad
	# como la clase EnemyStats en su hint, no como "Resource" a secas.
	# (Confirmado también de forma indirecta: intentar asignar en tiempo de
	# análisis un UnitStats a este campo produce un Parse Error de GDScript
	# por incompatibilidad de tipos — el tipado está activo.)
	var entry := WaveSpawnEntry.new()
	var found_property := false
	for prop in entry.get_property_list():
		if prop.get("name") == "enemy_stats":
			found_property = true
			assert_string_contains(
				String(prop.get("hint_string", "")), "EnemyStats",
				"enemy_stats debe declarar EnemyStats como su tipo exportado"
			)
	assert_true(found_property, "enemy_stats debe existir en la lista de propiedades exportadas")


## --- WaveData (T007) ---

func test_wave_data_instantiates_via_global_class_name() -> void:
	var wave := WaveData.new()
	assert_not_null(wave, "WaveData.new() debe instanciar vía class_name global")
	assert_true(wave is Resource, "una instancia de WaveData debe ser un Resource")


func test_wave_data_has_expected_fields_with_correct_types_and_default() -> void:
	var wave := WaveData.new()
	assert_typeof(wave.wave_number, TYPE_INT, "wave_number debe ser int")
	assert_typeof(wave.spawn_entries, TYPE_ARRAY, "spawn_entries debe ser un Array")
	assert_gt(wave.wave_number, 0, "wave_number por defecto debe ser > 0 (orden 1-based)")
	assert_eq(
		wave.spawn_entries.size(), 0,
		"spawn_entries debe iniciar vacío por defecto (composición se autora en el .tres)"
	)


func test_wave_data_spawn_entries_is_statically_typed_as_wave_spawn_entry_array() -> void:
	# Verifica que spawn_entries es realmente Array[WaveSpawnEntry] (tipado),
	# no un Array genérico: el motor debe reportar TYPE_ARRAY con un hint de
	# subtipo que referencia la clase WaveSpawnEntry.
	var wave := WaveData.new()
	var found_property := false
	for prop in wave.get_property_list():
		if prop.get("name") == "spawn_entries":
			found_property = true
			assert_eq(
				int(prop.get("type", -1)), TYPE_ARRAY,
				"spawn_entries debe reportar TYPE_ARRAY en su property list"
			)
			assert_string_contains(
				String(prop.get("hint_string", "")), "WaveSpawnEntry",
				"spawn_entries debe declarar WaveSpawnEntry como subtipo del array exportado"
			)
	assert_true(found_property, "spawn_entries debe existir en la lista de propiedades exportadas")


func test_wave_data_spawn_entries_accepts_and_stores_wave_spawn_entry_instances() -> void:
	# Comportamiento real: la composición de una oleada se arma agregando
	# WaveSpawnEntry al array (ver data-model.md "Relaciones":
	# WaveData (1) --> (N) WaveSpawnEntry).
	var wave := WaveData.new()
	var entry_a := WaveSpawnEntry.new()
	entry_a.count = 3
	var entry_b := WaveSpawnEntry.new()
	entry_b.count = 7

	wave.spawn_entries.append(entry_a)
	wave.spawn_entries.append(entry_b)

	assert_eq(wave.spawn_entries.size(), 2, "spawn_entries debe conservar las entradas agregadas")
	assert_eq(wave.spawn_entries[0], entry_a, "el orden de las entradas debe preservarse")
	assert_eq(wave.spawn_entries[1].count, 7, "cada entrada debe conservar sus propios datos")


func test_wave_data_spawn_entries_is_typed_array_enforced_at_runtime_not_generic() -> void:
	# Edge case de tipado: al ser Array[WaveSpawnEntry] (no Array genérico),
	# el motor debe reportar el array como tipado en tiempo de ejecución
	# (is_typed) y con el script de WaveSpawnEntry como su tipo de elemento
	# — así se garantiza que WaveManager/WaveSpawner reciban únicamente
	# WaveSpawnEntry reales al iterar spawn_entries, con el tipo rechazado
	# por el motor si se intentara insertar otra cosa (ver `get_typed_script`).
	var wave := WaveData.new()
	var raw_array: Array = wave.spawn_entries
	var wave_spawn_entry_script := load("res://resources/schemas/wave_spawn_entry.gd")

	assert_true(
		raw_array.is_typed(),
		"spawn_entries debe reportarse como Array tipado (is_typed) en tiempo de ejecución"
	)
	assert_eq(
		raw_array.get_typed_script(), wave_spawn_entry_script,
		"el tipo de elemento del array debe ser específicamente el script de WaveSpawnEntry"
	)
