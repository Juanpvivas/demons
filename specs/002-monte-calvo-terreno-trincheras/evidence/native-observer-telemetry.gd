extends "res://_observation_base.gd"

# Temporary native variant. Inherits the approved read-only observer unchanged.
# Only reads performance/state, enables viewport profiling, and writes diagnostics.
# No game setters, input injection/consumption, pause, scene replacement or buttons.
var _native_rows: Array = []
var _native_elapsed: float = 0.0
var _native_last_second: int = -1
var _native_saved: bool = false
var _native_ready_usec: int = 0
var _native_first_frame: Dictionary = {}

func _ready() -> void:
	super._ready()
	_native_ready_usec = Time.get_ticks_usec()
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	_native_first_post_draw()
	print("NATIVE_GEOMETRY ", JSON.stringify({"renderer": RenderingServer.get_current_rendering_method(), "driver": RenderingServer.get_current_rendering_driver_name(), "gpu": RenderingServer.get_video_adapter_name(), "window_size": str(DisplayServer.window_get_size()), "visible_rect": str(get_viewport().get_visible_rect()), "canvas_transform": str(get_viewport().canvas_transform), "stretch_transform": str(get_viewport().get_stretch_transform()), "root_scene": get_parent().scene_file_path, "touch_to_mouse_emulation": ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch", true)}))

func _native_first_post_draw() -> void:
	await RenderingServer.frame_post_draw
	_native_first_frame = {"engine_ticks_ms": Time.get_ticks_msec(), "observer_ready_to_post_draw_ms": (Time.get_ticks_usec() - _native_ready_usec)/1000.0, "scope": "Godot engine clock and observer ready to first post draw; excludes OS launch before engine; filesystem cache uncontrolled"}
	print("NATIVE_FIRST_FRAME ", JSON.stringify(_native_first_frame))

func _process(delta: float) -> void:
	super._process(delta)
	_native_elapsed += delta
	var rid: RID = get_viewport().get_viewport_rid()
	var row: Dictionary = {"elapsed_seconds": _native_elapsed, "game_state": GameStateManager.get("_current_state"), "delta_ms": delta*1000.0, "engine_fps": Performance.get_monitor(Performance.TIME_FPS), "process_ms": Performance.get_monitor(Performance.TIME_PROCESS)*1000.0, "physics_process_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0, "render_setup_cpu_ms": RenderingServer.get_frame_setup_time_cpu(), "viewport_render_cpu_ms": RenderingServer.viewport_get_measured_render_time_cpu(rid), "viewport_render_gpu_ms": RenderingServer.viewport_get_measured_render_time_gpu(rid), "texture_mem_bytes": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED), "video_mem_bytes": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED), "draw_calls_reported": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
	if not _native_saved:
		_native_rows.append(row)
	if int(_native_elapsed) != _native_last_second:
		_native_last_second = int(_native_elapsed)
		print("NATIVE_TELEMETRY ", JSON.stringify(row))
	if _native_elapsed >= 35.0 and not _native_saved:
		_native_saved = true
		var file: FileAccess = FileAccess.open("user://native-telemetry.json", FileAccess.WRITE)
		file.store_string(JSON.stringify({"method": "approved read-only observer003 plus telemetry002 in temporary native variant", "renderer": RenderingServer.get_current_rendering_method(), "driver": RenderingServer.get_current_rendering_driver_name(), "gpu": RenderingServer.get_video_adapter_name(), "first_post_draw": _native_first_frame, "rows": _native_rows}))
		file.close()
		print("NATIVE_TELEMETRY_SAVED rows=", _native_rows.size())
