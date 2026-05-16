extends Control

const GAME_RUNTIME_SCRIPT := preload("res://scripts/GameRuntime.gd")
const SAVE_MANAGER_SCRIPT := preload("res://scripts/SaveManager.gd")
const CONCEPT_BG_PATH := "res://rift-master-concept-technical-ui-blueprint.svg"
const PANEL_TOP_PATH := "res://assets/artpack/ui/hud_top_panel.svg"
const PANEL_BOTTOM_PATH := "res://assets/artpack/ui/hud_bottom_panel.svg"
const BUTTON_PRIMARY_PATH := "res://assets/artpack/ui/button_primary.svg"
const BUTTON_SECONDARY_PATH := "res://assets/artpack/ui/button_secondary.svg"

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
var settings_music_slider: HSlider
var settings_sfx_slider: HSlider
var settings_vibration_toggle: CheckButton
var settings_hit_flash_toggle: CheckButton
var settings_perf_hud_toggle: CheckButton
var settings_ui_scale_slider: HSlider
var settings_high_contrast_toggle: CheckButton
var difficulty_option: OptionButton
var performance_option: OptionButton
var concept_bg_texture: Texture2D
var panel_top_texture: Texture2D
var panel_bottom_texture: Texture2D
var button_primary_texture: Texture2D
var button_secondary_texture: Texture2D


func _ready() -> void:
	_load_profile()
	_load_visual_assets()
	_apply_master_volume_from_profile()
	_build_menu_ui()
	_refresh_menu()


func _load_profile() -> void:
	profile = SAVE_MANAGER_SCRIPT.load_profile()


func _save_profile() -> void:
	SAVE_MANAGER_SCRIPT.save_profile(profile)


func _load_visual_assets() -> void:
	concept_bg_texture = _load_texture_if_exists(CONCEPT_BG_PATH)
	panel_top_texture = _load_texture_if_exists(PANEL_TOP_PATH)
	panel_bottom_texture = _load_texture_if_exists(PANEL_BOTTOM_PATH)
	button_primary_texture = _load_texture_if_exists(BUTTON_PRIMARY_PATH)
	button_secondary_texture = _load_texture_if_exists(BUTTON_SECONDARY_PATH)


func _load_texture_if_exists(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _apply_master_volume_from_profile() -> void:
	var settings: Dictionary = profile.get("settings", {})
	var volume := float(settings.get("master_volume", 0.85))
	var bus_index := AudioServer.get_bus_index("Master")
	if bus_index < 0:
		return
	if volume <= 0.0001:
		AudioServer.set_bus_volume_db(bus_index, -80.0)
	else:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(clamp(volume, 0.0001, 1.0)))


func _build_menu_ui() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	if concept_bg_texture != null:
		var bg_texture := TextureRect.new()
		bg_texture.texture = concept_bg_texture
		bg_texture.set_anchors_preset(PRESET_FULL_RECT)
		bg_texture.stretch_mode = TextureRect.STRETCH_SCALE
		bg_texture.modulate = Color(1.0, 1.0, 1.0, 0.40)
		bg_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg_texture)

	var bg_overlay := ColorRect.new()
	bg_overlay.color = Color(0.03, 0.07, 0.15, 0.88)
	bg_overlay.set_anchors_preset(PRESET_FULL_RECT)
	bg_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_overlay)

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
	_apply_menu_skin()


