extends GutTest
## 013/T004: persistencia real aislada del perfil del jugador.
var _path: String


func before_each() -> void:
	_path = OS.get_temp_dir().path_join("demons_intro_%s.cfg" % str(Time.get_ticks_usec()))


func after_each() -> void:
	if FileAccess.file_exists(_path):
		DirAccess.remove_absolute(_path)


func _progress() -> IntroProgress:
	var progress := IntroProgress.new()
	progress.storage_path = _path
	return progress


func test_absent_record_is_unseen_without_writing() -> void:
	assert_false(_progress().has_seen("la_carta_v1"))
	assert_false(FileAccess.file_exists(_path), "Consultar no crea un recuerdo")


func test_successful_mark_survives_a_new_instance_only_for_that_version() -> void:
	assert_eq(_progress().mark_seen("la_carta_v1"), OK)
	assert_true(_progress().has_seen("la_carta_v1"), "Una nueva instancia recupera el recuerdo")
	assert_false(_progress().has_seen("la_carta_v2"), "Otra versión requiere nueva lectura")


func test_corrupt_record_is_unseen_and_not_rewritten_on_read() -> void:
	var file := FileAccess.open(_path, FileAccess.WRITE)
	file.store_string("[broken\nnot a config")
	file.close()
	assert_false(_progress().has_seen("la_carta_v1"))
	assert_eq(FileAccess.get_file_as_string(_path), "[broken\nnot a config")


func test_empty_or_unrelated_record_does_not_claim_completion() -> void:
	var config := ConfigFile.new()
	config.set_value("unrelated", "setting", true)
	assert_eq(config.save(_path), OK, "Control: archivo válido existe")
	assert_false(_progress().has_seen("la_carta_v1"))


func test_failed_save_returns_error_and_does_not_claim_persistence() -> void:
	var progress := _progress()
	progress.storage_path = _path.path_join("missing/intro.cfg")
	assert_ne(progress.mark_seen("la_carta_v1"), OK)
	assert_false(progress.has_seen("la_carta_v1"))
	assert_false(FileAccess.file_exists(progress.storage_path))
