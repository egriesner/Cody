extends RefCounted
class_name SaveManager

const SAVE_PATH := "user://rift_profile.json"


static func default_profile() -> Dictionary:
	return {
		"studio": "Code Max Studios",
		"profile_version": 1,
		"player_name": "Cody Max",
		"tutorial_completed": false,
		"meta_level": 1,
		"meta_xp": 0,
		"total_runs": 0,
		"total_wins": 0,
		"best_wave": 0,
		"best_time_seconds": 0,
		"total_drones_defeated": 0,
		"total_bestiary_pages": 0,
		"unlocked_skins": 1,
		"resources_bank": {
			"human_scrap": 0,
			"alien_crystals": 0
		},
		"settings": {
			"master_volume": 0.85,
			"vibration": true,
			"difficulty": "normal",
			"show_hit_flash": true
		},
		"has_continue_snapshot": false,
		"continue_snapshot": {}
	}


static func load_profile() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return default_profile()

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return default_profile()

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return default_profile()

	var profile := default_profile()
	_merge_dict(profile, parsed)
	return profile


static func save_profile(profile: Dictionary) -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(profile))
	return true


static func apply_session_result(profile: Dictionary, result: Dictionary) -> Dictionary:
	var updated := default_profile()
	_merge_dict(updated, profile)

	updated["total_runs"] = int(updated.get("total_runs", 0)) + 1
	if bool(result.get("victory", false)):
		updated["total_wins"] = int(updated.get("total_wins", 0)) + 1

	var wave := int(result.get("wave_reached", 0))
	updated["best_wave"] = maxi(int(updated.get("best_wave", 0)), wave)

	var duration := int(result.get("duration_seconds", 0))
	var best_time := int(updated.get("best_time_seconds", 0))
	if best_time == 0 or duration > best_time:
		updated["best_time_seconds"] = duration

	updated["total_drones_defeated"] = int(updated.get("total_drones_defeated", 0)) + int(result.get("drones_defeated", 0))
	updated["total_bestiary_pages"] = int(updated.get("total_bestiary_pages", 0)) + int(result.get("bestiary_pages_collected", 0))

	var bank := updated.get("resources_bank", {})
	bank["human_scrap"] = int(bank.get("human_scrap", 0)) + int(result.get("bank_scrap_gain", 0))
	bank["alien_crystals"] = int(bank.get("alien_crystals", 0)) + int(result.get("bank_crystal_gain", 0))
	updated["resources_bank"] = bank

	_apply_meta_xp(updated, int(result.get("meta_xp_gain", 0)))
	updated["unlocked_skins"] = maxi(int(updated.get("unlocked_skins", 1)), int(result.get("skins_unlocked", 1)))
	updated["tutorial_completed"] = bool(updated.get("tutorial_completed", false)) or bool(result.get("tutorial_completed", false))

	var snapshot = result.get("continue_snapshot", {})
	if typeof(snapshot) == TYPE_DICTIONARY and not snapshot.is_empty():
		updated["has_continue_snapshot"] = true
		updated["continue_snapshot"] = snapshot
	else:
		updated["has_continue_snapshot"] = false
		updated["continue_snapshot"] = {}

	return updated


static func clear_continue_snapshot(profile: Dictionary) -> Dictionary:
	var updated := default_profile()
	_merge_dict(updated, profile)
	updated["has_continue_snapshot"] = false
	updated["continue_snapshot"] = {}
	return updated


static func _apply_meta_xp(profile: Dictionary, gained_xp: int) -> void:
	var xp := int(profile.get("meta_xp", 0)) + maxi(gained_xp, 0)
	var level := int(profile.get("meta_level", 1))
	var needed := _meta_level_cost(level)
	while xp >= needed:
		xp -= needed
		level += 1
		needed = _meta_level_cost(level)
	profile["meta_level"] = level
	profile["meta_xp"] = xp


static func _meta_level_cost(level: int) -> int:
	return 90 + (level * 35)


static func _merge_dict(base: Dictionary, incoming: Dictionary) -> void:
	for key in incoming.keys():
		var incoming_value = incoming[key]
		if base.has(key) and typeof(base[key]) == TYPE_DICTIONARY and typeof(incoming_value) == TYPE_DICTIONARY:
			_merge_dict(base[key], incoming_value)
		else:
			base[key] = incoming_value
