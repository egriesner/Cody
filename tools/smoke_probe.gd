extends SceneTree

var _errors: Array[String] = []


func _init() -> void:
	_check_file("res://project.godot")
	_check_resource("res://android_ui_state_config.json")
	_check_resource("res://scripts/Main.gd")
	_check_resource("res://scripts/GameRuntime.gd")
	_check_resource("res://scripts/SaveManager.gd")
	_check_resource("res://scripts/Telemetry.gd")
	_check_scene("res://scenes/Main.tscn")
	_check_scene("res://scenes/Game.tscn")
	if _errors.is_empty():
		print("[smoke] Godot probe passed.")
		quit(0)
		return
	for issue in _errors:
		push_error(issue)
	quit(1)


func _check_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		_errors.append("[smoke] Missing file: %s" % path)


func _check_resource(path: String) -> void:
	if not ResourceLoader.exists(path):
		_errors.append("[smoke] Missing resource: %s" % path)
		return
	var loaded: Resource = load(path)
	if loaded == null:
		_errors.append("[smoke] Failed to load resource: %s" % path)


func _check_scene(path: String) -> void:
	if not ResourceLoader.exists(path):
		_errors.append("[smoke] Missing scene: %s" % path)
		return
	var packed := load(path) as PackedScene
	if packed == null:
		_errors.append("[smoke] Failed to parse scene: %s" % path)
		return
	var instance := packed.instantiate()
	if instance == null:
		_errors.append("[smoke] Failed to instantiate scene: %s" % path)
		return
	instance.free()
