extends Control

const GAME_RUNTIME_SCRIPT := preload("res://scripts/GameRuntime.gd")
const SAVE_MANAGER_SCRIPT := preload("res://scripts/SaveManager.gd")

var profile: Dictionary = {}
var active_runtime: GameRuntime

var title_label: Label
var subtitle_label: Label
var profile_label: Label
var status_label: Label
var menu_panel: Panel
var settings_panel: Panel
var continue_button: Button
var daily_reward_button: Button
var settings_volume_slider: HSlider
var settings_vibration_toggle: CheckButton
var settings_hit_flash_toggle: CheckButton
var settings_ui_scale_slider: HSlider
var settings_high_contrast_toggle: CheckButton
var difficulty_option: OptionButton


func _ready() -> void:
	_load_profile()
	_build_menu_ui()
	_refresh_menu()


func _load_profile() -> void:
	profile = SAVE_MANAGER_SCRIPT.load_profile()


func _save_profile() -> void:
	SAVE_MANAGER_SCRIPT.save_profile(profile)


func _build_menu_ui() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("#090d1a")
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	menu_panel = Panel.new()
	menu_panel.size = Vector2(980, 640)
	menu_panel.position = Vector2(470, 180)
	add_child(menu_panel)

	title_label = Label.new()
	title_label.text = "RIFT: THE BESTIARY PROTOCOL"
	title_label.position = Vector2(152, 34)
	title_label.add_theme_font_size_override("font_size", 44)
	menu_panel.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.text = "Open-world survival brawler by Code Max Studios"
	subtitle_label.position = Vector2(182, 92)
	subtitle_label.add_theme_font_size_override("font_size", 20)
	menu_panel.add_child(subtitle_label)

	profile_label = Label.new()
	profile_label.position = Vector2(62, 150)
	profile_label.size = Vector2(860, 130)
	profile_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_panel.add_child(profile_label)

	status_label = Label.new()
	status_label.position = Vector2(62, 286)
	status_label.size = Vector2(860, 46)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_panel.add_child(status_label)

	var new_run_button := Button.new()
	new_run_button.text = "Start New Run"
	new_run_button.position = Vector2(90, 360)
	new_run_button.size = Vector2(250, 62)
	new_run_button.pressed.connect(_on_new_run_pressed)
	menu_panel.add_child(new_run_button)

	continue_button = Button.new()
	continue_button.text = "Continue Run"
	continue_button.position = Vector2(365, 360)
	continue_button.size = Vector2(250, 62)
	continue_button.pressed.connect(_on_continue_pressed)
	menu_panel.add_child(continue_button)

	daily_reward_button = Button.new()
	daily_reward_button.text = "Claim Daily Reward"
	daily_reward_button.position = Vector2(365, 436)
	daily_reward_button.size = Vector2(250, 50)
	daily_reward_button.pressed.connect(_on_claim_daily_reward_pressed)
	menu_panel.add_child(daily_reward_button)

	var settings_button := Button.new()
	settings_button.text = "Settings"
	settings_button.position = Vector2(640, 360)
	settings_button.size = Vector2(250, 62)
	settings_button.pressed.connect(_on_settings_pressed)
	menu_panel.add_child(settings_button)

	var docs_label := Label.new()
	docs_label.position = Vector2(62, 500)
	docs_label.size = Vector2(860, 56)
	docs_label.text = "Run flow: Explore -> Wave combat -> Craft -> Bestiary pages -> Overlord Vex -> Rift Weaver ending"
	docs_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_panel.add_child(docs_label)

	var studio_label := Label.new()
	studio_label.position = Vector2(62, 586)
	studio_label.size = Vector2(860, 30)
	studio_label.text = "Developer: Code Max Studios"
	menu_panel.add_child(studio_label)

	_build_settings_panel()


