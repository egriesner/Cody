extends RefCounted
class_name Telemetry

const DEFAULT_EVENT_LOG_PATH := "user://telemetry_events.jsonl"
const DEFAULT_STATE_PATH := "user://telemetry_state.json"

static var _configured := false
static var _enabled := true
static var _event_log_path := DEFAULT_EVENT_LOG_PATH
static var _state_path := DEFAULT_STATE_PATH
static var _session_id := ""


static func configure(settings: Dictionary) -> void:
	_configured = true
	_enabled = bool(settings.get("enabled", true))
	_event_log_path = String(settings.get("eventLogPath", DEFAULT_EVENT_LOG_PATH))
	_state_path = String(settings.get("statePath", DEFAULT_STATE_PATH))
	if _session_id.is_empty():
		_session_id = _new_session_id()


static func start_app_session(profile: Dictionary = {}) -> Dictionary:
	if not _configured:
		configure({})
	var previous_state := _read_state()
	var dirty_shutdown := bool(previous_state.get("app_open", false))
	var state := {
		"session_id": _session_id,
		"app_open": true,
		"runtime_active": false,
		"stage": "menu",
		"heartbeat_unix": int(Time.get_unix_time_from_system()),
		"last_profile_level": int(profile.get("meta_level", 1))
	}
	_write_state(state)
	log_event("app_session_start", {
		"meta_level": int(profile.get("meta_level", 1)),
		"total_runs": int(profile.get("total_runs", 0))
	})
	if dirty_shutdown:
		log_event("unclean_shutdown_detected", {
			"previous_stage": String(previous_state.get("stage", "unknown")),
			"previous_runtime_active": bool(previous_state.get("runtime_active", false)),
			"previous_heartbeat_unix": int(previous_state.get("heartbeat_unix", 0))
		}, "warning")
	return {
		"dirty_shutdown_detected": dirty_shutdown,
		"previous_state": previous_state
	}


static func update_heartbeat(stage: String, payload: Dictionary = {}) -> void:
	if not _enabled:
		return
	var state := _read_state()
	state["session_id"] = _session_id
	state["app_open"] = true
	state["stage"] = stage
	state["heartbeat_unix"] = int(Time.get_unix_time_from_system())
	for key in payload.keys():
		state[key] = payload[key]
	_write_state(state)


static func mark_runtime_started(payload: Dictionary = {}) -> void:
	if not _enabled:
		return
	var state := _read_state()
	state["session_id"] = _session_id
	state["app_open"] = true
	state["runtime_active"] = true
	state["stage"] = "runtime"
	state["heartbeat_unix"] = int(Time.get_unix_time_from_system())
	for key in payload.keys():
		state[key] = payload[key]
	_write_state(state)
	log_event("runtime_started", payload)


static func mark_runtime_finished(payload: Dictionary = {}) -> void:
	if not _enabled:
		return
	var state := _read_state()
	state["session_id"] = _session_id
	state["runtime_active"] = false
	state["stage"] = "menu"
	state["heartbeat_unix"] = int(Time.get_unix_time_from_system())
	state.erase("run_wave")
	state.erase("run_difficulty")
	state.erase("run_performance")
	_write_state(state)
	log_event("runtime_finished", payload)


static func mark_clean_shutdown(reason: String = "exit") -> void:
	if not _enabled:
		return
	var state := _read_state()
	state["session_id"] = _session_id
	state["app_open"] = false
	state["runtime_active"] = false
	state["stage"] = "closed"
	state["heartbeat_unix"] = int(Time.get_unix_time_from_system())
	state["shutdown_reason"] = reason
	_write_state(state)
	log_event("app_session_end", {"reason": reason})


static func log_event(name: String, payload: Dictionary = {}, level: String = "info") -> void:
	if not _enabled:
		return
	var event_payload := payload.duplicate(true)
	var event := {
		"event": name,
		"level": level,
		"unix_time": int(Time.get_unix_time_from_system()),
		"session_id": _session_id,
		"payload": event_payload
	}
	_append_json_line(event)


static func record_error(scope: String, message: String, payload: Dictionary = {}) -> void:
	var merged_payload := payload.duplicate(true)
	merged_payload["scope"] = scope
	merged_payload["message"] = message
	log_event("runtime_error", merged_payload, "error")


static func _append_json_line(data: Dictionary) -> void:
	var file := FileAccess.open(_event_log_path, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(_event_log_path, FileAccess.WRITE)
	if file == null:
		return
	file.seek_end()
	file.store_line(JSON.stringify(data))


static func _read_state() -> Dictionary:
	if not FileAccess.file_exists(_state_path):
		return {}
	var file := FileAccess.open(_state_path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


static func _write_state(state: Dictionary) -> void:
	var file := FileAccess.open(_state_path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(state))


static func _new_session_id() -> String:
	return "%d-%d" % [int(Time.get_unix_time_from_system()), randi_range(100000, 999999)]
