extends Control

const GAME_RUNTIME_SCRIPT := preload("res://scripts/GameRuntime.gd")
const SAVE_MANAGER_SCRIPT := preload("res://scripts/SaveManager.gd")
const TELEMETRY_SCRIPT := preload("res://scripts/Telemetry.gd")
const CONCEPT_BG_PATH := "res://rift-master-concept-technical-ui-blueprint.svg"
const STUDIO_SPLASH_PATH := "res://assets/branding/code_maxx_studios_intro.svg"
const MENU_MUSIC_PATH := "res://assets/audio/music/menu_theme.wav"
const STUDIO_STING_PATH := "res://assets/audio/sfx/studio_sting.wav"
const MENU_UI_CLICK_PATH := "res://assets/audio/sfx/ui_click.wav"
const PANEL_TOP_PATH := "res://assets/artpack/ui/hud_top_panel.svg"
const PANEL_BOTTOM_PATH := "res://assets/artpack/ui/hud_bottom_panel.svg"
const BUTTON_PRIMARY_PATH := "res://assets/artpack/ui/button_primary.svg"
const BUTTON_SECONDARY_PATH := "res://assets/artpack/ui/button_secondary.svg"

var profile: Dictionary = {}
var runtime_config: Dictionary = {}
var active_runtime: GameRuntime
var telemetry_heartbeat_tick := 0.0

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
var studio_splash_texture: Texture2D
var menu_music_stream: AudioStream
var studio_sting_stream: AudioStream
var menu_ui_click_stream: AudioStream
var menu_music_player: AudioStreamPlayer
var menu_sfx_player: AudioStreamPlayer
var menu_music_tween: Tween
var menu_bg_texture_rect: TextureRect
var menu_bg_glow_overlay: ColorRect
var menu_panel_base_position := Vector2.ZERO
var intro_logo_base_position := Vector2.ZERO
var interactive_buttons: Array[Button] = []
var intro_overlay: Control
var intro_logo: TextureRect
var intro_tween: Tween
var intro_active := false


func _ready() -> void:
	_load_profile()
	_load_runtime_config()
	TELEMETRY_SCRIPT.configure(runtime_config.get("analytics", {}))
	var session_info: Dictionary = TELEMETRY_SCRIPT.start_app_session(profile)
	_load_visual_assets()
	_apply_master_volume_from_profile()
	_build_menu_ui()
	_setup_menu_audio()
	_build_intro_splash()
	_refresh_menu()
	if bool(session_info.get("dirty_shutdown_detected", false)) and status_label != null:
		status_label.text = "Recovered from an unexpected close. Continue is available."
		TELEMETRY_SCRIPT.log_event("menu_recovery_notice_shown", {
			"has_continue_snapshot": bool(profile.get("has_continue_snapshot", false))
		}, "warning")
	_play_intro_if_available()


func _load_profile() -> void:
	profile = SAVE_MANAGER_SCRIPT.load_profile()


func _load_runtime_config() -> void:
	var file := FileAccess.open("res://android_ui_state_config.json", FileAccess.READ)
	if file == null:
		runtime_config = {}
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		runtime_config = {}
		return
	runtime_config = parsed


func _save_profile() -> void:
	SAVE_MANAGER_SCRIPT.save_profile(profile)


func _load_visual_assets() -> void:
	concept_bg_texture = _load_texture_if_exists(CONCEPT_BG_PATH)
	studio_splash_texture = _load_texture_if_exists(STUDIO_SPLASH_PATH)
	panel_top_texture = _load_texture_if_exists(PANEL_TOP_PATH)
	panel_bottom_texture = _load_texture_if_exists(PANEL_BOTTOM_PATH)
	button_primary_texture = _load_texture_if_exists(BUTTON_PRIMARY_PATH)
	button_secondary_texture = _load_texture_if_exists(BUTTON_SECONDARY_PATH)
	menu_music_stream = _load_audio_stream_if_exists(MENU_MUSIC_PATH)
	studio_sting_stream = _load_audio_stream_if_exists(STUDIO_STING_PATH)
	menu_ui_click_stream = _load_audio_stream_if_exists(MENU_UI_CLICK_PATH)