func _build_settings_panel() -> void:
	settings_panel = Panel.new()
	settings_panel.size = Vector2(620, 430)
	settings_panel.position = Vector2(650, 280)
	settings_panel.visible = false
	add_child(settings_panel)

	var settings_title := Label.new()
	settings_title.text = "Settings"
	settings_title.position = Vector2(246, 24)
	settings_title.add_theme_font_size_override("font_size", 34)
	settings_panel.add_child(settings_title)

	var volume_label := Label.new()
	volume_label.text = "Master Volume"
	volume_label.position = Vector2(60, 104)
	settings_panel.add_child(volume_label)

	settings_volume_slider = HSlider.new()
	settings_volume_slider.position = Vector2(230, 102)
	settings_volume_slider.size = Vector2(320, 30)
	settings_volume_slider.min_value = 0.0
	settings_volume_slider.max_value = 1.0
	settings_volume_slider.step = 0.01
	settings_panel.add_child(settings_volume_slider)

	settings_vibration_toggle = CheckButton.new()
	settings_vibration_toggle.text = "Enable Vibration"
	settings_vibration_toggle.position = Vector2(60, 158)
	settings_panel.add_child(settings_vibration_toggle)

	settings_hit_flash_toggle = CheckButton.new()
	settings_hit_flash_toggle.text = "Enable Hit Flash"
	settings_hit_flash_toggle.position = Vector2(300, 158)
	settings_panel.add_child(settings_hit_flash_toggle)

	var ui_scale_label := Label.new()
	ui_scale_label.text = "UI Scale"
	ui_scale_label.position = Vector2(60, 194)
	settings_panel.add_child(ui_scale_label)

	settings_ui_scale_slider = HSlider.new()
	settings_ui_scale_slider.position = Vector2(230, 190)
	settings_ui_scale_slider.size = Vector2(320, 30)
	settings_ui_scale_slider.min_value = 0.8
	settings_ui_scale_slider.max_value = 1.3
	settings_ui_scale_slider.step = 0.01
	settings_panel.add_child(settings_ui_scale_slider)

	settings_high_contrast_toggle = CheckButton.new()
	settings_high_contrast_toggle.text = "High Contrast UI"
	settings_high_contrast_toggle.position = Vector2(60, 228)
	settings_panel.add_child(settings_high_contrast_toggle)

	var difficulty_label := Label.new()
	difficulty_label.text = "Difficulty"
	difficulty_label.position = Vector2(300, 228)
	settings_panel.add_child(difficulty_label)

	difficulty_option = OptionButton.new()
	difficulty_option.position = Vector2(410, 222)
	difficulty_option.size = Vector2(140, 36)
	difficulty_option.add_item("Easy", 0)
	difficulty_option.add_item("Normal", 1)
	difficulty_option.add_item("Hard", 2)
	settings_panel.add_child(difficulty_option)

	var save_button := Button.new()
	save_button.text = "Save Settings"
	save_button.position = Vector2(96, 304)
	save_button.size = Vector2(200, 54)
	save_button.pressed.connect(_on_save_settings_pressed)
	settings_panel.add_child(save_button)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.position = Vector2(328, 304)
	close_button.size = Vector2(200, 54)
	close_button.pressed.connect(_on_close_settings_pressed)
	settings_panel.add_child(close_button)

	var replay_tutorial_button := Button.new()
	replay_tutorial_button.text = "Replay Tutorial Next Run"
	replay_tutorial_button.position = Vector2(172, 366)
	replay_tutorial_button.size = Vector2(276, 40)
	replay_tutorial_button.pressed.connect(_on_replay_tutorial_pressed)
	settings_panel.add_child(replay_tutorial_button)


func _refresh_menu() -> void:
	var settings: Dictionary = profile.get("settings", {})
	settings_volume_slider.value = float(settings.get("master_volume", 0.85))
	settings_vibration_toggle.button_pressed = bool(settings.get("vibration", true))
	settings_hit_flash_toggle.button_pressed = bool(settings.get("show_hit_flash", true))
	settings_ui_scale_slider.value = float(settings.get("ui_scale", 1.0))
	settings_high_contrast_toggle.button_pressed = bool(settings.get("high_contrast", false))
	var difficulty := String(settings.get("difficulty", "normal"))
	match difficulty:
		"easy":
			difficulty_option.select(0)
		"hard":
			difficulty_option.select(2)
		_:
			difficulty_option.select(1)

	continue_button.disabled = not bool(profile.get("has_continue_snapshot", false))
	var reward_claimed_today := String(profile.get("last_daily_reward_date", "")) == SAVE_MANAGER_SCRIPT.today_stamp()
	daily_reward_button.disabled = reward_claimed_today
	if reward_claimed_today:
		daily_reward_button.text = "Reward Claimed Today"
	else:
		daily_reward_button.text = "Claim Daily Reward (Streak %d)" % int(profile.get("daily_streak", 0))
	profile_label.text = "Meta Lv %d (%d XP) | Runs: %d | Wins: %d | Best Wave: %d | Drones Defeated: %d | Bestiary Pages: %d" % [
		int(profile.get("meta_level", 1)),
		int(profile.get("meta_xp", 0)),
		int(profile.get("total_runs", 0)),
		int(profile.get("total_wins", 0)),
		int(profile.get("best_wave", 0)),
		int(profile.get("total_drones_defeated", 0)),
		int(profile.get("total_bestiary_pages", 0))
	]
	if bool(profile.get("tutorial_completed", false)):
		status_label.text = "Ready for deployment builds and Play Store progression testing. Daily streak: %d" % int(profile.get("daily_streak", 0))
	else:
		status_label.text = "Tutorial pending: first run will open guided onboarding."