func _build_settings_panel() -> void:
	settings_panel = Panel.new()
	settings_panel.size = Vector2(720, 560)
	settings_panel.position = Vector2(600, 220)
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

	var music_label := Label.new()
	music_label.text = "Music Volume"
	music_label.position = Vector2(60, 142)
	settings_panel.add_child(music_label)

	settings_music_slider = HSlider.new()
	settings_music_slider.position = Vector2(230, 140)
	settings_music_slider.size = Vector2(320, 30)
	settings_music_slider.min_value = 0.0
	settings_music_slider.max_value = 1.0
	settings_music_slider.step = 0.01
	settings_panel.add_child(settings_music_slider)

	var sfx_label := Label.new()
	sfx_label.text = "SFX Volume"
	sfx_label.position = Vector2(60, 180)
	settings_panel.add_child(sfx_label)

	settings_sfx_slider = HSlider.new()
	settings_sfx_slider.position = Vector2(230, 178)
	settings_sfx_slider.size = Vector2(320, 30)
	settings_sfx_slider.min_value = 0.0
	settings_sfx_slider.max_value = 1.0
	settings_sfx_slider.step = 0.01
	settings_panel.add_child(settings_sfx_slider)

	settings_vibration_toggle = CheckButton.new()
	settings_vibration_toggle.text = "Enable Vibration"
	settings_vibration_toggle.position = Vector2(60, 224)
	settings_panel.add_child(settings_vibration_toggle)

	settings_hit_flash_toggle = CheckButton.new()
	settings_hit_flash_toggle.text = "Enable Hit Flash"
	settings_hit_flash_toggle.position = Vector2(300, 224)
	settings_panel.add_child(settings_hit_flash_toggle)

	var ui_scale_label := Label.new()
	ui_scale_label.text = "UI Scale"
	ui_scale_label.position = Vector2(60, 260)
	settings_panel.add_child(ui_scale_label)

	settings_ui_scale_slider = HSlider.new()
	settings_ui_scale_slider.position = Vector2(230, 256)
	settings_ui_scale_slider.size = Vector2(320, 30)
	settings_ui_scale_slider.min_value = 0.8
	settings_ui_scale_slider.max_value = 1.3
	settings_ui_scale_slider.step = 0.01
	settings_panel.add_child(settings_ui_scale_slider)

	settings_high_contrast_toggle = CheckButton.new()
	settings_high_contrast_toggle.text = "High Contrast UI"
	settings_high_contrast_toggle.position = Vector2(60, 298)
	settings_panel.add_child(settings_high_contrast_toggle)

	var difficulty_label := Label.new()
	difficulty_label.text = "Difficulty"
	difficulty_label.position = Vector2(300, 298)
	settings_panel.add_child(difficulty_label)

	difficulty_option = OptionButton.new()
	difficulty_option.position = Vector2(410, 292)
	difficulty_option.size = Vector2(140, 36)
	difficulty_option.add_item("Easy", 0)
	difficulty_option.add_item("Normal", 1)
	difficulty_option.add_item("Hard", 2)
	settings_panel.add_child(difficulty_option)

	var perf_label := Label.new()
	perf_label.text = "Performance Mode"
	perf_label.position = Vector2(60, 342)
	settings_panel.add_child(perf_label)

	performance_option = OptionButton.new()
	performance_option.position = Vector2(230, 336)
	performance_option.size = Vector2(220, 36)
	performance_option.add_item("Quality", 0)
	performance_option.add_item("Balanced", 1)
	performance_option.add_item("Performance", 2)
	settings_panel.add_child(performance_option)

	settings_perf_hud_toggle = CheckButton.new()
	settings_perf_hud_toggle.text = "Show Perf HUD In-Run"
	settings_perf_hud_toggle.position = Vector2(470, 338)
	settings_panel.add_child(settings_perf_hud_toggle)

	var save_button := Button.new()
	save_button.text = "Save Settings"
	save_button.position = Vector2(112, 420)
	save_button.size = Vector2(200, 54)
	save_button.pressed.connect(_on_save_settings_pressed)
	settings_panel.add_child(save_button)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.position = Vector2(380, 420)
	close_button.size = Vector2(200, 54)
	close_button.pressed.connect(_on_close_settings_pressed)
	settings_panel.add_child(close_button)

	var replay_tutorial_button := Button.new()
	replay_tutorial_button.text = "Replay Tutorial Next Run"
	replay_tutorial_button.position = Vector2(222, 490)
	replay_tutorial_button.size = Vector2(276, 44)
	replay_tutorial_button.pressed.connect(_on_replay_tutorial_pressed)
	settings_panel.add_child(replay_tutorial_button)


func _make_stylebox(bg: Color, border: Color, border_size: int = 2, radius: int = 12) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_size)
	sb.set_corner_radius_all(radius)
	return sb


func _make_texture_stylebox(texture: Texture2D, margin: int = 14) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = texture
	sb.texture_margin_left = margin
	sb.texture_margin_top = margin
	sb.texture_margin_right = margin
	sb.texture_margin_bottom = margin
	return sb


