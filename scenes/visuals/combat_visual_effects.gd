## Servicio del nivel: observa hechos de combate y recicla imágenes, nunca actores.
class_name CombatVisualEffects
extends Node

const _EFFECT_SCENE: PackedScene = preload("res://scenes/visuals/DeathVisualEffect.tscn")
const _RIFLE_SCENE: PackedScene = preload("res://scenes/visuals/RifleShotVisualEffect.tscn")

var _pool: ObjectPool
var _rifle_pool: ObjectPool
var _active_rifle_effects: Array[RifleShotVisualEffect] = []
var _closed: bool = false
var _enemy_shooters: Dictionary[int, Dictionary] = {}


func setup(initial_size: int = 10) -> void:
	assert(_pool == null, "CombatVisualEffects.setup solo admite una preparación")
	_pool = ObjectPool.new()
	add_child(_pool)
	_pool.instance_created.connect(_on_effect_created)
	_pool.setup(_EFFECT_SCENE, initial_size)
	_rifle_pool = ObjectPool.new()
	add_child(_rifle_pool)
	_rifle_pool.instance_created.connect(_on_rifle_effect_created)
	_rifle_pool.setup(_RIFLE_SCENE, initial_size)
	GameStateManager.game_state_changed.connect(_on_game_state_changed)


func register_actor(actor: Node) -> void:
	if _closed:
		return
	if actor.has_signal("defeat_visual_requested") \
			and not actor.is_connected("defeat_visual_requested", request_defeat):
		actor.connect("defeat_visual_requested", request_defeat)
	if actor is Enemigo:
		var id := actor.get_instance_id()
		if not _enemy_shooters.has(id):
			var callback := _on_enemy_rifle_shot.bind(weakref(actor))
			_enemy_shooters[id] = {"actor": weakref(actor), "callback": callback, "snapshot": null}
			actor.connect(&"rifle_shot_visual_requested", callback)
			actor.tree_exiting.connect(_on_enemy_leaving.bind(id))
	elif actor.has_signal("rifle_shot_visual_requested") \
			and not actor.is_connected("rifle_shot_visual_requested", request_rifle_shot):
		actor.connect("rifle_shot_visual_requested", request_rifle_shot)


func _on_enemy_rifle_shot(snapshot: Dictionary, reference: WeakRef) -> void:
	var enemy := reference.get_ref() as Enemigo
	if _closed or not is_instance_valid(enemy) or not enemy.is_targetable() \
			or snapshot.size() != 3 or not snapshot.get("activation_generation") is int \
			or snapshot.activation_generation != enemy.activation_generation:
		return
	var id := enemy.get_instance_id()
	if not _enemy_shooters.has(id) or is_same(_enemy_shooters[id].snapshot, snapshot):
		return
	_enemy_shooters[id].snapshot = snapshot
	# La generación sólo valida admisión. El efecto conserva dos datos sin dueño.
	request_rifle_shot({"origin_world": snapshot.get("origin_world"), "target_world": snapshot.get("target_world")})


func _on_enemy_leaving(id: int) -> void:
	if not _enemy_shooters.has(id):
		return
	var record: Dictionary = _enemy_shooters[id]
	var actor: Node = record.actor.get_ref()
	if is_instance_valid(actor):
		if actor.is_connected(&"rifle_shot_visual_requested", record.callback):
			actor.disconnect(&"rifle_shot_visual_requested", record.callback)
		var leaving := _on_enemy_leaving.bind(id)
		if actor.tree_exiting.is_connected(leaving):
			actor.tree_exiting.disconnect(leaving)
	_enemy_shooters.erase(id)


func request_defeat(snapshot: Dictionary) -> void:
	var frames := snapshot.get("sprite_frames") as SpriteFrames
	var animation: StringName = snapshot.get("defeat_animation", &"")
	if _pool == null or frames == null or not frames.has_animation(animation):
		push_warning("No se pudo representar la derrota: falta pool o recurso visual")
		return
	var effect := _pool.acquire() as DeathVisualEffect
	effect.play_snapshot(snapshot)


func request_rifle_shot(snapshot: Dictionary) -> void:
	if _closed or _rifle_pool == null \
			or GameStateManager._current_state != GameStateManager.GameState.PLAYING:
		return
	if snapshot.size() != 2 or not snapshot.get("origin_world") is Vector2 \
			or not snapshot.get("target_world") is Vector2:
		return
	var origin: Vector2 = snapshot["origin_world"]
	var target: Vector2 = snapshot["target_world"]
	if not origin.is_finite() or not target.is_finite():
		return
	var effect := _rifle_pool.acquire() as RifleShotVisualEffect
	_active_rifle_effects.append(effect)
	effect.play_snapshot({"origin_world": origin, "target_world": target})


func get_active_rifle_effect_count() -> int:
	return _rifle_pool.in_use_count() if _rifle_pool != null else 0


func get_available_rifle_effect_count() -> int:
	return _rifle_pool.available_count() if _rifle_pool != null else 0


func close_match() -> void:
	if _closed:
		return
	_closed = true
	for id: int in _enemy_shooters.keys():
		_on_enemy_leaving(id)
	for effect: RifleShotVisualEffect in _active_rifle_effects:
		_rifle_pool.release(effect)
	_active_rifle_effects.clear()
	if GameStateManager.game_state_changed.is_connected(_on_game_state_changed):
		GameStateManager.game_state_changed.disconnect(_on_game_state_changed)


func get_active_effect_count() -> int:
	return _pool.in_use_count() if _pool != null else 0


func get_available_effect_count() -> int:
	return _pool.available_count() if _pool != null else 0


func _exit_tree() -> void:
	close_match()


func _on_game_state_changed(state: int) -> void:
	# WON/LOST sólo bloquean nuevos tiros; los confirmados terminan su reloj.
	if state == GameStateManager.GameState.MENU:
		close_match()


func _on_effect_created(instance: Node) -> void:
	(instance as DeathVisualEffect).finished.connect(_on_effect_finished)


func _on_effect_finished(effect: Node2D, activation: int) -> void:
	if (effect as DeathVisualEffect).get_activation_id() == activation:
		_pool.release(effect)


func _on_rifle_effect_created(instance: Node) -> void:
	(instance as RifleShotVisualEffect).finished.connect(_on_rifle_effect_finished)


func _on_rifle_effect_finished(effect: Node2D, activation: int) -> void:
	var shot := effect as RifleShotVisualEffect
	if shot.get_activation_id() == activation:
		_active_rifle_effects.erase(shot)
		_rifle_pool.release(shot)
