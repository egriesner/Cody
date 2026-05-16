extends RefCounted
class_name SaveManager

const SAVE_PATH := "user://rift_profile.json"


static func default_profile() -> Dictionary:
	return {
		"studio": "Code Max Studios",
		"profile_version": 1,
		"player_name": "Cody Max",
		"tutorial_completed": false,
		"daily_streak": 0,
		"last_daily_reward_date": "",
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
			"show_hit_flash": true,
			"ui_scale": 1.0,
			"high_contrast": false
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

	var bank: Dictionary = updated.get("resources_bank", {})
	bank["human_scrap"] = int(bank.get("human_scrap", 0)) + int(result.get("bank_scrap_gain", 0))
	bank["alien_crystals"] = int(bank.get("alien_crystals", 0)) + int(result.get("bank_crystal_gain", 0))
	updated["resources_bank"] = bank

	_apply_meta_xp(updated, int(result.get("meta_xp_gain", 0)))
	updated["unlocked_skins"] = maxi(int(updated.get("unlocked_skins", 1)), int(result.get("skins_unlocked", 1)))
	updated["tutorial_completed"] = bool(updated.get("tutorial_completed", false)) or bool(result.get("tutorial_completed", false))

	var snapshot: Dictionary = result.get("continue_snapshot", {})
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


static func update_continue_snapshot(profile: Dictionary, snapshot: Dictionary) -> Dictionary:
	var updated := default_profile()
	_merge_dict(updated, profile)
	if typeof(snapshot) == TYPE_DICTIONARY and not snapshot.is_empty():
		updated["has_continue_snapshot"] = true
		updated["continue_snapshot"] = snapshot
	return updated


static func claim_daily_reward(profile: Dictionary) -> Dictionary:
	var updated := default_profile()
	_merge_dict(updated, profile)

	var today := _today_stamp()
	var last_claim := String(updated.get("last_daily_reward_date", ""))
	if today == last_claim:
		return {
			"profile": updated,
			"rewarded": false,
			"message": "Daily reward already claimed today."
		}

	var streak := int(updated.get("daily_streak", 0)) + 1
	updated["daily_streak"] = streak
	updated["last_daily_reward_date"] = today

	var scrap_reward := 10 + streak * 2
	var crystal_reward := 4 + int(streak / 2)
	var meta_xp_reward := 20 + streak * 3

	var bank: Dictionary = updated.get("resources_bank", {})
	bank["human_scrap"] = int(bank.get("human_scrap", 0)) + scrap_reward
	bank["alien_crystals"] = int(bank.get("alien_crystals", 0)) + crystal_reward
	updated["resources_bank"] = bank
	_apply_meta_xp(updated, meta_xp_reward)

	return {
		"profile": updated,
		"rewarded": true,
		"scrap": scrap_reward,
		"crystal": crystal_reward,
		"meta_xp": meta_xp_reward,
		"streak": streak,
		"message": "Daily reward claimed."
	}


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


static func today_stamp() -> String:
	return _today_stamp()


static func _today_stamp() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [int(d.get("year", 1970)), int(d.get("month", 1)), int(d.get("day", 1))]


static func _merge_dict(base: Dictionary, incoming: Dictionary) -> void:
	for key in incoming.keys():
		var incoming_value = incoming[key]
		if base.has(key) and typeof(base[key]) == TYPE_DICTIONARY and typeof(incoming_value) == TYPE_DICTIONARY:
			_merge_dict(base[key], incoming_value)
		else:
			base[key] = incoming_value