func _launch_runtime(use_continue_snapshot: bool) -> void:
	if active_runtime != null:
		active_runtime.queue_free()

	var runtime: GameRuntime = GAME_RUNTIME_SCRIPT.new()
	var runtime_profile := profile.duplicate(true)
	if not use_continue_snapshot:
		runtime_profile = SAVE_MANAGER_SCRIPT.clear_continue_snapshot(runtime_profile)
	profile = runtime_profile
	runtime.set_profile(runtime_profile)
	runtime.session_finished.connect(_on_runtime_session_finished)
	runtime.checkpoint_updated.connect(_on_runtime_checkpoint_updated)
	active_runtime = runtime
	add_child(runtime)
	menu_panel.visible = false
	settings_panel.visible = false
	status_label.text = "Run in progress..."


func _on_runtime_session_finished(victory: bool, summary: Dictionary) -> void:
	var restart_requested := bool(summary.get("request_restart", false))
	profile = SAVE_MANAGER_SCRIPT.apply_session_result(profile, summary)
	_save_profile()
	_refresh_menu()
	menu_panel.visible = true
	settings_panel.visible = false
	if active_runtime != null and is_instance_valid(active_runtime):
		active_runtime = null
	status_label.text = "Run complete: %s" % ("Victory" if victory else "Session ended")
	if restart_requested:
		_launch_runtime(false)


func _on_new_run_pressed() -> void:
	_launch_runtime(false)


func _on_continue_pressed() -> void:
	if continue_button.disabled:
		status_label.text = "No continue snapshot available."
		return
	_launch_runtime(true)


func _on_settings_pressed() -> void:
	settings_panel.visible = true


func _on_save_settings_pressed() -> void:
	var settings: Dictionary = profile.get("settings", {})
	settings["master_volume"] = settings_volume_slider.value
	settings["vibration"] = settings_vibration_toggle.button_pressed
	settings["show_hit_flash"] = settings_hit_flash_toggle.button_pressed
	settings["ui_scale"] = settings_ui_scale_slider.value
	settings["high_contrast"] = settings_high_contrast_toggle.button_pressed
	match difficulty_option.selected:
		0:
			settings["difficulty"] = "easy"
		2:
			settings["difficulty"] = "hard"
		_:
			settings["difficulty"] = "normal"
	profile["settings"] = settings
	_save_profile()
	status_label.text = "Settings saved."


func _on_close_settings_pressed() -> void:
	settings_panel.visible = false


func _on_replay_tutorial_pressed() -> void:
	profile["tutorial_completed"] = false
	_save_profile()
	_refresh_menu()
	status_label.text = "Tutorial will appear on the next run."


func _on_runtime_checkpoint_updated(snapshot: Dictionary) -> void:
	profile = SAVE_MANAGER_SCRIPT.update_continue_snapshot(profile, snapshot)
	_save_profile()


func _on_claim_daily_reward_pressed() -> void:
	var result: Dictionary = SAVE_MANAGER_SCRIPT.claim_daily_reward(profile)
	profile = result.get("profile", profile)
	_save_profile()
	_refresh_menu()
	if bool(result.get("rewarded", false)):
		status_label.text = "Daily reward claimed: +%d scrap, +%d crystals, +%d meta XP (streak %d)." % [
			int(result.get("scrap", 0)),
			int(result.get("crystal", 0)),
			int(result.get("meta_xp", 0)),
			int(result.get("streak", 0))
		]
	else:
		status_label.text = String(result.get("message", "Daily reward unavailable."))