func _load_texture_if_exists(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _load_audio_stream_if_exists(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream


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


func _process(_delta: float) -> void:
	telemetry_heartbeat_tick += _delta
	if telemetry_heartbeat_tick >= 8.0:
		telemetry_heartbeat_tick = 0.0
		TELEMETRY_SCRIPT.update_heartbeat(
			"menu",
			{
				"menu_visible": menu_panel != null and menu_panel.visible,
				"settings_visible": settings_panel != null and settings_panel.visible,
				"has_continue_snapshot": bool(profile.get("has_continue_snapshot", false))
			}
		)
	var t: float = float(Time.get_ticks_msec()) / 1000.0
	if menu_bg_texture_rect != null:
		var viewport_size := get_viewport_rect().size
		var drift := Vector2(sin(t * 0.16), cos(t * 0.13)) * 10.0
		menu_bg_texture_rect.position = drift - Vector2(40, 26)
		menu_bg_texture_rect.size = viewport_size + Vector2(80, 52)
	if menu_bg_glow_overlay != null:
		var glow: float = 0.18 + 0.06 * (0.5 + 0.5 * sin(t * 1.3))
		menu_bg_glow_overlay.color = Color(0.08, 0.18, 0.38, glow)
	if menu_panel != null and menu_panel.visible:
		menu_panel.position.y = menu_panel_base_position.y + sin(t * 0.95) * 4.0
	if title_label != null:
		title_label.modulate = Color(0.92 + 0.08 * (0.5 + 0.5 * sin(t * 2.2)), 0.98, 1.0, 1.0)
	if subtitle_label != null:
		subtitle_label.modulate = Color(0.82, 0.94 + 0.06 * (0.5 + 0.5 * sin(t * 1.8)), 1.0, 1.0)
	if intro_active and intro_logo != null:
		intro_logo.position.y = intro_logo_base_position.y + sin(t * 2.0) * 6.0


func _exit_tree() -> void:
	TELEMETRY_SCRIPT.mark_clean_shutdown("main_exit")


func _setup_menu_audio() -> void:
	menu_music_player = AudioStreamPlayer.new()
	menu_music_player.bus = "Master"
	add_child(menu_music_player)
	menu_music_player.stream = menu_music_stream
	menu_music_player.autoplay = false
	menu_music_player.volume_db = -20.0
	if menu_music_stream != null:
		menu_music_player.play()

	menu_sfx_player = AudioStreamPlayer.new()
	menu_sfx_player.bus = "Master"
	add_child(menu_sfx_player)
	_apply_menu_audio_mix()
	_fade_menu_music_to(_menu_music_target_db(), 0.65)


func _menu_music_target_db() -> float:
	var settings: Dictionary = profile.get("settings", {})
	var music_volume: float = float(settings.get("music_volume", 0.85))
	var adjusted: float = clamp(music_volume * 0.72, 0.0001, 1.0)
	return -80.0 if music_volume <= 0.0001 else linear_to_db(adjusted)


func _apply_menu_audio_mix() -> void:
	if menu_music_player != null:
		if menu_music_stream == null:
			menu_music_player.stop()
		elif not menu_music_player.playing:
			menu_music_player.play()
	if menu_sfx_player != null:
		var settings: Dictionary = profile.get("settings", {})
		var sfx_volume: float = float(settings.get("sfx_volume", 0.90))
		menu_sfx_player.volume_db = -80.0 if sfx_volume <= 0.0001 else linear_to_db(clamp(sfx_volume, 0.0001, 1.0))


func _fade_menu_music_to(target_db: float, duration: float) -> void:
	if menu_music_player == null:
		return
	if menu_music_tween != null:
		menu_music_tween.kill()
	menu_music_tween = create_tween()
	menu_music_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	menu_music_tween.tween_property(menu_music_player, "volume_db", target_db, duration)


func _play_menu_sfx(stream: AudioStream = null, pitch: float = 1.0) -> void:
	if menu_sfx_player == null:
		return
	var selected_stream: AudioStream = stream if stream != null else menu_ui_click_stream
	if selected_stream == null:
		return
	menu_sfx_player.pitch_scale = pitch
	menu_sfx_player.stream = selected_stream
	menu_sfx_player.play()


func _build_menu_ui() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	if concept_bg_texture != null:
		menu_bg_texture_rect = TextureRect.new()
		menu_bg_texture_rect.texture = concept_bg_texture
		menu_bg_texture_rect.set_anchors_preset(PRESET_FULL_RECT)
		menu_bg_texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
		menu_bg_texture_rect.modulate = Color(1.0, 1.0, 1.0, 0.40)
		menu_bg_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(menu_bg_texture_rect)

	var bg_overlay := ColorRect.new()
	bg_overlay.color = Color(0.03, 0.07, 0.15, 0.88)
	bg_overlay.set_anchors_preset(PRESET_FULL_RECT)
	bg_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_overlay)
	menu_bg_glow_overlay = ColorRect.new()
	menu_bg_glow_overlay.color = Color(0.08, 0.18, 0.38, 0.20)
	menu_bg_glow_overlay.set_anchors_preset(PRESET_FULL_RECT)
	menu_bg_glow_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(menu_bg_glow_overlay)

	menu_panel = Panel.new()
	menu_panel.size = Vector2(980, 640)
	menu_panel.position = Vector2(470, 180)
	menu_panel_base_position = menu_panel.position
	add_child(menu_panel)

	title_label = Label.new()
	title_label.text = "RIFT: THE BESTIARY PROTOCOL"
	title_label.position = Vector2(152, 34)
	title_label.add_theme_font_size_override("font_size", 44)
	menu_panel.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.text = "Open-world survival brawler by Code Maxx Studios"
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
	_register_interactive_button(new_run_button)
	menu_panel.add_child(new_run_button)

	continue_button = Button.new()
	continue_button.text = "Continue Run"
	continue_button.position = Vector2(365, 360)
	continue_button.size = Vector2(250, 62)
	continue_button.pressed.connect(_on_continue_pressed)
	_register_interactive_button(continue_button)
	menu_panel.add_child(continue_button)

	daily_reward_button = Button.new()
	daily_reward_button.text = "Claim Daily Reward"
	daily_reward_button.position = Vector2(365, 436)
	daily_reward_button.size = Vector2(250, 50)
	daily_reward_button.pressed.connect(_on_claim_daily_reward_pressed)
	_register_interactive_button(daily_reward_button)
	menu_panel.add_child(daily_reward_button)

	var settings_button := Button.new()
	settings_button.text = "Settings"
	settings_button.position = Vector2(640, 360)
	settings_button.size = Vector2(250, 62)
	settings_button.pressed.connect(_on_settings_pressed)
	_register_interactive_button(settings_button)
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
	studio_label.text = "Developer: Code Maxx Studios"
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
	_register_interactive_button(save_button)
	settings_panel.add_child(save_button)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.position = Vector2(380, 420)
	close_button.size = Vector2(200, 54)
	close_button.pressed.connect(_on_close_settings_pressed)
	_register_interactive_button(close_button)
	settings_panel.add_child(close_button)

	var replay_tutorial_button := Button.new()
	replay_tutorial_button.text = "Replay Tutorial Next Run"
	replay_tutorial_button.position = Vector2(222, 490)
	replay_tutorial_button.size = Vector2(276, 44)
	replay_tutorial_button.pressed.connect(_on_replay_tutorial_pressed)
	_register_interactive_button(replay_tutorial_button)
	settings_panel.add_child(replay_tutorial_button)


func _build_intro_splash() -> void:
	intro_overlay = Control.new()
	intro_overlay.set_anchors_preset(PRESET_FULL_RECT)
	intro_overlay.visible = false
	intro_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	intro_overlay.gui_input.connect(_on_intro_gui_input)
	add_child(intro_overlay)

	var splash_bg := ColorRect.new()
	splash_bg.set_anchors_preset(PRESET_FULL_RECT)
	splash_bg.color = Color(0.02, 0.05, 0.12, 0.97)
	splash_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_overlay.add_child(splash_bg)

	intro_logo = TextureRect.new()
	intro_logo.texture = studio_splash_texture
	intro_logo.position = Vector2(520, 170)
	intro_logo_base_position = intro_logo.position
	intro_logo.size = Vector2(880, 560)
	intro_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	intro_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	intro_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_overlay.add_child(intro_logo)

	var presents_label := Label.new()
	presents_label.text = "Presents"
	presents_label.position = Vector2(865, 84)
	presents_label.add_theme_font_size_override("font_size", 34)
	presents_label.add_theme_color_override("font_color", Color(0.76, 0.96, 1.0))
	presents_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_overlay.add_child(presents_label)

	var continue_hint := Label.new()
	continue_hint.text = "Tap to skip"
	continue_hint.position = Vector2(858, 980)
	continue_hint.add_theme_font_size_override("font_size", 20)
	continue_hint.add_theme_color_override("font_color", Color(0.70, 0.85, 1.0, 0.9))
	continue_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_overlay.add_child(continue_hint)


func _play_intro_if_available() -> void:
	if studio_splash_texture == null or intro_overlay == null:
		_fade_menu_music_to(_menu_music_target_db(), 0.45)
		return
	intro_active = true
	intro_overlay.visible = true
	intro_overlay.modulate = Color(1, 1, 1, 0)
	intro_logo.scale = Vector2(0.90, 0.90)
	intro_logo.position = intro_logo_base_position
	menu_panel.visible = false
	settings_panel.visible = false
	status_label.text = "Launching..."
	_play_menu_sfx(studio_sting_stream, 1.0)
	_fade_menu_music_to(-18.0, 0.20)

	if intro_tween != null:
		intro_tween.kill()
	intro_tween = create_tween()
	intro_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	intro_tween.tween_property(intro_overlay, "modulate:a", 1.0, 0.36)
	intro_tween.parallel().tween_property(intro_logo, "scale", Vector2(1.0, 1.0), 0.54)
	intro_tween.tween_interval(2.0)
	intro_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	intro_tween.tween_property(intro_overlay, "modulate:a", 0.0, 0.42)
	intro_tween.tween_callback(_finish_intro_splash)


func _on_intro_gui_input(event: InputEvent) -> void:
	if not intro_active:
		return
	if event is InputEventScreenTouch and event.pressed:
		_finish_intro_splash()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_finish_intro_splash()


func _finish_intro_splash() -> void:
	if not intro_active:
		return
	intro_active = false
	if intro_tween != null:
		intro_tween.kill()
		intro_tween = null
	if intro_overlay != null:
		intro_overlay.visible = false
	menu_panel.visible = true
	settings_panel.visible = false
	_fade_menu_music_to(_menu_music_target_db(), 0.45)
	_refresh_menu()


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


func _register_interactive_button(button: Button) -> void:
	interactive_buttons.append(button)
	button.mouse_entered.connect(_on_button_hover_entered.bind(button))
	button.mouse_exited.connect(_on_button_hover_exited.bind(button))
	button.button_down.connect(_on_button_down.bind(button))
	button.button_up.connect(_on_button_up.bind(button))
	button.pressed.connect(_on_button_pressed_feedback.bind(button))


func _tween_button_feedback(button: Button, scale_target: Vector2, modulate_target: Color, duration: float) -> void:
	var existing_tween: Variant = button.get_meta("feedback_tween", null)
	if existing_tween is Tween:
		(existing_tween as Tween).kill()
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", scale_target, duration)
	tween.parallel().tween_property(button, "modulate", modulate_target, duration)
	button.set_meta("feedback_tween", tween)


func _on_button_hover_entered(button: Button) -> void:
	_tween_button_feedback(button, Vector2(1.03, 1.03), Color(1.04, 1.04, 1.08, 1.0), 0.10)


func _on_button_hover_exited(button: Button) -> void:
	_tween_button_feedback(button, Vector2.ONE, Color(1, 1, 1, 1), 0.12)


func _on_button_down(button: Button) -> void:
	_tween_button_feedback(button, Vector2(0.97, 0.97), Color(0.95, 0.95, 1.0, 1.0), 0.06)


func _on_button_up(button: Button) -> void:
	_tween_button_feedback(button, Vector2.ONE, Color(1, 1, 1, 1), 0.10)


func _on_button_pressed_feedback(_button: Button) -> void:
	_play_menu_sfx(menu_ui_click_stream, randf_range(0.96, 1.05))


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
	profile_label.text = "Meta Lv %d (%d XP) | Runs: %d | Wins: %d | Best Wave: %d | Best Rank: %s | Best Score: %d\nDrones Defeated: %d | Elite Defeats: %d | Bestiary Pages: %d | Best Combo: x%.2f | Total Dashes: %d | Rift Bursts: %d" % [
		int(profile.get("meta_level", 1)),
		int(profile.get("meta_xp", 0)),
		int(profile.get("total_runs", 0)),
		int(profile.get("total_wins", 0)),
		int(profile.get("best_wave", 0)),
		String(profile.get("best_run_rank", "C")),
		int(profile.get("best_run_score", 0)),
		int(profile.get("total_drones_defeated", 0)),
		int(profile.get("total_elite_defeats", 0)),
		int(profile.get("total_bestiary_pages", 0)),
		float(profile.get("best_combo", 1.0)),
		int(profile.get("total_dash_uses", 0)),
		int(profile.get("total_rift_bursts", 0))
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
	TELEMETRY_SCRIPT.mark_runtime_started({
		"run_wave": int(runtime_profile.get("continue_snapshot", {}).get("wave_number", 0)) if use_continue_snapshot else 0,
		"run_difficulty": String(runtime_profile.get("settings", {}).get("difficulty", "normal")),
		"run_performance": String(runtime_profile.get("settings", {}).get("performance_mode", "balanced")),
		"use_continue": use_continue_snapshot
	})
	runtime.session_finished.connect(_on_runtime_session_finished)
	runtime.checkpoint_updated.connect(_on_runtime_checkpoint_updated)
	active_runtime = runtime
	add_child(runtime)
	_fade_menu_music_to(-36.0, 0.35)
	menu_panel.visible = false
	settings_panel.visible = false
	status_label.text = "Run in progress..."
	TELEMETRY_SCRIPT.log_event("runtime_launched_from_menu", {
		"use_continue": use_continue_snapshot
	})


func _on_runtime_session_finished(victory: bool, summary: Dictionary) -> void:
	var restart_requested := bool(summary.get("request_restart", false))
	TELEMETRY_SCRIPT.mark_runtime_finished({
		"victory": victory,
		"wave_reached": int(summary.get("wave_reached", 0)),
		"run_score": int(summary.get("run_score", 0)),
		"rank": String(summary.get("rank", "C"))
	})
	profile = SAVE_MANAGER_SCRIPT.apply_session_result(profile, summary)
	_save_profile()
	_refresh_menu()
	menu_panel.visible = true
	settings_panel.visible = false
	_apply_menu_audio_mix()
	_fade_menu_music_to(_menu_music_target_db(), 0.55)
	if active_runtime != null and is_instance_valid(active_runtime):
		active_runtime = null
	status_label.text = "Run complete: %s" % ("Victory" if victory else "Session ended")
	if restart_requested:
		TELEMETRY_SCRIPT.log_event("runtime_restart_requested", {
			"prior_victory": victory
		})
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
	settings_panel.modulate = Color(1, 1, 1, 0.0)
	settings_panel.scale = Vector2(0.96, 0.96)
	var reveal_tween := create_tween()
	reveal_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	reveal_tween.tween_property(settings_panel, "modulate:a", 1.0, 0.18)
	reveal_tween.parallel().tween_property(settings_panel, "scale", Vector2.ONE, 0.20)


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
	_apply_menu_audio_mix()
	_fade_menu_music_to(_menu_music_target_db(), 0.24)
	status_label.text = "Settings saved."
	TELEMETRY_SCRIPT.log_event("settings_saved", {
		"difficulty": String(settings.get("difficulty", "normal")),
		"performance_mode": String(settings.get("performance_mode", "balanced")),
		"show_perf_hud": bool(settings.get("show_perf_hud", false))
	})


func _on_close_settings_pressed() -> void:
	var hide_tween := create_tween()
	hide_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	hide_tween.tween_property(settings_panel, "modulate:a", 0.0, 0.14)
	hide_tween.parallel().tween_property(settings_panel, "scale", Vector2(0.97, 0.97), 0.14)
	hide_tween.tween_callback(func() -> void:
		settings_panel.visible = false
		settings_panel.modulate = Color(1, 1, 1, 1)
		settings_panel.scale = Vector2.ONE
	)


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
	TELEMETRY_SCRIPT.log_event("daily_reward_attempt", {
		"rewarded": bool(result.get("rewarded", false)),
		"streak": int(result.get("streak", profile.get("daily_streak", 0)))
	})