func _style_button(button: Button, primary: bool = false) -> void:
	button.add_theme_color_override("font_color", Color(0.90, 0.97, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	button.add_theme_font_size_override("font_size", 18)
	if primary and button_primary_texture != null:
		var primary_style := _make_texture_stylebox(button_primary_texture, 16)
		button.add_theme_stylebox_override("normal", primary_style)
		button.add_theme_stylebox_override("hover", primary_style)
		button.add_theme_stylebox_override("pressed", primary_style)
	elif button_secondary_texture != null:
		var secondary_style := _make_texture_stylebox(button_secondary_texture, 10)
		button.add_theme_stylebox_override("normal", secondary_style)
		button.add_theme_stylebox_override("hover", secondary_style)
		button.add_theme_stylebox_override("pressed", secondary_style)
	else:
		var fallback := _make_stylebox(Color(0.10, 0.19, 0.36, 0.86), Color(0.58, 0.42, 1.0, 0.95), 2, 12)
		button.add_theme_stylebox_override("normal", fallback)
		button.add_theme_stylebox_override("hover", fallback)
		button.add_theme_stylebox_override("pressed", fallback)


func _style_controls_recursive(root: Node) -> void:
	for child in root.get_children():
		if child is Label:
			var label := child as Label
			label.add_theme_color_override("font_color", Color(0.86, 0.97, 1.0))
		elif child is Button:
			_style_button(child as Button)
		elif child is OptionButton:
			_style_button(child as Button)
		elif child is CheckButton:
			_style_button(child as Button)
		_style_controls_recursive(child)


func _apply_menu_skin() -> void:
	if menu_panel != null:
		if panel_top_texture != null:
			menu_panel.add_theme_stylebox_override("panel", _make_texture_stylebox(panel_top_texture, 14))
		else:
			menu_panel.add_theme_stylebox_override("panel", _make_stylebox(Color(0.05, 0.10, 0.22, 0.94), Color(0.32, 0.84, 1.0, 0.9), 2, 16))
	if settings_panel != null:
		if panel_bottom_texture != null:
			settings_panel.add_theme_stylebox_override("panel", _make_texture_stylebox(panel_bottom_texture, 14))
		else:
			settings_panel.add_theme_stylebox_override("panel", _make_stylebox(Color(0.05, 0.10, 0.22, 0.94), Color(0.66, 0.44, 1.0, 0.9), 2, 16))

	_style_controls_recursive(menu_panel)
	_style_controls_recursive(settings_panel)
	for child in menu_panel.get_children():
		if child is Button:
			var menu_button := child as Button
			var is_primary := menu_button.text == "Start New Run"
			_style_button(menu_button, is_primary)


func _refresh_menu() -> void:
	var settings: Dictionary = profile.get("settings", {})
	settings_volume_slider.value = float(settings.get("master_volume", 0.85))
	settings_music_slider.value = float(settings.get("music_volume", 0.85))
	settings_sfx_slider.value = float(settings.get("sfx_volume", 0.90))
	settings_vibration_toggle.button_pressed = bool(settings.get("vibration", true))
	settings_hit_flash_toggle.button_pressed = bool(settings.get("show_hit_flash", true))
	settings_perf_hud_toggle.button_pressed = bool(settings.get("show_perf_hud", false))
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
	var performance_mode := String(settings.get("performance_mode", "balanced"))
	match performance_mode:
		"quality":
			performance_option.select(0)
		"performance":
			performance_option.select(2)
		_:
			performance_option.select(1)

	continue_button.disabled = not bool(profile.get("has_continue_snapshot", false))
	var reward_claimed_today := String(profile.get("last_daily_reward_date", "")) == SAVE_MANAGER_SCRIPT.today_stamp()
	daily_reward_button.disabled = reward_claimed_today
	if reward_claimed_today:
		daily_reward_button.text = "Reward Claimed Today"
	else:
		daily_reward_button.text = "Claim Daily Reward (Streak %d)" % int(profile.get("daily_streak", 0))
	profile_label.text = "Meta Lv %d (%d XP) | Runs: %d | Wins: %d | Best Wave: %d | Best Rank: %s | Best Score: %d\nDrones Defeated: %d | Bestiary Pages: %d | Best Combo: x%.2f | Total Dashes: %d" % [
		int(profile.get("meta_level", 1)),
		int(profile.get("meta_xp", 0)),
		int(profile.get("total_runs", 0)),
		int(profile.get("total_wins", 0)),
		int(profile.get("best_wave", 0)),
		String(profile.get("best_run_rank", "C")),
		int(profile.get("best_run_score", 0)),
		int(profile.get("total_drones_defeated", 0)),
		int(profile.get("total_bestiary_pages", 0)),
		float(profile.get("best_combo", 1.0)),
		int(profile.get("total_dash_uses", 0))
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
	settings["music_volume"] = settings_music_slider.value
	settings["sfx_volume"] = settings_sfx_slider.value
	settings["vibration"] = settings_vibration_toggle.button_pressed
	settings["show_hit_flash"] = settings_hit_flash_toggle.button_pressed
	settings["show_perf_hud"] = settings_perf_hud_toggle.button_pressed
	settings["ui_scale"] = settings_ui_scale_slider.value
	settings["high_contrast"] = settings_high_contrast_toggle.button_pressed
	match difficulty_option.selected:
		0:
			settings["difficulty"] = "easy"
		2:
			settings["difficulty"] = "hard"
		_:
			settings["difficulty"] = "normal"
	match performance_option.selected:
		0:
			settings["performance_mode"] = "quality"
		2:
			settings["performance_mode"] = "performance"
		_:
			settings["performance_mode"] = "balanced"
	profile["settings"] = settings
	_save_profile()
	_apply_master_volume_from_profile()
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
