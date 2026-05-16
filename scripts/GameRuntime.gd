extends Node2D
class_name GameRuntime

signal session_finished(victory: bool, summary: Dictionary)
signal checkpoint_updated(snapshot: Dictionary)
const FEEDBACK_BUS_SCRIPT := preload("res://scripts/FeedbackBus.gd")

enum PlayerState {
	NORMAL,
	EXHAUSTED,
	RHINO_CHARGE,
	SUPER_BEAST,
	RIFT_WEAVER
}

enum InputMode {
	ATTACK_MODE,
	EAT_MODE,
	RHINO_BOOST_MODE
}

const INVALID_TOUCH_ID := -1
const MOUSE_TOUCH_ID := 9001
const CONCEPT_BG_PATH := "res://rift-master-concept-technical-ui-blueprint.svg"
const ICON_PATH := "res://assets/icon.svg"
const PLAYER_SKIN_PATH := "res://assets/artpack/skins/player_cody.svg"
const ENEMY_DRONE_PATH := "res://assets/artpack/enemies/drone.svg"
const ENEMY_BRUTE_PATH := "res://assets/artpack/enemies/brute.svg"
const ENEMY_SPITTER_PATH := "res://assets/artpack/enemies/spitter.svg"
const BOSS_OVERLORD_PATH := "res://assets/artpack/enemies/boss_overlord_vex.svg"
const KEELEY_PORTRAIT_PATH := "res://assets/artpack/companions/keeley_portrait.svg"
const ANNALIZE_PORTRAIT_PATH := "res://assets/artpack/companions/annalize_portrait.svg"
const HOTBAR_ICON_PATHS := [
	"res://assets/artpack/icons/pulse_tool.svg",
	"res://assets/artpack/icons/titan_hammer.svg",
	"res://assets/artpack/icons/glow_berry.svg",
	"res://assets/artpack/icons/arc_blaster.svg",
	"res://assets/artpack/icons/med_snack.svg"
]
const HUD_TOP_PANEL_PATH := "res://assets/artpack/ui/hud_top_panel.svg"
const HUD_BOTTOM_PANEL_PATH := "res://assets/artpack/ui/hud_bottom_panel.svg"
const BUTTON_PRIMARY_PATH := "res://assets/artpack/ui/button_primary.svg"
const BUTTON_SECONDARY_PATH := "res://assets/artpack/ui/button_secondary.svg"
const COMPANION_FRAME_PATH := "res://assets/artpack/ui/companion_frame.svg"
const JOYSTICK_MOVE_BASE_PATH := "res://assets/artpack/ui/joystick_move_base.svg"
const JOYSTICK_MOVE_KNOB_PATH := "res://assets/artpack/ui/joystick_move_knob.svg"
const JOYSTICK_AIM_BASE_PATH := "res://assets/artpack/ui/joystick_aim_base.svg"
const JOYSTICK_AIM_KNOB_PATH := "res://assets/artpack/ui/joystick_aim_knob.svg"
const BIOME_BG_PATHS := [
	"res://assets/artpack/backgrounds/biome_scrap_dunes.svg",
	"res://assets/artpack/backgrounds/biome_whispering_archives.svg",
	"res://assets/artpack/backgrounds/biome_plasma_crater.svg"
]
const BIOME_MUSIC_PATHS := [
	"res://assets/audio/music/biome_scrap_dunes.wav",
	"res://assets/audio/music/biome_whispering_archives.wav",
	"res://assets/audio/music/biome_plasma_crater.wav"
]
const SFX_PATHS := {
	"attack": "res://assets/audio/sfx/attack.wav",
	"hit": "res://assets/audio/sfx/hit.wav",
	"dash": "res://assets/audio/sfx/dash.wav",
	"enemy_down": "res://assets/audio/sfx/enemy_down.wav",
	"boss_alarm": "res://assets/audio/sfx/boss_alarm.wav",
	"ui_click": "res://assets/audio/sfx/ui_click.wav"
}
const MAX_ACTIVE_ENEMIES := 56
const MAX_ACTIVE_PROJECTILES := 36
const MAX_ACTIVE_VFX_PARTICLES := 180

var profile: Dictionary = {}
var config: Dictionary = {}

var run_elapsed_seconds := 0.0
var checkpoint_emit_tick := 0.0
var game_ended := false
var is_soft_paused := false
var pending_result: Dictionary = {}

var player_state: int = PlayerState.NORMAL
var input_mode: int = InputMode.ATTACK_MODE
var companion_id := "keeley"
var keeley_dna_upgrade := false

var health := 100.0
var hunger := 100.0
var max_health := 100.0
var max_hunger := 100.0
var player_lives := 3
var max_lives := 3

var base_move_speed := 320.0
var state_move_speed_multiplier := 1.0
var loadout_move_speed_multiplier := 1.0
var player_position := Vector2(960, 540)
var player_direction := Vector2.RIGHT

var left_touch_id := INVALID_TOUCH_ID
var right_touch_id := INVALID_TOUCH_ID
var left_origin := Vector2.ZERO
var right_origin := Vector2.ZERO
var left_vector := Vector2.ZERO
var right_vector := Vector2.ZERO
var right_touch_start := Vector2.ZERO
var right_touch_start_msec := 0

var left_dead_zone_px := 100.0
var right_dead_zone_px := 100.0
var configured_left_dead_zone_px := 100.0
var configured_right_dead_zone_px := 100.0
var left_spawn_rect := Rect2()
var right_spawn_rect := Rect2()
var viewport_size := Vector2.ZERO

var selected_hotbar_index := 0
var hotbar_items: Array[Dictionary] = [
	{"label": "Pulse Tool", "tag": "tool"},
	{"label": "Titan Hammer", "tag": "heavy_weapon"},
	{"label": "Glow Berry", "tag": "food"},
	{"label": "Arc Blaster", "tag": "weapon"},
	{"label": "Med Snack", "tag": "food"}
]

var inventory: Dictionary = {
	"human_scrap": 15,
	"alien_crystals": 8,
	"star_melons": 4,
	"glow_berries": 6
}
var crafted_items: Dictionary = {
	"pulse_blade": 0,
	"arc_launcher": 0,
	"vex_piercer_cannon": 0
}
var recipes: Array[Dictionary] = [
	{"id": "pulse_blade", "name": "Pulse Blade", "scrap": 5, "crystal": 2, "unlock_level": 1},
	{"id": "arc_launcher", "name": "Arc Launcher", "scrap": 8, "crystal": 4, "unlock_level": 2},
	{"id": "vex_piercer_cannon", "name": "Vex-Piercer Cannon", "scrap": 12, "crystal": 8, "unlock_level": 4}
]
var recipe_index := 0

var objectives: Array[Dictionary] = [
	{"key": "collect", "label": "Collect resources", "progress": 0, "target": 30, "reward_xp": 40, "completed": false},
	{"key": "defeat", "label": "Defeat Vexian drones", "progress": 0, "target": 24, "reward_xp": 45, "completed": false},
	{"key": "craft", "label": "Craft weapons", "progress": 0, "target": 4, "reward_xp": 60, "completed": false},
	{"key": "rhino", "label": "Use Rhino Charge", "progress": 0, "target": 2, "reward_xp": 35, "completed": false}
]

var player_level := 1
var player_xp := 0
var skins_unlocked := 1

var bestiary_pages := 0
var bestiary_entries: Dictionary = {}
var secret_walls_broken := 0
var drones_defeated := 0
var pages_collected_this_run := 0

var wave_number := 0
var wave_active := false
var wave_spawn_remaining := 0
var wave_spawn_tick := 0.0
var wave_wait_tick := 1.6
var wave_base_enemies := 4
var wave_enemy_growth := 2
var wave_spawn_radius := 430.0
var enemy_touch_damage_tick := 0.0
var enemy_contact_cooldown_seconds := 0.65
var active_enemies: Array[Dictionary] = []
var next_enemy_id := 1

var boss_active := false
var boss: Dictionary = {}
var boss_attack_tick := 0.0
var boss_spawned := false
var boss_base_health := 1800.0
var boss_health_per_wave := 80.0
var boss_contact_damage := 16.0
var boss_shockwave_damage := 18.0

var goal_boss_unlock_min_wave := 8
var goal_boss_unlock_pages := 6
var goal_boss_unlock_entries := 24

var rhino_time_left := 0.0
var attack_cooldown := 0.0
var companion_tick := 0.0
var passive_scavenge_tick := 0.0
var dash_cooldown_remaining := 0.0
var dash_time_left := 0.0
var dash_direction := Vector2.RIGHT
var combo_streak := 0
var combo_multiplier := 1.0
var combo_decay_time_left := 0.0
var max_combo_reached := 1.0
var dash_uses_this_run := 0
var enemy_projectiles: Array[Dictionary] = []
var spitter_shot_tick := 0.0
var dash_cooldown_seconds := 2.4
var dash_duration_seconds := 0.22
var combo_timeout_seconds := 4.0
var spitter_projectile_speed := 420.0
var spitter_projectile_damage := 8.0
var difficulty_name := "normal"
var enemy_health_multiplier := 1.0
var enemy_damage_multiplier := 1.0
var enemy_spawn_multiplier := 1.0
var enemy_speed_multiplier := 1.0
var loot_gain_multiplier := 1.0
var biome_names := PackedStringArray(["Scrap Dunes", "Whispering Archives", "Plasma Crater"])
var current_biome_index := 0

var progression_base_level_xp := 70
var progression_level_xp_growth := 28
var progression_health_gain_per_level := 8.0
var progression_hunger_gain_per_level := 6.0

var hud_root: Control
var health_bar: ProgressBar
var hunger_bar: ProgressBar
var status_label: Label
var state_label: Label
var biome_label: Label
var wave_label: Label
var boss_label: Label
var combo_label: Label
var dash_label: Label
var perf_metrics_label: Label
var companion_label: Label
var loot_label: Label
var rhino_timer_label: Label
var inventory_label: Label
var quest_label: Label
var progression_label: Label
var action_button: Button
var dash_button: Button
var rhino_button: Button
var travel_biome_button: Button
var hotbar_container: HBoxContainer
var hotbar_buttons: Array[Button] = []
var companion_select: OptionButton
var keeley_upgrade_toggle: CheckButton
var recipe_select: OptionButton
var craft_button: Button
var scavenge_button: Button
var gain_page_button: Button
var pause_button: Button
var hotbar_title: Label
var left_stick_base: Panel
var left_stick_knob: Panel
var right_stick_base: Panel
var right_stick_knob: Panel
var companion_portrait_frame: Panel
var companion_portrait: TextureRect

var pause_panel: Panel
var pause_title: Label
var end_panel: Panel
var end_title: Label
var end_subtitle: Label
var tutorial_panel: Panel
var tutorial_body: Label
var tutorial_index := 0
var tutorial_completed_this_session := false
var tutorial_enabled := true
var tutorial_allow_skip := true
var tutorial_steps := [
	"Move with the left stick. Aim and attack with the right stick.",
	"Collect scrap, crystals, and food. Food restores energy when using EAT mode.",
	"Craft stronger weapons and finish objectives to trigger the Titan Protocol.",
	"Activate Rhino Charge for burst damage and wall-smashing momentum.",
	"Defeat Overlord Vex to complete the Rift Weaver finale."
]

var feedback_bus: FeedbackBus
var feedback_overlay: ColorRect
var feedback_flash_alpha := 0.0
var feedback_flash_decay := 0.0
var ui_scale := 1.0
var high_contrast_mode := false
var master_volume := 0.85
var music_volume := 0.85
var sfx_volume := 0.90
var performance_mode := "balanced"
var show_perf_hud := false
var max_active_enemies := MAX_ACTIVE_ENEMIES
var max_active_projectiles := MAX_ACTIVE_PROJECTILES
var max_active_vfx_particles := MAX_ACTIVE_VFX_PARTICLES
var ambient_overlay_base_alpha := 0.08
var concept_bg_texture: Texture2D
var player_sprite_texture: Texture2D
var enemy_drone_texture: Texture2D
var enemy_brute_texture: Texture2D
var enemy_spitter_texture: Texture2D
var boss_sprite_texture: Texture2D
var biome_bg_textures: Array = []
var keeley_portrait_texture: Texture2D
var annalize_portrait_texture: Texture2D
var hotbar_icon_textures: Array = []
var hud_top_panel_texture: Texture2D
var hud_bottom_panel_texture: Texture2D
var ui_button_primary_texture: Texture2D
var ui_button_secondary_texture: Texture2D
var ui_companion_frame_texture: Texture2D
var ui_move_base_texture: Texture2D
var ui_move_knob_texture: Texture2D
var ui_aim_base_texture: Texture2D
var ui_aim_knob_texture: Texture2D
var biome_music_streams: Array = []
var sfx_streams: Dictionary = {}
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var vfx_particles: Array[Dictionary] = []
var top_hud_panel: Panel
var bottom_hud_panel: Panel


func set_profile(input_profile: Dictionary) -> void:
	profile = input_profile.duplicate(true)


func _ready() -> void:
	randomize()
	_load_config()
	_apply_profile_bonuses()
	_load_visual_assets()
	_setup_audio_players()
	_setup_feedback_bus()
	_build_hud()
	_apply_hud_visual_mode()
	_recalculate_input_regions()
	player_position = get_viewport_rect().size * 0.5
	status_label.text = "Run started. Track, craft, survive."
	_apply_hotbar_context_rules()

	if bool(profile.get("has_continue_snapshot", false)):
		_load_snapshot(profile.get("continue_snapshot", {}))
		status_label.text = "Continue run loaded."
	else:
		_start_next_wave()

	if tutorial_enabled and not bool(profile.get("tutorial_completed", false)):
		_show_tutorial_step(0)
	else:
		tutorial_completed_this_session = true

	_update_hud()


func _load_visual_assets() -> void:
	if ResourceLoader.exists(CONCEPT_BG_PATH):
		concept_bg_texture = load(CONCEPT_BG_PATH) as Texture2D
	player_sprite_texture = _load_texture_if_exists(PLAYER_SKIN_PATH)
	if player_sprite_texture == null and ResourceLoader.exists(ICON_PATH):
		player_sprite_texture = load(ICON_PATH) as Texture2D

	enemy_drone_texture = _load_texture_if_exists(ENEMY_DRONE_PATH)
	enemy_brute_texture = _load_texture_if_exists(ENEMY_BRUTE_PATH)
	enemy_spitter_texture = _load_texture_if_exists(ENEMY_SPITTER_PATH)
	boss_sprite_texture = _load_texture_if_exists(BOSS_OVERLORD_PATH)

	if enemy_drone_texture == null:
		enemy_drone_texture = player_sprite_texture
	if enemy_brute_texture == null:
		enemy_brute_texture = enemy_drone_texture
	if enemy_spitter_texture == null:
		enemy_spitter_texture = enemy_drone_texture
	if boss_sprite_texture == null:
		boss_sprite_texture = enemy_brute_texture

	biome_bg_textures.clear()
	for path in BIOME_BG_PATHS:
		var biome_texture := _load_texture_if_exists(path)
		if biome_texture == null:
			biome_texture = concept_bg_texture
		biome_bg_textures.append(biome_texture)

	keeley_portrait_texture = _load_texture_if_exists(KEELEY_PORTRAIT_PATH)
	annalize_portrait_texture = _load_texture_if_exists(ANNALIZE_PORTRAIT_PATH)
	hud_top_panel_texture = _load_texture_if_exists(HUD_TOP_PANEL_PATH)
	hud_bottom_panel_texture = _load_texture_if_exists(HUD_BOTTOM_PANEL_PATH)
	ui_button_primary_texture = _load_texture_if_exists(BUTTON_PRIMARY_PATH)
	ui_button_secondary_texture = _load_texture_if_exists(BUTTON_SECONDARY_PATH)
	ui_companion_frame_texture = _load_texture_if_exists(COMPANION_FRAME_PATH)
	ui_move_base_texture = _load_texture_if_exists(JOYSTICK_MOVE_BASE_PATH)
	ui_move_knob_texture = _load_texture_if_exists(JOYSTICK_MOVE_KNOB_PATH)
	ui_aim_base_texture = _load_texture_if_exists(JOYSTICK_AIM_BASE_PATH)
	ui_aim_knob_texture = _load_texture_if_exists(JOYSTICK_AIM_KNOB_PATH)
	_load_hotbar_icon_textures()
	_load_audio_streams()


func _load_texture_if_exists(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _load_hotbar_icon_textures() -> void:
	hotbar_icon_textures.clear()
	for path in HOTBAR_ICON_PATHS:
		var icon_texture: Texture2D = _load_texture_if_exists(path)
		hotbar_icon_textures.append(icon_texture)


func _load_audio_streams() -> void:
	biome_music_streams.clear()
	for path in BIOME_MUSIC_PATHS:
		biome_music_streams.append(_load_audio_stream_if_exists(path))
	sfx_streams.clear()
	for key in SFX_PATHS.keys():
		var stream: AudioStream = _load_audio_stream_if_exists(String(SFX_PATHS[key]))
		sfx_streams[key] = stream


func _load_audio_stream_if_exists(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream


func _setup_audio_players() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "Master"
	add_child(sfx_player)

	_apply_audio_mix()
	_update_biome_music(true)


func _apply_audio_mix() -> void:
	_apply_master_volume()
	if music_player != null:
		music_player.volume_db = -80.0 if music_volume <= 0.0001 else linear_to_db(clamp(music_volume, 0.0001, 1.0))
	if sfx_player != null:
		sfx_player.volume_db = -80.0 if sfx_volume <= 0.0001 else linear_to_db(clamp(sfx_volume, 0.0001, 1.0))


func _apply_master_volume() -> void:
	var bus_index := AudioServer.get_bus_index("Master")
	if bus_index < 0:
		return
	if master_volume <= 0.0001:
		AudioServer.set_bus_volume_db(bus_index, -80.0)
	else:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(clamp(master_volume, 0.0001, 1.0)))


func _play_sfx(name: String) -> void:
	if sfx_player == null:
		return
	var stream := sfx_streams.get(name, null) as AudioStream
	if stream == null:
		return
	sfx_player.stream = stream
	sfx_player.play()


func _update_biome_music(force_restart: bool = false) -> void:
	if music_player == null:
		return
	if current_biome_index < 0 or current_biome_index >= biome_music_streams.size():
		return
	var desired_stream: AudioStream = biome_music_streams[current_biome_index]
	if desired_stream == null:
		return
	if not force_restart and music_player.stream == desired_stream and music_player.playing:
		return
	music_player.stream = desired_stream
	music_player.play()


func _texture_for_enemy_type(enemy_type: String) -> Texture2D:
	match enemy_type:
		"brute":
			return enemy_brute_texture
		"spitter":
			return enemy_spitter_texture
		_:
			return enemy_drone_texture


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_recalculate_input_regions()


func _input(event: InputEvent) -> void:
	if game_ended:
		return
	if is_soft_paused:
		return

	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		_on_touch(touch_event.index, touch_event.pressed, touch_event.position)
	elif event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		_on_drag(drag_event.index, drag_event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_button := event as InputEventMouseButton
		_on_touch(MOUSE_TOUCH_ID, mouse_button.pressed, mouse_button.position)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_motion := event as InputEventMouseMotion
		_on_drag(MOUSE_TOUCH_ID, mouse_motion.position)


func _process(delta: float) -> void:
	if viewport_size != get_viewport_rect().size:
		_recalculate_input_regions()

	if game_ended:
		_update_feedback_overlay(delta)
		_update_vfx(delta)
		_update_hud()
		queue_redraw()
		return

	if is_soft_paused:
		_update_feedback_overlay(delta)
		_update_vfx(delta)
		_update_hud()
		queue_redraw()
		return

	run_elapsed_seconds += delta

	_update_survival(delta)
	_update_player_state(delta)
	_update_dash_and_combo(delta)
	_apply_hotbar_context_rules()
	_update_movement(delta)
	_update_combat(delta)
	_update_companion_logic(delta)
	_update_wave_system(delta)
	_update_boss_system(delta)
	_update_enemy_projectiles(delta)
	_update_passive_scavenge(delta)
	_update_enemy_contacts(delta)
	_check_run_completion()
	_update_checkpoint_emitter(delta)
	_update_feedback_overlay(delta)
	_update_vfx(delta)
	_update_hud()
	queue_redraw()


func _draw() -> void:
	var screen_size := get_viewport_rect().size
	var bg_color := Color("#0b1022")
	var pulse := 0.70 + 0.30 * (0.5 + 0.5 * sin(Time.get_ticks_msec() / 420.0))
	if high_contrast_mode:
		bg_color = Color("#05070f")

	var biome_texture: Texture2D = null
	if current_biome_index >= 0 and current_biome_index < biome_bg_textures.size():
		biome_texture = biome_bg_textures[current_biome_index]
	if biome_texture != null:
		draw_texture_rect(biome_texture, Rect2(Vector2.ZERO, screen_size), false, Color(1, 1, 1, 0.90))
		if concept_bg_texture != null and performance_mode != "performance":
			draw_texture_rect(concept_bg_texture, Rect2(Vector2.ZERO, screen_size), false, Color(1, 1, 1, 0.14))
		draw_rect(Rect2(Vector2.ZERO, screen_size), Color(bg_color.r, bg_color.g, bg_color.b, 0.44))
	elif concept_bg_texture != null:
		draw_texture_rect(concept_bg_texture, Rect2(Vector2.ZERO, screen_size), false, Color(1, 1, 1, 0.42))
		draw_rect(Rect2(Vector2.ZERO, screen_size), Color(bg_color.r, bg_color.g, bg_color.b, 0.60))
	else:
		draw_rect(Rect2(Vector2.ZERO, screen_size), bg_color)
	var ambient_alpha := ambient_overlay_base_alpha
	if performance_mode != "performance":
		ambient_alpha += 0.04 * pulse
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0.04, 0.18, 0.32, ambient_alpha))

	# Fixed thumb guides make touch zones obvious on tablets.
	var left_hint_center := Vector2(screen_size.x * 0.16, screen_size.y * 0.82)
	var right_hint_center := Vector2(screen_size.x * 0.84, screen_size.y * 0.82)
	if performance_mode != "performance":
		draw_circle(left_hint_center, 66, Color(0.27, 0.9, 1.0, 0.12))
		draw_circle(left_hint_center, 26, Color(0.27, 0.9, 1.0, 0.18))
		draw_circle(right_hint_center, 74, Color(0.80, 0.55, 1.0, 0.12))
		draw_circle(right_hint_center, 26, Color(0.80, 0.55, 1.0, 0.18))

	var dead_zone_alpha := 0.08 if not high_contrast_mode else 0.20
	draw_rect(Rect2(0, 0, left_dead_zone_px, screen_size.y), Color(0.30, 0.76, 1.0, dead_zone_alpha))
	draw_rect(Rect2(screen_size.x - right_dead_zone_px, 0, right_dead_zone_px, screen_size.y), Color(0.85, 0.50, 1.0, dead_zone_alpha))
	if performance_mode != "performance":
		draw_rect(left_spawn_rect, Color(0.15, 0.8, 1.0, 0.06), true)
		draw_rect(right_spawn_rect, Color(0.66, 0.42, 1.0, 0.06), true)
	draw_rect(Rect2(0, 70, screen_size.x, 8), Color(0.26, 0.85, 1.0, 0.28))

	var player_color := Color("#76efff")
	if player_state == PlayerState.EXHAUSTED:
		player_color = Color("#ff8db1")
	elif player_state == PlayerState.RHINO_CHARGE:
		player_color = Color("#8af7ff")
		draw_circle(player_position, 56, Color(0.42, 0.49, 1.0, 0.35))
		draw_circle(player_position, 76, Color(0.33, 0.82, 1.0, 0.2))
	if dash_time_left > 0.0:
		draw_circle(player_position, 64, Color(0.86, 0.96, 1.0, 0.24))
		draw_circle(player_position, 84, Color(0.70, 0.88, 1.0, 0.16))
	if player_sprite_texture != null:
		var player_size := Vector2(96, 96)
		draw_texture_rect(player_sprite_texture, Rect2(player_position - player_size * 0.5, player_size), false, player_color)
	else:
		draw_circle(player_position, 30, player_color)
	draw_line(player_position, player_position + player_direction * 44, Color("#d8fbff"), 4.0)

	for enemy in active_enemies:
		var enemy_position: Vector2 = enemy.get("position", Vector2.ZERO)
		var enemy_hp: float = enemy.get("hp", 1.0)
		var enemy_max_hp: float = enemy.get("max_hp", 1.0)
		var enemy_type: String = enemy.get("type", "drone")
		var enemy_color := Color("#bc7bff")
		if enemy_type == "brute":
			enemy_color = Color("#ff8f89")
		elif enemy_type == "spitter":
			enemy_color = Color("#8fffb4")
		var enemy_texture := _texture_for_enemy_type(enemy_type)
		if enemy_texture != null:
			var enemy_size := Vector2(50, 50)
			if enemy_type == "brute":
				enemy_size = Vector2(62, 62)
			draw_texture_rect(enemy_texture, Rect2(enemy_position - enemy_size * 0.5, enemy_size), false, enemy_color)
		else:
			draw_circle(enemy_position, 16, enemy_color)
		var hp_ratio: float = clamp(enemy_hp / max(enemy_max_hp, 0.001), 0.0, 1.0)
		draw_rect(Rect2(enemy_position.x - 17, enemy_position.y - 28, 34, 4), Color(0.08, 0.08, 0.2, 1))
		draw_rect(Rect2(enemy_position.x - 17, enemy_position.y - 28, 34 * hp_ratio, 4), Color("#69f2b0"))

	for projectile in enemy_projectiles:
		var projectile_position: Vector2 = projectile.get("position", Vector2.ZERO)
		var projectile_velocity: Vector2 = projectile.get("velocity", Vector2.ZERO)
		var tail := projectile_position - projectile_velocity.normalized() * 18.0
		draw_line(tail, projectile_position, Color(0.46, 1.0, 0.88, 0.75), 4.0)
		draw_circle(projectile_position, 8.0, Color(0.58, 1.0, 0.90, 0.94))

	for particle in vfx_particles:
		var particle_pos: Vector2 = particle.get("position", Vector2.ZERO)
		var particle_color: Color = particle.get("color", Color.WHITE)
		var particle_ttl: float = particle.get("ttl", 0.0)
		var particle_total_ttl: float = max(0.001, float(particle.get("total_ttl", 0.001)))
		var particle_size: float = particle.get("size", 4.0)
		var fade := clamp(particle_ttl / particle_total_ttl, 0.0, 1.0)
		draw_circle(particle_pos, particle_size * fade, Color(particle_color.r, particle_color.g, particle_color.b, particle_color.a * fade))

	if boss_active:
		var boss_position: Vector2 = boss.get("position", Vector2.ZERO)
		if boss_sprite_texture != null:
			var boss_size := Vector2(136, 136)
			draw_texture_rect(boss_sprite_texture, Rect2(boss_position - boss_size * 0.5, boss_size), false, Color("#ff6f95"))
		else:
			draw_circle(boss_position, 46, Color("#ff6f95"))
		draw_circle(boss_position, 66, Color(0.9, 0.2, 0.4, 0.18))
		var boss_hp := float(boss.get("hp", 1.0))
		var boss_max_hp := float(boss.get("max_hp", 1.0))
		var boss_ratio: float = clamp(boss_hp / max(boss_max_hp, 0.001), 0.0, 1.0)
		draw_rect(Rect2(screen_size.x * 0.20, 86, screen_size.x * 0.60, 14), Color(0.07, 0.05, 0.12, 1))
		draw_rect(Rect2(screen_size.x * 0.20, 86, screen_size.x * 0.60 * boss_ratio, 14), Color("#ff6f95"))
		draw_rect(Rect2(screen_size.x * 0.20, 84, screen_size.x * 0.60 * pulse * boss_ratio, 2), Color(1.0, 0.84, 0.94, 0.86))


func _load_config() -> void:
	var file := FileAccess.open("res://android_ui_state_config.json", FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	config = parsed

	var input_layout: Dictionary = config.get("inputLayout", {})
	var deadzones: Dictionary = input_layout.get("edgeDeadZonesPx", {})
	configured_left_dead_zone_px = float(deadzones.get("left", configured_left_dead_zone_px))
	configured_right_dead_zone_px = float(deadzones.get("right", configured_right_dead_zone_px))
	left_dead_zone_px = configured_left_dead_zone_px
	right_dead_zone_px = configured_right_dead_zone_px

	var wave_combat: Dictionary = config.get("waveCombat", {})
	wave_base_enemies = int(wave_combat.get("baseWaveEnemies", wave_base_enemies))
	wave_enemy_growth = int(wave_combat.get("waveEnemyGrowth", wave_enemy_growth))
	wave_spawn_radius = float(wave_combat.get("spawnRadiusPx", wave_spawn_radius))
	enemy_contact_cooldown_seconds = float(wave_combat.get("contactDamageCooldownSeconds", enemy_contact_cooldown_seconds))

	var progression: Dictionary = config.get("progression", {})
	progression_base_level_xp = int(progression.get("baseLevelXp", progression_base_level_xp))
	progression_level_xp_growth = int(progression.get("levelXpGrowth", progression_level_xp_growth))
	progression_health_gain_per_level = float(progression.get("healthGainPerLevel", progression_health_gain_per_level))
	progression_hunger_gain_per_level = float(progression.get("hungerGainPerLevel", progression_hunger_gain_per_level))

	var run_goals: Dictionary = config.get("runGoals", {})
	goal_boss_unlock_min_wave = int(run_goals.get("bossUnlockMinWave", goal_boss_unlock_min_wave))
	goal_boss_unlock_pages = int(run_goals.get("bossUnlockBestiaryPages", goal_boss_unlock_pages))
	goal_boss_unlock_entries = int(run_goals.get("bossUnlockBestiaryEntries", goal_boss_unlock_entries))

	var boss_config: Dictionary = config.get("boss", {})
	boss_base_health = float(boss_config.get("baseHealth", boss_base_health))
	boss_health_per_wave = float(boss_config.get("healthPerWave", boss_health_per_wave))
	boss_contact_damage = float(boss_config.get("contactDamage", boss_contact_damage))
	boss_shockwave_damage = float(boss_config.get("shockwaveDamage", boss_shockwave_damage))

	var combat_polish: Dictionary = config.get("combatPolish", {})
	dash_cooldown_seconds = float(combat_polish.get("dashCooldownSeconds", dash_cooldown_seconds))
	dash_duration_seconds = float(combat_polish.get("dashDurationSeconds", dash_duration_seconds))
	combo_timeout_seconds = float(combat_polish.get("comboTimeoutSeconds", combo_timeout_seconds))
	spitter_projectile_speed = float(combat_polish.get("spitterProjectileSpeed", spitter_projectile_speed))
	spitter_projectile_damage = float(combat_polish.get("spitterProjectileDamage", spitter_projectile_damage))

	var tutorial_config: Dictionary = config.get("tutorial", {})
	tutorial_enabled = bool(tutorial_config.get("enabled", tutorial_enabled))
	tutorial_allow_skip = bool(tutorial_config.get("allowSkip", tutorial_allow_skip))
	var steps_override = tutorial_config.get("steps", [])
	if typeof(steps_override) == TYPE_ARRAY and steps_override.size() > 0:
		var converted: Array = []
		for step in steps_override:
			converted.append(String(step))
		tutorial_steps = converted

	var crafting: Dictionary = config.get("crafting", {})
	var recipe_overrides = crafting.get("recipes", [])
	if typeof(recipe_overrides) == TYPE_ARRAY:
		for entry in recipe_overrides:
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var override_recipe: Dictionary = entry
			var recipe_id := String(override_recipe.get("id", ""))
			for i in recipes.size():
				if String(recipes[i].get("id", "")) != recipe_id:
					continue
				recipes[i]["scrap"] = int(override_recipe.get("scrap", recipes[i].get("scrap", 0)))
				recipes[i]["crystal"] = int(override_recipe.get("crystal", recipes[i].get("crystal", 0)))
				recipes[i]["unlock_level"] = int(override_recipe.get("unlockLevel", recipes[i].get("unlock_level", 1)))


func _apply_profile_bonuses() -> void:
	var meta_level := int(profile.get("meta_level", 1))
	player_level = maxi(1, meta_level)
	skins_unlocked = maxi(1, int(profile.get("unlocked_skins", 1)))
	max_health += float(meta_level - 1) * 4.0
	max_hunger += float(meta_level - 1) * 3.0
	health = max_health
	hunger = max_hunger

	var bank: Dictionary = profile.get("resources_bank", {})
	inventory["human_scrap"] = int(inventory.get("human_scrap", 0)) + int(bank.get("human_scrap", 0))
	inventory["alien_crystals"] = int(inventory.get("alien_crystals", 0)) + int(bank.get("alien_crystals", 0))

	var settings: Dictionary = profile.get("settings", {})
	var difficulty := String(settings.get("difficulty", "normal"))
	difficulty_name = difficulty
	ui_scale = float(settings.get("ui_scale", 1.0))
	high_contrast_mode = bool(settings.get("high_contrast", false))
	master_volume = float(settings.get("master_volume", 0.85))
	music_volume = float(settings.get("music_volume", 0.85))
	sfx_volume = float(settings.get("sfx_volume", 0.90))
	performance_mode = String(settings.get("performance_mode", "balanced"))
	show_perf_hud = bool(settings.get("show_perf_hud", false))
	enemy_health_multiplier = 1.0
	enemy_damage_multiplier = 1.0
	enemy_spawn_multiplier = 1.0
	enemy_speed_multiplier = 1.0
	loot_gain_multiplier = 1.0
	max_active_enemies = MAX_ACTIVE_ENEMIES
	max_active_projectiles = MAX_ACTIVE_PROJECTILES
	max_active_vfx_particles = MAX_ACTIVE_VFX_PARTICLES
	ambient_overlay_base_alpha = 0.08
	if difficulty == "easy":
		player_lives = 4
		max_lives = 4
		enemy_health_multiplier = 0.86
		enemy_damage_multiplier = 0.78
		enemy_spawn_multiplier = 0.84
		enemy_speed_multiplier = 0.93
		loot_gain_multiplier = 1.18
	elif difficulty == "hard":
		player_lives = 2
		max_lives = 2
		enemy_health_multiplier = 1.22
		enemy_damage_multiplier = 1.34
		enemy_spawn_multiplier = 1.16
		enemy_speed_multiplier = 1.08
		loot_gain_multiplier = 0.90

	match performance_mode:
		"quality":
			max_active_enemies = 64
			max_active_projectiles = 48
			max_active_vfx_particles = 260
			ambient_overlay_base_alpha = 0.10
		"performance":
			max_active_enemies = 44
			max_active_projectiles = 24
			max_active_vfx_particles = 110
			ambient_overlay_base_alpha = 0.05
		_:
			max_active_enemies = MAX_ACTIVE_ENEMIES
			max_active_projectiles = MAX_ACTIVE_PROJECTILES
			max_active_vfx_particles = MAX_ACTIVE_VFX_PARTICLES
			ambient_overlay_base_alpha = 0.08


func _setup_feedback_bus() -> void:
	feedback_bus = FEEDBACK_BUS_SCRIPT.new()
	add_child(feedback_bus)
	var settings: Dictionary = profile.get("settings", {})
	var feedback_defaults: Dictionary = config.get("feedback", {})
	if not settings.has("vibration"):
		settings["vibration"] = bool(feedback_defaults.get("vibrationEnabledDefault", true))
	if not settings.has("show_hit_flash"):
		settings["show_hit_flash"] = bool(feedback_defaults.get("hitFlashEnabledDefault", true))
	feedback_bus.configure_from_profile(settings)
	feedback_bus.feedback_triggered.connect(_on_feedback_triggered)


func _on_feedback_triggered(event_name: String, flash_color: Color, flash_duration: float) -> void:
	if feedback_overlay == null:
		return
	feedback_overlay.color = flash_color
	feedback_flash_alpha = flash_color.a
	feedback_flash_decay = flash_color.a / max(flash_duration, 0.02)


func _update_feedback_overlay(delta: float) -> void:
	if feedback_overlay == null:
		return
	if feedback_flash_alpha <= 0.001:
		feedback_overlay.color = Color(feedback_overlay.color.r, feedback_overlay.color.g, feedback_overlay.color.b, 0.0)
		return
	feedback_flash_alpha = max(0.0, feedback_flash_alpha - feedback_flash_decay * delta)
	feedback_overlay.color = Color(
		feedback_overlay.color.r,
		feedback_overlay.color.g,
		feedback_overlay.color.b,
		feedback_flash_alpha
	)


func _apply_hud_visual_mode() -> void:
	if hud_root == null:
		return
	var clamped_scale: float = clamp(ui_scale, 0.8, 1.3)
	hud_root.scale = Vector2(clamped_scale, clamped_scale)

	_apply_ui_skin()

	if high_contrast_mode:
		status_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.55))
		state_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		quest_label.add_theme_color_override("font_color", Color(0.90, 1.0, 1.0))
	else:
		status_label.remove_theme_color_override("font_color")
		state_label.remove_theme_color_override("font_color")
		quest_label.remove_theme_color_override("font_color")


func _make_stylebox(bg: Color, border: Color, border_size: int = 2, radius: int = 12) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_size)
	sb.set_corner_radius_all(radius)
	return sb


func _style_button_control(control: Control) -> void:
	var normal := _make_stylebox(Color(0.08, 0.15, 0.30, 0.78), Color(0.26, 0.87, 1.0, 0.95), 2, 12)
	var hover := _make_stylebox(Color(0.10, 0.19, 0.36, 0.86), Color(0.58, 0.42, 1.0, 0.95), 2, 12)
	var pressed := _make_stylebox(Color(0.06, 0.11, 0.23, 0.92), Color(0.40, 0.96, 1.0, 0.95), 2, 12)
	var disabled := _make_stylebox(Color(0.08, 0.10, 0.16, 0.55), Color(0.24, 0.30, 0.44, 0.75), 1, 12)

	control.add_theme_stylebox_override("normal", normal)
	control.add_theme_stylebox_override("hover", hover)
	control.add_theme_stylebox_override("pressed", pressed)
	control.add_theme_stylebox_override("disabled", disabled)
	control.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0))
	control.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	control.add_theme_color_override("font_pressed_color", Color(0.84, 0.98, 1.0))
	control.add_theme_font_size_override("font_size", 16)


func _style_panel_children_recursive(parent: Node) -> void:
	for child in parent.get_children():
		if child is Button or child is OptionButton or child is CheckButton:
			var interactive := child as Control
			_style_button_control(interactive)
		if child is Label:
			var label := child as Label
			label.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0))
		_style_panel_children_recursive(child)


func _make_texture_stylebox(texture: Texture2D, margin: int = 14) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = texture
	sb.texture_margin_left = margin
	sb.texture_margin_top = margin
	sb.texture_margin_right = margin
	sb.texture_margin_bottom = margin
	return sb


func _apply_hotbar_icons() -> void:
	for i in hotbar_buttons.size():
		if i >= hotbar_icon_textures.size():
			continue
		var icon_texture: Texture2D = hotbar_icon_textures[i]
		if icon_texture == null:
			continue
		hotbar_buttons[i].icon = icon_texture
		hotbar_buttons[i].expand_icon = true


func _apply_companion_portrait() -> void:
	if companion_portrait == null:
		return
	var portrait_texture: Texture2D = annalize_portrait_texture if companion_id == "annalize" else keeley_portrait_texture
	companion_portrait.texture = portrait_texture


func _apply_ui_skin() -> void:
	if top_hud_panel != null:
		if hud_top_panel_texture != null:
			top_hud_panel.add_theme_stylebox_override("panel", _make_texture_stylebox(hud_top_panel_texture, 12))
		else:
			top_hud_panel.add_theme_stylebox_override("panel", _make_stylebox(Color(0.03, 0.06, 0.14, 0.76), Color(0.23, 0.82, 1.0, 0.72), 2, 0))
	if bottom_hud_panel != null:
		if hud_bottom_panel_texture != null:
			bottom_hud_panel.add_theme_stylebox_override("panel", _make_texture_stylebox(hud_bottom_panel_texture, 12))
		else:
			bottom_hud_panel.add_theme_stylebox_override("panel", _make_stylebox(Color(0.03, 0.06, 0.14, 0.74), Color(0.55, 0.34, 0.98, 0.70), 2, 0))

	var panels := [pause_panel, end_panel, tutorial_panel]
	for p in panels:
		if p != null:
			p.add_theme_stylebox_override("panel", _make_stylebox(Color(0.04, 0.08, 0.18, 0.92), Color(0.31, 0.88, 1.0, 0.88), 2, 16))
			_style_panel_children_recursive(p)

	var controls := [
		action_button,
		dash_button,
		rhino_button,
		travel_biome_button,
		scavenge_button,
		craft_button,
		gain_page_button,
		pause_button,
		companion_select,
		recipe_select,
		keeley_upgrade_toggle
	]
	for control in controls:
		if control != null:
			_style_button_control(control)

	for button in hotbar_buttons:
		if button != null:
			_style_button_control(button)
			button.add_theme_font_size_override("font_size", 15)
	if ui_button_secondary_texture != null:
		var secondary_style := _make_texture_stylebox(ui_button_secondary_texture, 10)
		for control in controls:
			if control != null:
				control.add_theme_stylebox_override("normal", secondary_style)
				control.add_theme_stylebox_override("hover", secondary_style)
				control.add_theme_stylebox_override("pressed", secondary_style)
		for button in hotbar_buttons:
			if button != null:
				button.add_theme_stylebox_override("normal", secondary_style)
				button.add_theme_stylebox_override("hover", secondary_style)
				button.add_theme_stylebox_override("pressed", secondary_style)
	if ui_button_primary_texture != null and action_button != null:
		var primary_style := _make_texture_stylebox(ui_button_primary_texture, 16)
		action_button.add_theme_stylebox_override("normal", primary_style)
		action_button.add_theme_stylebox_override("hover", primary_style)
		action_button.add_theme_stylebox_override("pressed", primary_style)

	if health_bar != null:
		health_bar.add_theme_stylebox_override("background", _make_stylebox(Color(0.03, 0.08, 0.17, 0.72), Color(0.20, 0.48, 0.84, 0.7), 1, 8))
		health_bar.add_theme_stylebox_override("fill", _make_stylebox(Color(0.30, 0.98, 0.80, 0.94), Color(0.72, 1.0, 0.93, 0.95), 1, 8))
	if hunger_bar != null:
		hunger_bar.add_theme_stylebox_override("background", _make_stylebox(Color(0.03, 0.08, 0.17, 0.72), Color(0.20, 0.48, 0.84, 0.7), 1, 8))
		hunger_bar.add_theme_stylebox_override("fill", _make_stylebox(Color(0.98, 0.38, 0.63, 0.94), Color(1.0, 0.74, 0.84, 0.95), 1, 8))

	if left_stick_base != null:
		if ui_move_base_texture != null:
			left_stick_base.add_theme_stylebox_override("panel", _make_texture_stylebox(ui_move_base_texture, 24))
		else:
			left_stick_base.add_theme_stylebox_override("panel", _make_stylebox(Color(0.16, 0.72, 1.0, 0.14), Color(0.37, 0.95, 1.0, 0.9), 2, 70))
	if left_stick_knob != null:
		if ui_move_knob_texture != null:
			left_stick_knob.add_theme_stylebox_override("panel", _make_texture_stylebox(ui_move_knob_texture, 10))
		else:
			left_stick_knob.add_theme_stylebox_override("panel", _make_stylebox(Color(0.45, 0.95, 1.0, 0.58), Color(0.84, 1.0, 1.0, 0.96), 2, 30))
	if right_stick_base != null:
		if ui_aim_base_texture != null:
			right_stick_base.add_theme_stylebox_override("panel", _make_texture_stylebox(ui_aim_base_texture, 24))
		else:
			right_stick_base.add_theme_stylebox_override("panel", _make_stylebox(Color(0.62, 0.42, 1.0, 0.14), Color(0.84, 0.68, 1.0, 0.88), 2, 80))
	if right_stick_knob != null:
		if ui_aim_knob_texture != null:
			right_stick_knob.add_theme_stylebox_override("panel", _make_texture_stylebox(ui_aim_knob_texture, 10))
		else:
			right_stick_knob.add_theme_stylebox_override("panel", _make_stylebox(Color(0.84, 0.62, 1.0, 0.56), Color(1.0, 0.90, 1.0, 0.96), 2, 30))

	if companion_portrait_frame != null:
		if ui_companion_frame_texture != null:
			companion_portrait_frame.add_theme_stylebox_override("panel", _make_texture_stylebox(ui_companion_frame_texture, 16))
		else:
			companion_portrait_frame.add_theme_stylebox_override("panel", _make_stylebox(Color(0.05, 0.16, 0.33, 0.88), Color(0.50, 0.90, 1.0, 0.88), 2, 14))
	_apply_hotbar_icons()
	_apply_companion_portrait()


func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud_root = Control.new()
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(hud_root)

	top_hud_panel = Panel.new()
	top_hud_panel.position = Vector2(0, 0)
	top_hud_panel.size = Vector2(1920, 440)
	top_hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(top_hud_panel)

	bottom_hud_panel = Panel.new()
	bottom_hud_panel.position = Vector2(0, 882)
	bottom_hud_panel.size = Vector2(1920, 198)
	bottom_hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(bottom_hud_panel)

	var title := Label.new()
	title.text = "RIFT: The Bestiary Protocol - Code Max Studios"
	title.position = Vector2(20, 12)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.80, 0.98, 1.0))
	hud_root.add_child(title)

	state_label = Label.new()
	state_label.position = Vector2(20, 48)
	state_label.add_theme_font_size_override("font_size", 18)
	state_label.add_theme_color_override("font_color", Color(0.90, 0.98, 1.0))
	hud_root.add_child(state_label)

	biome_label = Label.new()
	biome_label.position = Vector2(420, 48)
	biome_label.add_theme_font_size_override("font_size", 18)
	biome_label.add_theme_color_override("font_color", Color(0.82, 1.0, 0.96))
	hud_root.add_child(biome_label)

	wave_label = Label.new()
	wave_label.position = Vector2(720, 48)
	wave_label.add_theme_font_size_override("font_size", 18)
	wave_label.add_theme_color_override("font_color", Color(0.99, 0.90, 1.0))
	hud_root.add_child(wave_label)

	boss_label = Label.new()
	boss_label.position = Vector2(980, 48)
	boss_label.add_theme_font_size_override("font_size", 18)
	boss_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.92))
	hud_root.add_child(boss_label)

	combo_label = Label.new()
	combo_label.position = Vector2(1240, 48)
	combo_label.size = Vector2(300, 22)
	combo_label.add_theme_font_size_override("font_size", 18)
	combo_label.add_theme_color_override("font_color", Color(0.95, 1.0, 0.82))
	hud_root.add_child(combo_label)

	dash_label = Label.new()
	dash_label.position = Vector2(1560, 48)
	dash_label.size = Vector2(260, 22)
	dash_label.add_theme_font_size_override("font_size", 18)
	dash_label.add_theme_color_override("font_color", Color(0.84, 0.96, 1.0))
	hud_root.add_child(dash_label)

	perf_metrics_label = Label.new()
	perf_metrics_label.position = Vector2(20, 20)
	perf_metrics_label.size = Vector2(520, 24)
	perf_metrics_label.add_theme_font_size_override("font_size", 14)
	perf_metrics_label.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
	hud_root.add_child(perf_metrics_label)

	health_bar = ProgressBar.new()
	health_bar.position = Vector2(20, 82)
	health_bar.size = Vector2(280, 24)
	health_bar.max_value = max_health
	health_bar.show_percentage = false
	hud_root.add_child(health_bar)

	var health_text := Label.new()
	health_text.text = "Health"
	health_text.position = Vector2(308, 82)
	hud_root.add_child(health_text)

	hunger_bar = ProgressBar.new()
	hunger_bar.position = Vector2(20, 116)
	hunger_bar.size = Vector2(280, 24)
	hunger_bar.max_value = max_hunger
	hunger_bar.show_percentage = false
	hud_root.add_child(hunger_bar)

	var hunger_text := Label.new()
	hunger_text.text = "Hunger (Energy)"
	hunger_text.position = Vector2(308, 116)
	hud_root.add_child(hunger_text)

	companion_select = OptionButton.new()
	companion_select.position = Vector2(20, 154)
	companion_select.size = Vector2(220, 34)
	companion_select.add_item("Keeley - Tech Scout", 0)
	companion_select.add_item("Annalize - Master Engineer", 1)
	companion_select.item_selected.connect(_on_companion_changed)
	hud_root.add_child(companion_select)

	keeley_upgrade_toggle = CheckButton.new()
	keeley_upgrade_toggle.position = Vector2(250, 156)
	keeley_upgrade_toggle.text = "Keeley DNA Upgrade"
	keeley_upgrade_toggle.toggled.connect(_on_keeley_upgrade_toggled)
	hud_root.add_child(keeley_upgrade_toggle)

	companion_portrait_frame = Panel.new()
	companion_portrait_frame.position = Vector2(488, 150)
	companion_portrait_frame.size = Vector2(132, 132)
	companion_portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(companion_portrait_frame)

	companion_portrait = TextureRect.new()
	companion_portrait.position = Vector2(8, 8)
	companion_portrait.size = Vector2(116, 116)
	companion_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	companion_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	companion_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	companion_portrait_frame.add_child(companion_portrait)

	companion_label = Label.new()
	companion_label.position = Vector2(20, 196)
	companion_label.size = Vector2(1240, 26)
	hud_root.add_child(companion_label)

	loot_label = Label.new()
	loot_label.position = Vector2(20, 224)
	loot_label.size = Vector2(980, 24)
	hud_root.add_child(loot_label)

	status_label = Label.new()
	status_label.position = Vector2(20, 252)
	status_label.size = Vector2(1280, 24)
	hud_root.add_child(status_label)

	rhino_timer_label = Label.new()
	rhino_timer_label.position = Vector2(20, 282)
	rhino_timer_label.size = Vector2(480, 24)
	hud_root.add_child(rhino_timer_label)

	inventory_label = Label.new()
	inventory_label.position = Vector2(20, 312)
	inventory_label.size = Vector2(1280, 24)
	hud_root.add_child(inventory_label)

	progression_label = Label.new()
	progression_label.position = Vector2(20, 340)
	progression_label.size = Vector2(1280, 24)
	hud_root.add_child(progression_label)

	quest_label = Label.new()
	quest_label.position = Vector2(20, 368)
	quest_label.size = Vector2(1320, 52)
	quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud_root.add_child(quest_label)

	travel_biome_button = Button.new()
	travel_biome_button.text = "Travel Biome"
	travel_biome_button.position = Vector2(1080, 80)
	travel_biome_button.size = Vector2(160, 42)
	travel_biome_button.pressed.connect(_on_travel_biome_pressed)
	hud_root.add_child(travel_biome_button)

	rhino_button = Button.new()
	rhino_button.text = "Activate Rhino Charge"
	rhino_button.position = Vector2(1080, 132)
	rhino_button.size = Vector2(220, 42)
	rhino_button.pressed.connect(_on_rhino_pressed)
	hud_root.add_child(rhino_button)

	scavenge_button = Button.new()
	scavenge_button.text = "Scavenge Burst"
	scavenge_button.position = Vector2(1310, 80)
	scavenge_button.size = Vector2(180, 42)
	scavenge_button.pressed.connect(_on_scavenge_pressed)
	hud_root.add_child(scavenge_button)

	recipe_select = OptionButton.new()
	recipe_select.position = Vector2(1310, 132)
	recipe_select.size = Vector2(240, 42)
	for recipe in recipes:
		recipe_select.add_item(recipe.get("name", "Recipe"))
	recipe_select.item_selected.connect(_on_recipe_selected)
	hud_root.add_child(recipe_select)

	craft_button = Button.new()
	craft_button.text = "Craft Weapon"
	craft_button.position = Vector2(1560, 132)
	craft_button.size = Vector2(160, 42)
	craft_button.pressed.connect(_on_craft_pressed)
	hud_root.add_child(craft_button)

	gain_page_button = Button.new()
	gain_page_button.text = "Find Bestiary Page"
	gain_page_button.position = Vector2(1500, 80)
	gain_page_button.size = Vector2(220, 42)
	gain_page_button.pressed.connect(_on_gain_page_pressed)
	hud_root.add_child(gain_page_button)

	pause_button = Button.new()
	pause_button.text = "Pause"
	pause_button.position = Vector2(1730, 80)
	pause_button.size = Vector2(170, 42)
	pause_button.pressed.connect(_on_pause_pressed)
	hud_root.add_child(pause_button)

	hotbar_title = Label.new()
	hotbar_title.text = "Hotbar"
	hotbar_title.position = Vector2(920, 942)
	hotbar_title.add_theme_color_override("font_color", Color(0.82, 0.97, 1.0))
	hud_root.add_child(hotbar_title)

	hotbar_container = HBoxContainer.new()
	hotbar_container.position = Vector2(690, 980)
	hotbar_container.add_theme_constant_override("separation", 10)
	hud_root.add_child(hotbar_container)

	for i in hotbar_items.size():
		var button := Button.new()
		button.custom_minimum_size = Vector2(140, 74)
		button.text = "%d" % [i + 1]
		button.tooltip_text = String(hotbar_items[i].get("label", "Item"))
		button.pressed.connect(_on_hotbar_selected.bind(i))
		hotbar_container.add_child(button)
		hotbar_buttons.append(button)

	action_button = Button.new()
	action_button.position = Vector2(1570, 920)
	action_button.size = Vector2(280, 120)
	action_button.text = "ATTACK"
	action_button.pressed.connect(_on_action_pressed)
	hud_root.add_child(action_button)

	dash_button = Button.new()
	dash_button.position = Vector2(1370, 944)
	dash_button.size = Vector2(180, 84)
	dash_button.text = "DASH"
	dash_button.pressed.connect(_on_dash_pressed)
	hud_root.add_child(dash_button)

	left_stick_base = Panel.new()
	left_stick_base.size = Vector2(140, 140)
	left_stick_base.visible = false
	hud_root.add_child(left_stick_base)

	left_stick_knob = Panel.new()
	left_stick_knob.size = Vector2(52, 52)
	left_stick_knob.visible = false
	hud_root.add_child(left_stick_knob)

	right_stick_base = Panel.new()
	right_stick_base.size = Vector2(154, 154)
	right_stick_base.visible = false
	hud_root.add_child(right_stick_base)

	right_stick_knob = Panel.new()
	right_stick_knob.size = Vector2(52, 52)
	right_stick_knob.visible = false
	hud_root.add_child(right_stick_knob)

	feedback_overlay = ColorRect.new()
	feedback_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	feedback_overlay.color = Color(1, 1, 1, 0)
	feedback_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(feedback_overlay)

	_build_pause_panel()
	_build_end_panel()
	_build_tutorial_panel()
	_apply_ui_skin()
	_on_hotbar_selected(selected_hotbar_index)


func _build_pause_panel() -> void:
	pause_panel = Panel.new()
	pause_panel.size = Vector2(560, 340)
	pause_panel.position = Vector2(680, 290)
	pause_panel.visible = false
	hud_root.add_child(pause_panel)

	pause_title = Label.new()
	pause_title.text = "PAUSED"
	pause_title.position = Vector2(220, 30)
	pause_title.add_theme_font_size_override("font_size", 34)
	pause_panel.add_child(pause_title)

	var resume_button := Button.new()
	resume_button.text = "Resume"
	resume_button.position = Vector2(140, 96)
	resume_button.size = Vector2(280, 50)
	resume_button.pressed.connect(_on_resume_pressed)
	pause_panel.add_child(resume_button)

	var save_menu_button := Button.new()
	save_menu_button.text = "Save & Return to Menu"
	save_menu_button.position = Vector2(140, 162)
	save_menu_button.size = Vector2(280, 50)
	save_menu_button.pressed.connect(_on_save_and_menu_pressed)
	pause_panel.add_child(save_menu_button)

	var quit_button := Button.new()
	quit_button.text = "End Run"
	quit_button.position = Vector2(140, 228)
	quit_button.size = Vector2(280, 50)
	quit_button.pressed.connect(_on_end_run_pressed)
	pause_panel.add_child(quit_button)


func _build_end_panel() -> void:
	end_panel = Panel.new()
	end_panel.size = Vector2(700, 360)
	end_panel.position = Vector2(610, 270)
	end_panel.visible = false
	hud_root.add_child(end_panel)

	end_title = Label.new()
	end_title.text = "RUN COMPLETE"
	end_title.position = Vector2(216, 26)
	end_title.add_theme_font_size_override("font_size", 36)
	end_panel.add_child(end_title)

	end_subtitle = Label.new()
	end_subtitle.position = Vector2(44, 88)
	end_subtitle.size = Vector2(612, 116)
	end_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	end_panel.add_child(end_subtitle)

	var retry_button := Button.new()
	retry_button.text = "Start New Run"
	retry_button.position = Vector2(140, 236)
	retry_button.size = Vector2(180, 54)
	retry_button.pressed.connect(_on_retry_pressed)
	end_panel.add_child(retry_button)

	var menu_button := Button.new()
	menu_button.text = "Return to Menu"
	menu_button.position = Vector2(380, 236)
	menu_button.size = Vector2(180, 54)
	menu_button.pressed.connect(_on_return_menu_pressed)
	end_panel.add_child(menu_button)


func _build_tutorial_panel() -> void:
	tutorial_panel = Panel.new()
	tutorial_panel.size = Vector2(760, 360)
	tutorial_panel.position = Vector2(580, 300)
	tutorial_panel.visible = false
	hud_root.add_child(tutorial_panel)

	var tutorial_title := Label.new()
	tutorial_title.text = "MISSION BRIEFING"
	tutorial_title.position = Vector2(214, 24)
	tutorial_title.add_theme_font_size_override("font_size", 34)
	tutorial_panel.add_child(tutorial_title)

	tutorial_body = Label.new()
	tutorial_body.position = Vector2(44, 92)
	tutorial_body.size = Vector2(672, 130)
	tutorial_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_panel.add_child(tutorial_body)

	var next_button := Button.new()
	next_button.text = "Next"
	next_button.position = Vector2(152, 258)
	next_button.size = Vector2(190, 52)
	next_button.pressed.connect(_on_tutorial_next_pressed)
	tutorial_panel.add_child(next_button)

	var skip_button := Button.new()
	skip_button.text = "Skip Tutorial"
	skip_button.position = Vector2(418, 258)
	skip_button.size = Vector2(190, 52)
	skip_button.pressed.connect(_on_tutorial_skip_pressed)
	skip_button.visible = tutorial_allow_skip
	tutorial_panel.add_child(skip_button)


func _recalculate_input_regions() -> void:
	viewport_size = get_viewport_rect().size
	left_dead_zone_px = min(configured_left_dead_zone_px, viewport_size.x * 0.09)
	right_dead_zone_px = min(configured_right_dead_zone_px, viewport_size.x * 0.09)
	var input_layout: Dictionary = config.get("inputLayout", {})
	left_spawn_rect = _rect_from_norm(input_layout.get("leftJoystick", {}).get("spawnArea", {}), Rect2(0, viewport_size.y * 0.54, viewport_size.x * 0.4, viewport_size.y * 0.4))
	right_spawn_rect = _rect_from_norm(input_layout.get("rightJoystick", {}).get("spawnArea", {}), Rect2(viewport_size.x * 0.6, viewport_size.y * 0.52, viewport_size.x * 0.35, viewport_size.y * 0.42))

	if hotbar_container:
		hotbar_container.position = Vector2((viewport_size.x - hotbar_container.size.x) * 0.5, viewport_size.y - 96)
	if hotbar_title:
		hotbar_title.position = Vector2((viewport_size.x - 100) * 0.5, viewport_size.y - 138)
	if action_button:
		action_button.position = Vector2(viewport_size.x - 320, viewport_size.y - 150)
	if pause_panel:
		pause_panel.position = (viewport_size - pause_panel.size) * 0.5
	if end_panel:
		end_panel.position = (viewport_size - end_panel.size) * 0.5
	if tutorial_panel:
		tutorial_panel.position = (viewport_size - tutorial_panel.size) * 0.5


func _rect_from_norm(source: Dictionary, fallback: Rect2) -> Rect2:
	if source.is_empty():
		return fallback
	var x_min := float(source.get("xMinNorm", fallback.position.x / max(viewport_size.x, 1.0)))
	var x_max := float(source.get("xMaxNorm", (fallback.position.x + fallback.size.x) / max(viewport_size.x, 1.0)))
	var y_min := float(source.get("yMinNorm", fallback.position.y / max(viewport_size.y, 1.0)))
	var y_max := float(source.get("yMaxNorm", (fallback.position.y + fallback.size.y) / max(viewport_size.y, 1.0)))
	return Rect2(Vector2(x_min * viewport_size.x, y_min * viewport_size.y), Vector2((x_max - x_min) * viewport_size.x, (y_max - y_min) * viewport_size.y))


func _on_touch(touch_id: int, pressed: bool, position: Vector2) -> void:
	if pressed:
		if _is_over_interactive_ui(position):
			return
		if _is_dead_zone(position):
			return
		var allow_left := left_spawn_rect.has_point(position) or (position.x < viewport_size.x * 0.48 and position.y > viewport_size.y * 0.34)
		if left_touch_id == INVALID_TOUCH_ID and allow_left:
			left_touch_id = touch_id
			left_origin = position
			left_vector = Vector2.ZERO
			_show_stick(left_stick_base, left_stick_knob, left_origin)
			return
		var allow_right := right_spawn_rect.has_point(position) or (position.x >= viewport_size.x * 0.52 and position.y > viewport_size.y * 0.34)
		if right_touch_id == INVALID_TOUCH_ID and allow_right:
			right_touch_id = touch_id
			right_origin = position
			right_touch_start = position
			right_touch_start_msec = Time.get_ticks_msec()
			right_vector = Vector2.ZERO
			_show_stick(right_stick_base, right_stick_knob, right_origin)
	else:
		if touch_id == left_touch_id:
			left_touch_id = INVALID_TOUCH_ID
			left_vector = Vector2.ZERO
			left_stick_base.visible = false
			left_stick_knob.visible = false
		elif touch_id == right_touch_id:
			var elapsed := Time.get_ticks_msec() - right_touch_start_msec
			if elapsed < 220 and right_touch_start.distance_to(position) < 20.0 and input_mode == InputMode.ATTACK_MODE:
				_fire_attack("Quick tap auto-fire", player_direction)
			right_touch_id = INVALID_TOUCH_ID
			right_vector = Vector2.ZERO
			right_stick_base.visible = false
			right_stick_knob.visible = false


func _on_drag(touch_id: int, position: Vector2) -> void:
	if touch_id == left_touch_id:
		left_vector = _stick_vector(position - left_origin, 70.0)
		_update_knob(left_stick_knob, left_origin, left_vector * 70.0)
	elif touch_id == right_touch_id:
		right_vector = _stick_vector(position - right_origin, 77.0)
		_update_knob(right_stick_knob, right_origin, right_vector * 77.0)


func _stick_vector(offset: Vector2, max_radius: float) -> Vector2:
	if offset.length() == 0.0:
		return Vector2.ZERO
	return offset.limit_length(max_radius) / max_radius


func _show_stick(base: Panel, knob: Panel, origin: Vector2) -> void:
	base.visible = true
	base.position = origin - base.size * 0.5
	knob.visible = true
	_update_knob(knob, origin, Vector2.ZERO)


func _update_knob(knob: Panel, origin: Vector2, offset: Vector2) -> void:
	knob.position = origin + offset - knob.size * 0.5


func _is_dead_zone(position: Vector2) -> bool:
	return position.x < left_dead_zone_px or position.x > viewport_size.x - right_dead_zone_px


func _is_over_interactive_ui(position: Vector2) -> bool:
	var controls: Array[Control] = [
		action_button,
		dash_button,
		rhino_button,
		travel_biome_button,
		scavenge_button,
		recipe_select,
		craft_button,
		gain_page_button,
		pause_button,
		companion_select,
		keeley_upgrade_toggle
	]
	for control in controls:
		if control != null and control.visible and control.get_global_rect().has_point(position):
			return true
	if pause_panel != null and pause_panel.visible and pause_panel.get_global_rect().has_point(position):
		return true
	if end_panel != null and end_panel.visible and end_panel.get_global_rect().has_point(position):
		return true
	if tutorial_panel != null and tutorial_panel.visible and tutorial_panel.get_global_rect().has_point(position):
		return true
	return false


func _update_survival(delta: float) -> void:
	var hunger_drain_rate := 1.3
	if player_state == PlayerState.RHINO_CHARGE:
		hunger_drain_rate = 2.2
	hunger = clamp(hunger - hunger_drain_rate * delta, 0.0, max_hunger)

	if player_state == PlayerState.EXHAUSTED:
		health = clamp(health - (1.6 * delta), 0.0, max_health)
	elif wave_active:
		health = clamp(health + (0.30 * delta), 0.0, max_health)


func _update_player_state(delta: float) -> void:
	state_move_speed_multiplier = 1.0
	if player_state == PlayerState.RHINO_CHARGE:
		rhino_time_left = max(0.0, rhino_time_left - delta)
		state_move_speed_multiplier = 1.8
		if rhino_time_left <= 0.0:
			player_state = PlayerState.NORMAL if hunger > 0.0 else PlayerState.EXHAUSTED
			status_label.text = "Rhino Charge ended."
	elif hunger <= 0.0:
		player_state = PlayerState.EXHAUSTED
		state_move_speed_multiplier = 0.72
	elif player_state == PlayerState.EXHAUSTED and hunger > 12.0:
		player_state = PlayerState.NORMAL
		status_label.text = "Recovered from Exhausted state."


func _update_dash_and_combo(delta: float) -> void:
	dash_cooldown_remaining = max(0.0, dash_cooldown_remaining - delta)
	if dash_time_left > 0.0:
		dash_time_left = max(0.0, dash_time_left - delta)

	if combo_streak <= 0:
		combo_multiplier = 1.0
		combo_decay_time_left = 0.0
		return
	combo_decay_time_left = max(0.0, combo_decay_time_left - delta)
	if combo_decay_time_left <= 0.0:
		combo_streak = 0
		combo_multiplier = 1.0


func _spawn_vfx_burst(position: Vector2, color: Color, count: int, speed: float, ttl: float, size: float) -> void:
	if vfx_particles.size() >= max_active_vfx_particles:
		return
	var emit_count := mini(count, max_active_vfx_particles - vfx_particles.size())
	for i in emit_count:
		var angle := randf_range(0.0, TAU)
		var velocity := Vector2.RIGHT.rotated(angle) * randf_range(speed * 0.55, speed * 1.05)
		vfx_particles.append({
			"position": position,
			"velocity": velocity,
			"ttl": ttl,
			"total_ttl": ttl,
			"color": color,
			"size": size
		})


func _update_vfx(delta: float) -> void:
	if vfx_particles.is_empty():
		return
	var remove_indexes: Array[int] = []
	for i in vfx_particles.size():
		var particle: Dictionary = vfx_particles[i]
		var position: Vector2 = particle.get("position", Vector2.ZERO)
		var velocity: Vector2 = particle.get("velocity", Vector2.ZERO)
		var ttl: float = particle.get("ttl", 0.0)
		position += velocity * delta
		velocity *= 0.92
		ttl -= delta
		particle["position"] = position
		particle["velocity"] = velocity
		particle["ttl"] = ttl
		vfx_particles[i] = particle
		if ttl <= 0.0:
			remove_indexes.append(i)
	if not remove_indexes.is_empty():
		remove_indexes.reverse()
		for index in remove_indexes:
			vfx_particles.remove_at(index)


func _apply_hotbar_context_rules() -> void:
	loadout_move_speed_multiplier = 1.0
	if player_state == PlayerState.RHINO_CHARGE:
		input_mode = InputMode.RHINO_BOOST_MODE
		action_button.text = "RAMMING SPEED"
		hotbar_container.visible = false
		hotbar_title.visible = false
		return

	hotbar_container.visible = true
	hotbar_title.visible = true
	var selected_item := hotbar_items[selected_hotbar_index]
	var selected_tag := String(selected_item.get("tag", "tool"))
	if selected_tag == "heavy_weapon":
		loadout_move_speed_multiplier = 0.86
	if selected_tag == "food":
		input_mode = InputMode.EAT_MODE
		action_button.text = "EAT"
	else:
		input_mode = InputMode.ATTACK_MODE
		action_button.text = "ATTACK"


func _update_movement(delta: float) -> void:
	var velocity := left_vector
	var speed := base_move_speed * state_move_speed_multiplier * loadout_move_speed_multiplier
	if dash_time_left > 0.0:
		velocity = dash_direction
		speed *= 2.7
	elif velocity.length() > 0.05:
		player_direction = velocity.normalized()
	player_position += velocity * speed * delta
	player_position.x = clamp(player_position.x, left_dead_zone_px + 30.0, viewport_size.x - right_dead_zone_px - 30.0)
	player_position.y = clamp(player_position.y, 320.0, viewport_size.y - 70.0)


func _update_combat(delta: float) -> void:
	attack_cooldown = max(0.0, attack_cooldown - delta)
	if input_mode == InputMode.ATTACK_MODE and right_vector.length() > 0.6 and attack_cooldown <= 0.0:
		_fire_attack("Drag fire", right_vector.normalized())
	elif input_mode == InputMode.RHINO_BOOST_MODE and right_vector.length() > 0.45 and attack_cooldown <= 0.0:
		_fire_attack("Rhino impact", right_vector.normalized())


func _fire_attack(source: String, facing: Vector2 = Vector2.ZERO) -> void:
	attack_cooldown = 0.24
	feedback_bus.emit_feedback("attack")
	_play_sfx("attack")
	var attack_dir := facing if facing.length() > 0.2 else player_direction
	_spawn_vfx_burst(player_position + attack_dir * 30.0, Color(0.70, 0.95, 1.0, 0.95), 4, 155.0, 0.20, 6.0)

	if input_mode == InputMode.RHINO_BOOST_MODE:
		var rhino_kills := _damage_enemies_radius(player_position, 150.0, 75.0)
		secret_walls_broken += 1 if rhino_kills > 0 else 0
		status_label.text = "Rhino impact %s. (%s)" % ["cleared targets" if rhino_kills > 0 else "missed", source]
		_damage_boss_from_attack(attack_dir, 34.0, 180.0)
		return

	var selected_tag := String(hotbar_items[selected_hotbar_index].get("tag", "tool"))
	var damage := 26.0
	var range := 210.0
	if selected_tag == "heavy_weapon":
		damage = 42.0
		range = 260.0

	var kills_hit := _damage_enemies_arc(player_position, attack_dir, range, 0.88, damage)
	var boss_hit := _damage_boss_from_attack(attack_dir, damage * 0.9, range + 40.0)
	if kills_hit > 0 or boss_hit:
		status_label.text = "Direct hits landed. (%s)" % source
	else:
		status_label.text = "Shots fired. (%s)" % source


func _damage_boss_from_attack(direction: Vector2, damage: float, range: float) -> bool:
	if not boss_active:
		return false
	var boss_pos: Vector2 = boss.get("position", Vector2.ZERO)
	var to_boss := boss_pos - player_position
	if to_boss.length() > range or to_boss.length() < 0.001:
		return false
	if to_boss.normalized().dot(direction.normalized()) < 0.72:
		return false
	boss["hp"] = float(boss.get("hp", 1.0)) - damage
	if float(boss.get("hp", 0.0)) <= 0.0:
		_on_boss_defeated()
	return true


func _damage_enemies_arc(origin: Vector2, direction: Vector2, range: float, dot_threshold: float, damage: float) -> int:
	var kills := 0
	var to_remove: Array[int] = []
	for i in active_enemies.size():
		var enemy: Dictionary = active_enemies[i]
		var enemy_position: Vector2 = enemy.get("position", Vector2.ZERO)
		var to_enemy := enemy_position - origin
		var distance := to_enemy.length()
		if distance > range or distance < 0.001:
			continue
		if to_enemy.normalized().dot(direction) < dot_threshold:
			continue
		enemy["hp"] = float(enemy.get("hp", 0.0)) - damage
		_spawn_vfx_burst(enemy_position, Color(0.92, 0.64, 1.0, 0.95), 3, 140.0, 0.22, 5.0)
		active_enemies[i] = enemy
		if float(enemy.get("hp", 0.0)) <= 0.0:
			to_remove.append(i)

	if not to_remove.is_empty():
		to_remove.reverse()
		for index in to_remove:
			var dead_enemy: Dictionary = active_enemies[index]
			_on_enemy_defeated(dead_enemy)
			active_enemies.remove_at(index)
			kills += 1
	return kills


func _damage_enemies_radius(origin: Vector2, radius: float, damage: float) -> int:
	var kills := 0
	var to_remove: Array[int] = []
	for i in active_enemies.size():
		var enemy: Dictionary = active_enemies[i]
		var enemy_position: Vector2 = enemy.get("position", Vector2.ZERO)
		if enemy_position.distance_to(origin) > radius:
			continue
		enemy["hp"] = float(enemy.get("hp", 0.0)) - damage
		_spawn_vfx_burst(enemy_position, Color(0.56, 0.98, 0.90, 0.95), 4, 160.0, 0.22, 5.0)
		active_enemies[i] = enemy
		if float(enemy.get("hp", 0.0)) <= 0.0:
			to_remove.append(i)
	if not to_remove.is_empty():
		to_remove.reverse()
		for index in to_remove:
			var dead_enemy: Dictionary = active_enemies[index]
			_on_enemy_defeated(dead_enemy)
			active_enemies.remove_at(index)
			kills += 1
	return kills


func _update_companion_logic(delta: float) -> void:
	companion_tick += delta
	if companion_tick < 2.0:
		return
	companion_tick = 0.0

	if companion_id == "annalize":
		var railgun_kills := _damage_enemies_arc(player_position, player_direction, 360.0, 0.72, 36.0)
		var boss_shot := _damage_boss_from_attack(player_direction, 18.0, 420.0)
		companion_label.text = "Annalize railgun support fired (%d enemies%s)." % [railgun_kills, ", boss hit" if boss_shot else ""]
	else:
		var nearby_enemies := _count_enemies_in_radius(player_position, 170.0)
		if nearby_enemies >= 5:
			if keeley_dna_upgrade:
				_apply_keeley_wail()
				companion_label.text = "Keeley triggered Neuro-Toxic Wail!"
			else:
				_apply_keeley_sonic()
				companion_label.text = "Keeley triggered Sonic Scream!"
		else:
			companion_label.text = "Keeley scanning... (%d nearby hostiles)" % nearby_enemies


func _count_enemies_in_radius(origin: Vector2, radius: float) -> int:
	var count := 0
	for enemy in active_enemies:
		var enemy_position: Vector2 = enemy.get("position", Vector2.ZERO)
		if enemy_position.distance_to(origin) <= radius:
			count += 1
	return count


func _apply_keeley_sonic() -> void:
	for i in active_enemies.size():
		var enemy: Dictionary = active_enemies[i]
		var enemy_position: Vector2 = enemy.get("position", Vector2.ZERO)
		var push_dir := (enemy_position - player_position).normalized()
		enemy_position += push_dir * 140.0
		enemy_position.x = clamp(enemy_position.x, left_dead_zone_px + 35.0, viewport_size.x - right_dead_zone_px - 35.0)
		enemy_position.y = clamp(enemy_position.y, 330.0, viewport_size.y - 60.0)
		enemy["position"] = enemy_position
		active_enemies[i] = enemy


func _apply_keeley_wail() -> void:
	var to_remove: Array[int] = []
	for i in active_enemies.size():
		var enemy: Dictionary = active_enemies[i]
		var enemy_position: Vector2 = enemy.get("position", Vector2.ZERO)
		var distance := enemy_position.distance_to(player_position)
		if distance <= 200.0:
			enemy["hp"] = float(enemy.get("hp", 0.0)) - 18.0
		var push_dir := (enemy_position - player_position).normalized()
		enemy_position += push_dir * 160.0
		enemy["position"] = enemy_position
		active_enemies[i] = enemy
		if float(enemy.get("hp", 0.0)) <= 0.0:
			to_remove.append(i)
	if not to_remove.is_empty():
		to_remove.reverse()
		for index in to_remove:
			var dead_enemy: Dictionary = active_enemies[index]
			_on_enemy_defeated(dead_enemy)
			active_enemies.remove_at(index)


func _update_wave_system(delta: float) -> void:
	if boss_active:
		return
	if not wave_active:
		wave_wait_tick -= delta
		if wave_wait_tick <= 0.0:
			_start_next_wave()
		return

	wave_spawn_tick -= delta
	if wave_spawn_remaining > 0 and wave_spawn_tick <= 0.0:
		_spawn_enemy()
		wave_spawn_remaining -= 1
		wave_spawn_tick = max(0.25, 0.8 - (wave_number * 0.05))

	_update_enemies(delta)

	if wave_spawn_remaining == 0 and active_enemies.is_empty():
		wave_active = false
		wave_wait_tick = 3.5
		_grant_xp(35 + wave_number * 5)
		_scavenge_resources(
			_scaled_loot_value(3 + wave_number),
			_scaled_loot_value(1 + int(wave_number / 2)),
			_scaled_loot_value(1),
			_scaled_loot_value(1)
		)
		status_label.text = "Wave %d cleared!" % wave_number


func _start_next_wave() -> void:
	wave_number += 1
	wave_active = true
	enemy_projectiles.clear()
	vfx_particles.clear()
	var base_spawn := wave_base_enemies + wave_number * wave_enemy_growth
	wave_spawn_remaining = maxi(1, int(round(float(base_spawn) * enemy_spawn_multiplier)))
	wave_spawn_tick = 0.15
	status_label.text = "Wave %d started." % wave_number


func _spawn_enemy() -> void:
	if active_enemies.size() >= max_active_enemies:
		return
	var angle := randf_range(0.0, TAU)
	var enemy_position := player_position + Vector2.RIGHT.rotated(angle) * wave_spawn_radius
	enemy_position.x = clamp(enemy_position.x, left_dead_zone_px + 50.0, viewport_size.x - right_dead_zone_px - 50.0)
	enemy_position.y = clamp(enemy_position.y, 360.0, viewport_size.y - 100.0)

	var enemy_type := "drone"
	var hp := (45.0 + (wave_number * 4.0)) * enemy_health_multiplier
	var speed := (72.0 + (wave_number * 2.5)) * enemy_speed_multiplier
	var roll := randf()
	if roll > 0.85:
		enemy_type = "brute"
		hp *= 1.9
		speed *= 0.72
	elif roll > 0.62:
		enemy_type = "spitter"
		hp *= 1.2
		speed *= 1.12

	active_enemies.append({
		"id": next_enemy_id,
		"type": enemy_type,
		"position": enemy_position,
		"hp": hp,
		"max_hp": hp,
		"speed": speed
	})
	next_enemy_id += 1


func _update_enemies(delta: float) -> void:
	spitter_shot_tick = max(0.0, spitter_shot_tick - delta)
	var spitter_position_for_shot := Vector2.ZERO
	var has_spitter_line := false
	for i in active_enemies.size():
		var enemy: Dictionary = active_enemies[i]
		var enemy_position: Vector2 = enemy.get("position", Vector2.ZERO)
		var enemy_speed: float = enemy.get("speed", 60.0)
		var enemy_type := String(enemy.get("type", "drone"))
		var drift := Vector2(randf_range(-0.35, 0.35), randf_range(-0.35, 0.35))
		var direction := (player_position - enemy_position).normalized()
		if enemy_type == "brute":
			drift *= 0.45
		elif enemy_type == "spitter":
			if enemy_position.distance_to(player_position) < 170.0:
				direction = -direction
			if not has_spitter_line and enemy_position.distance_to(player_position) < 520.0:
				spitter_position_for_shot = enemy_position
				has_spitter_line = true
		enemy_position += (direction + drift).normalized() * enemy_speed * delta
		enemy_position.x = clamp(enemy_position.x, left_dead_zone_px + 35.0, viewport_size.x - right_dead_zone_px - 35.0)
		enemy_position.y = clamp(enemy_position.y, 330.0, viewport_size.y - 60.0)
		enemy["position"] = enemy_position
		active_enemies[i] = enemy

	if has_spitter_line and spitter_shot_tick <= 0.0:
		_spawn_enemy_projectile(spitter_position_for_shot)
		spitter_shot_tick = 1.15


func _spawn_enemy_projectile(origin: Vector2) -> void:
	if enemy_projectiles.size() >= max_active_projectiles:
		return
	var fire_direction := (player_position - origin).normalized()
	if fire_direction.length() <= 0.01:
		return
	enemy_projectiles.append({
		"position": origin,
		"velocity": fire_direction * spitter_projectile_speed,
		"ttl": 2.5
	})


func _update_enemy_projectiles(delta: float) -> void:
	if enemy_projectiles.is_empty():
		return
	var to_remove: Array[int] = []
	for i in enemy_projectiles.size():
		var projectile: Dictionary = enemy_projectiles[i]
		var position: Vector2 = projectile.get("position", Vector2.ZERO)
		var velocity: Vector2 = projectile.get("velocity", Vector2.ZERO)
		var ttl: float = projectile.get("ttl", 0.0)
		position += velocity * delta
		ttl -= delta
		projectile["position"] = position
		projectile["ttl"] = ttl
		enemy_projectiles[i] = projectile

		if ttl <= 0.0:
			to_remove.append(i)
			continue
		if position.x < left_dead_zone_px + 16.0 or position.x > viewport_size.x - right_dead_zone_px - 16.0:
			to_remove.append(i)
			continue
		if position.y < 310.0 or position.y > viewport_size.y - 44.0:
			to_remove.append(i)
			continue
		if position.distance_to(player_position) <= 34.0:
			_apply_player_damage(spitter_projectile_damage * enemy_damage_multiplier, "Spitter acid bolt")
			to_remove.append(i)
			enemy_touch_damage_tick = enemy_contact_cooldown_seconds

	if not to_remove.is_empty():
		to_remove.reverse()
		for index in to_remove:
			enemy_projectiles.remove_at(index)


func _update_enemy_contacts(delta: float) -> void:
	enemy_touch_damage_tick = max(0.0, enemy_touch_damage_tick - delta)
	if enemy_touch_damage_tick > 0.0:
		return

	if boss_active:
		var boss_position: Vector2 = boss.get("position", Vector2.ZERO)
		if boss_position.distance_to(player_position) <= 72.0:
			_apply_player_damage(boss_contact_damage * enemy_damage_multiplier, "Overlord slam")
			enemy_touch_damage_tick = enemy_contact_cooldown_seconds
			return

	for enemy in active_enemies:
		var enemy_position: Vector2 = enemy.get("position", Vector2.ZERO)
		if enemy_position.distance_to(player_position) > 50.0:
			continue
		var damage := 6.5
		if enemy.get("type", "drone") == "brute":
			damage = 11.0
		_apply_player_damage(damage * enemy_damage_multiplier, "Vexian " + String(enemy.get("type", "drone")))
		enemy_touch_damage_tick = enemy_contact_cooldown_seconds
		break


func _apply_player_damage(amount: float, source: String) -> void:
	if dash_time_left > 0.0:
		status_label.text = "Dash evaded %s." % source
		_spawn_vfx_burst(player_position, Color(0.84, 0.96, 1.0, 0.92), 5, 180.0, 0.24, 6.0)
		return
	health = clamp(health - amount, 0.0, max_health)
	combo_streak = 0
	combo_multiplier = 1.0
	combo_decay_time_left = 0.0
	feedback_bus.emit_feedback("hit")
	_play_sfx("hit")
	_spawn_vfx_burst(player_position, Color(1.0, 0.52, 0.65, 0.95), 7, 200.0, 0.26, 6.0)
	status_label.text = "Hit by %s: -%.0f HP" % [source, amount]
	if health > 0.0:
		return

	player_lives -= 1
	if player_lives <= 0:
		_end_run(false, "Cody was overrun by Vex forces.")
		return

	health = max_health
	hunger = max_hunger * 0.55
	player_position = get_viewport_rect().size * 0.5
	active_enemies.clear()
	enemy_projectiles.clear()
	vfx_particles.clear()
	wave_active = false
	wave_wait_tick = 2.5
	boss_active = false
	status_label.text = "Life lost. %d lives remaining." % player_lives


func _on_enemy_defeated(enemy: Dictionary) -> void:
	drones_defeated += 1
	_play_sfx("enemy_down")
	combo_streak += 1
	combo_decay_time_left = combo_timeout_seconds
	combo_multiplier = min(2.4, 1.0 + float(combo_streak - 1) * 0.12)
	max_combo_reached = float(max(max_combo_reached, combo_multiplier))
	var enemy_type: String = enemy.get("type", "drone")
	var enemy_pos := enemy.get("position", player_position) as Vector2
	_spawn_vfx_burst(enemy_pos, Color(0.78, 0.68, 1.0, 0.92), 8, 180.0, 0.30, 6.0)
	var current := int(bestiary_entries.get(enemy_type, 0))
	bestiary_entries[enemy_type] = current + 1
	_add_objective_progress("defeat", 1)

	var scrap_gain := 1
	var crystal_gain := 0
	if enemy_type == "brute":
		scrap_gain = 3
		crystal_gain = 2
	elif enemy_type == "spitter":
		scrap_gain = 2
		crystal_gain = 1

	if companion_id == "annalize":
		scrap_gain = int(ceil(scrap_gain * 1.3))
		if randf() < 0.45:
			crystal_gain += 1

	scrap_gain = _scaled_loot_value(scrap_gain)
	crystal_gain = _scaled_loot_value(crystal_gain)
	_scavenge_resources(scrap_gain, crystal_gain, 0, 0)
	var base_xp := 8 + wave_number
	var xp_gain := int(round(float(base_xp) * combo_multiplier))
	_grant_xp(xp_gain)


func _update_passive_scavenge(delta: float) -> void:
	passive_scavenge_tick += delta
	if passive_scavenge_tick < 5.0:
		return
	passive_scavenge_tick = 0.0
	var moving_bonus := 1 if left_vector.length() > 0.2 else 0
	_scavenge_resources(_scaled_loot_value(1 + moving_bonus), _scaled_loot_value(1 if randf() > 0.55 else 0), 0, 0)


func _scaled_loot_value(amount: int) -> int:
	return maxi(0, int(round(float(amount) * loot_gain_multiplier)))


func _scavenge_resources(scrap: int, crystals: int, melons: int, berries: int) -> void:
	inventory["human_scrap"] = int(inventory.get("human_scrap", 0)) + maxi(scrap, 0)
	inventory["alien_crystals"] = int(inventory.get("alien_crystals", 0)) + maxi(crystals, 0)
	inventory["star_melons"] = int(inventory.get("star_melons", 0)) + maxi(melons, 0)
	inventory["glow_berries"] = int(inventory.get("glow_berries", 0)) + maxi(berries, 0)
	_add_objective_progress("collect", maxi(scrap, 0) + maxi(crystals, 0) + maxi(melons, 0) + maxi(berries, 0))


func _consume_food() -> bool:
	var melons := int(inventory.get("star_melons", 0))
	var berries := int(inventory.get("glow_berries", 0))
	if melons <= 0 and berries <= 0:
		status_label.text = "No food available."
		return false

	if melons > 0:
		inventory["star_melons"] = melons - 1
		hunger = clamp(hunger + 34.0, 0.0, max_hunger)
	else:
		inventory["glow_berries"] = berries - 1
		hunger = clamp(hunger + 24.0, 0.0, max_hunger)
	status_label.text = "Food consumed."
	return true


func _grant_xp(amount: int) -> void:
	player_xp += maxi(amount, 0)
	var next_level_xp := _xp_for_next_level(player_level)
	while player_xp >= next_level_xp:
		player_xp -= next_level_xp
		player_level += 1
		max_health += progression_health_gain_per_level
		max_hunger += progression_hunger_gain_per_level
		health = max_health
		hunger = max_hunger
		skins_unlocked += 1
		status_label.text = "Level up! Cody reached level %d." % player_level
		next_level_xp = _xp_for_next_level(player_level)


func _xp_for_next_level(level: int) -> int:
	return progression_base_level_xp + level * progression_level_xp_growth


func _add_objective_progress(key: String, amount: int) -> void:
	if amount <= 0:
		return
	for i in objectives.size():
		var objective: Dictionary = objectives[i]
		if objective.get("key", "") != key:
			continue
		if bool(objective.get("completed", false)):
			break
		var progress := int(objective.get("progress", 0))
		var target := int(objective.get("target", 1))
		progress = mini(progress + amount, target)
		objective["progress"] = progress
		if progress >= target:
			objective["completed"] = true
			var reward := int(objective.get("reward_xp", 0))
			_grant_xp(reward)
			status_label.text = "Objective complete: %s (+%d XP)" % [objective.get("label", ""), reward]
			feedback_bus.emit_feedback("objective")
		objectives[i] = objective
		break


func _objectives_complete() -> bool:
	for objective in objectives:
		if not bool(objective.get("completed", false)):
			return false
	return true


func _objective_summary() -> String:
	var lines: Array[String] = []
	for objective in objectives:
		var prefix := "[x]" if bool(objective.get("completed", false)) else "[ ]"
		lines.append("%s %s %d/%d" % [prefix, objective.get("label", ""), int(objective.get("progress", 0)), int(objective.get("target", 0))])
	return _join_lines(lines, " | ")


func _join_lines(lines: Array[String], separator: String) -> String:
	var result := ""
	for i in lines.size():
		if i > 0:
			result += separator
		result += lines[i]
	return result


func _current_recipe() -> Dictionary:
	if recipe_index < 0 or recipe_index >= recipes.size():
		return recipes[0]
	return recipes[recipe_index]


func _craft_current_recipe() -> void:
	var recipe := _current_recipe()
	var unlock_level := int(recipe.get("unlock_level", 1))
	if player_level < unlock_level:
		status_label.text = "%s unlocks at level %d." % [recipe.get("name", "Recipe"), unlock_level]
		return
	var scrap_cost := int(recipe.get("scrap", 0))
	var crystal_cost := int(recipe.get("crystal", 0))
	var scrap := int(inventory.get("human_scrap", 0))
	var crystals := int(inventory.get("alien_crystals", 0))
	if scrap < scrap_cost or crystals < crystal_cost:
		status_label.text = "Not enough materials for %s." % recipe.get("name", "Recipe")
		return
	inventory["human_scrap"] = scrap - scrap_cost
	inventory["alien_crystals"] = crystals - crystal_cost
	var crafted_id := String(recipe.get("id", "pulse_blade"))
	crafted_items[crafted_id] = int(crafted_items.get(crafted_id, 0)) + 1
	_add_objective_progress("craft", 1)
	_grant_xp(18 + unlock_level * 4)
	status_label.text = "Crafted %s." % recipe.get("name", "Recipe")


func _bestiary_progress_count() -> int:
	var total := 0
	for key in bestiary_entries.keys():
		total += int(bestiary_entries[key])
	return total


func _can_unlock_super_beast() -> bool:
	return bestiary_pages >= goal_boss_unlock_pages and _bestiary_progress_count() >= goal_boss_unlock_entries


func _check_run_completion() -> void:
	if boss_active or boss_spawned:
		return
	if wave_number < goal_boss_unlock_min_wave:
		return
	if not _objectives_complete():
		return
	if not _can_unlock_super_beast():
		return
	_enter_boss_phase()


func _update_checkpoint_emitter(delta: float) -> void:
	checkpoint_emit_tick += delta
	if checkpoint_emit_tick < 20.0:
		return
	checkpoint_emit_tick = 0.0
	if game_ended:
		return
	checkpoint_updated.emit(_build_continue_snapshot())


func _enter_boss_phase() -> void:
	boss_spawned = true
	boss_active = true
	wave_active = false
	active_enemies.clear()
	enemy_projectiles.clear()
	vfx_particles.clear()
	boss = {
		"name": "Overlord Vex",
		"position": Vector2(viewport_size.x * 0.72, viewport_size.y * 0.55),
		"hp": boss_base_health + float(wave_number) * boss_health_per_wave,
		"max_hp": boss_base_health + float(wave_number) * boss_health_per_wave,
		"speed": 72.0
	}
	boss_attack_tick = 1.0
	player_state = PlayerState.SUPER_BEAST
	status_label.text = "Titan Protocol complete. Overlord Vex engaged!"
	feedback_bus.emit_feedback("boss")
	_play_sfx("boss_alarm")


func _update_boss_system(delta: float) -> void:
	if not boss_active:
		return
	var boss_position: Vector2 = boss.get("position", Vector2.ZERO)
	var boss_speed: float = boss.get("speed", 72.0)
	var target_direction := (player_position - boss_position).normalized()
	boss_position += target_direction * boss_speed * delta
	boss_position.x = clamp(boss_position.x, left_dead_zone_px + 80.0, viewport_size.x - right_dead_zone_px - 80.0)
	boss_position.y = clamp(boss_position.y, 340.0, viewport_size.y - 90.0)
	boss["position"] = boss_position

	boss_attack_tick -= delta
	if boss_attack_tick <= 0.0:
		boss_attack_tick = 2.4
		if boss_position.distance_to(player_position) < 180.0:
			_apply_player_damage(boss_shockwave_damage * enemy_damage_multiplier, "Overlord shockwave")
		else:
			_spawn_enemy()
			_spawn_enemy()
			status_label.text = "Overlord summoned reinforcements."


func _on_boss_defeated() -> void:
	boss_active = false
	enemy_projectiles.clear()
	vfx_particles.clear()
	player_state = PlayerState.RIFT_WEAVER
	status_label.text = "Overlord Vex defeated. Alpha Strain extracted."
	feedback_bus.emit_feedback("objective")
	_end_run(true, "Rift Weaver protocol stabilized the final rift home.")


func _show_tutorial_step(step_index: int) -> void:
	tutorial_index = step_index
	if tutorial_index >= tutorial_steps.size():
		tutorial_panel.visible = false
		is_soft_paused = false
		tutorial_completed_this_session = true
		status_label.text = "Tutorial complete. Begin tracking Vexian signatures."
		return

	is_soft_paused = true
	tutorial_panel.visible = true
	tutorial_body.text = "Step %d/%d\n%s" % [tutorial_index + 1, tutorial_steps.size(), tutorial_steps[tutorial_index]]


func _on_tutorial_next_pressed() -> void:
	_show_tutorial_step(tutorial_index + 1)


func _on_tutorial_skip_pressed() -> void:
	tutorial_index = tutorial_steps.size()
	_show_tutorial_step(tutorial_index)


func _build_continue_snapshot() -> Dictionary:
	return {
		"health": health,
		"hunger": hunger,
		"max_health": max_health,
		"max_hunger": max_hunger,
		"player_level": player_level,
		"player_xp": player_xp,
		"player_lives": player_lives,
		"companion_id": companion_id,
		"keeley_dna_upgrade": keeley_dna_upgrade,
		"inventory": inventory.duplicate(true),
		"crafted_items": crafted_items.duplicate(true),
		"bestiary_pages": bestiary_pages,
		"bestiary_entries": bestiary_entries.duplicate(true),
		"wave_number": wave_number,
		"current_biome_index": current_biome_index,
		"objectives": objectives.duplicate(true),
		"skins_unlocked": skins_unlocked,
		"secret_walls_broken": secret_walls_broken,
		"drones_defeated": drones_defeated,
		"pages_collected_this_run": pages_collected_this_run,
		"boss_spawned": boss_spawned,
		"dash_cooldown_remaining": dash_cooldown_remaining,
		"max_combo_reached": max_combo_reached,
		"dash_uses_this_run": dash_uses_this_run
	}


func _load_snapshot(snapshot: Dictionary) -> void:
	if typeof(snapshot) != TYPE_DICTIONARY or snapshot.is_empty():
		return
	health = float(snapshot.get("health", health))
	hunger = float(snapshot.get("hunger", hunger))
	max_health = float(snapshot.get("max_health", max_health))
	max_hunger = float(snapshot.get("max_hunger", max_hunger))
	player_level = int(snapshot.get("player_level", player_level))
	player_xp = int(snapshot.get("player_xp", player_xp))
	player_lives = int(snapshot.get("player_lives", player_lives))
	companion_id = String(snapshot.get("companion_id", companion_id))
	keeley_dna_upgrade = bool(snapshot.get("keeley_dna_upgrade", keeley_dna_upgrade))
	bestiary_pages = int(snapshot.get("bestiary_pages", bestiary_pages))
	wave_number = int(snapshot.get("wave_number", wave_number))
	current_biome_index = clamp(int(snapshot.get("current_biome_index", current_biome_index)), 0, biome_names.size() - 1)
	skins_unlocked = int(snapshot.get("skins_unlocked", skins_unlocked))
	secret_walls_broken = int(snapshot.get("secret_walls_broken", secret_walls_broken))
	drones_defeated = int(snapshot.get("drones_defeated", drones_defeated))
	pages_collected_this_run = int(snapshot.get("pages_collected_this_run", pages_collected_this_run))
	boss_spawned = bool(snapshot.get("boss_spawned", false))
	dash_cooldown_remaining = float(snapshot.get("dash_cooldown_remaining", 0.0))
	max_combo_reached = float(snapshot.get("max_combo_reached", max_combo_reached))
	dash_uses_this_run = int(snapshot.get("dash_uses_this_run", dash_uses_this_run))
	var loaded_inventory: Dictionary = snapshot.get("inventory", {})
	if typeof(loaded_inventory) == TYPE_DICTIONARY:
		inventory = loaded_inventory
	var loaded_crafted: Dictionary = snapshot.get("crafted_items", {})
	if typeof(loaded_crafted) == TYPE_DICTIONARY:
		crafted_items = loaded_crafted
	var loaded_entries: Dictionary = snapshot.get("bestiary_entries", {})
	if typeof(loaded_entries) == TYPE_DICTIONARY:
		bestiary_entries = loaded_entries
	var loaded_objectives: Array = snapshot.get("objectives", [])
	if typeof(loaded_objectives) == TYPE_ARRAY:
		objectives = loaded_objectives
	companion_select.select(0 if companion_id == "keeley" else 1)
	_apply_companion_portrait()
	keeley_upgrade_toggle.button_pressed = keeley_dna_upgrade
	_update_biome_music(true)
	active_enemies.clear()
	wave_active = false
	wave_wait_tick = 1.0
	if boss_spawned and not _can_unlock_super_beast():
		boss_spawned = false


func _end_run(victory: bool, reason: String) -> void:
	if game_ended:
		return
	game_ended = true
	enemy_projectiles.clear()
	vfx_particles.clear()
	is_soft_paused = true
	pause_panel.visible = false
	end_panel.visible = true
	end_title.text = "VICTORY" if victory else "DEFEAT"
	end_subtitle.text = "%s\nWave reached: %d | Drones defeated: %d | Duration: %s" % [
		reason,
		wave_number,
		drones_defeated,
		_format_time(run_elapsed_seconds)
	]
	var preview_score := _compute_run_score(victory)
	end_subtitle.text += "\nRun Score: %d | Rank: %s" % [preview_score, _score_rank(preview_score)]
	end_subtitle.text += "\nMax combo: x%.2f | Dash uses: %d" % [max_combo_reached, dash_uses_this_run]
	pending_result = _build_session_summary(victory, {}, reason)


func _build_session_summary(victory: bool, snapshot: Dictionary, reason: String) -> Dictionary:
	var bank_scrap_gain := int(inventory.get("human_scrap", 0)) / 4
	var bank_crystal_gain := int(inventory.get("alien_crystals", 0)) / 5
	var run_score := _compute_run_score(victory)
	var rank := _score_rank(run_score)
	return {
		"victory": victory,
		"reason": reason,
		"wave_reached": wave_number,
		"duration_seconds": int(run_elapsed_seconds),
		"drones_defeated": drones_defeated,
		"bestiary_pages_collected": pages_collected_this_run,
		"meta_xp_gain": 35 + (wave_number * 8) + (40 if victory else 0),
		"bank_scrap_gain": bank_scrap_gain,
		"bank_crystal_gain": bank_crystal_gain,
		"skins_unlocked": skins_unlocked,
		"run_score": run_score,
		"rank": rank,
		"max_combo_reached": max_combo_reached,
		"dash_uses": dash_uses_this_run,
		"tutorial_completed": tutorial_completed_this_session or bool(profile.get("tutorial_completed", false)),
		"continue_snapshot": snapshot
	}


func _compute_run_score(victory: bool) -> int:
	var score := wave_number * 100
	score += drones_defeated * 4
	score += int(round(max_combo_reached * 120.0))
	score += pages_collected_this_run * 55
	score += int(health)
	score += 450 if victory else 0
	return maxi(score, 0)


func _score_rank(score: int) -> String:
	if score >= 2200:
		return "S"
	if score >= 1500:
		return "A"
	if score >= 900:
		return "B"
	return "C"


func _format_time(seconds: float) -> String:
	var total := int(seconds)
	var minutes := total / 60
	var rem := total % 60
	return "%02d:%02d" % [minutes, rem]


func _update_hud() -> void:
	health_bar.max_value = max_health
	hunger_bar.max_value = max_hunger
	health_bar.value = health
	hunger_bar.value = hunger
	state_label.text = "State: %s | Input: %s | Lives: %d/%d | Diff: %s | Perf: %s" % [
		_state_text(player_state),
		_input_text(input_mode),
		player_lives,
		max_lives,
		difficulty_name.capitalize(),
		performance_mode.capitalize()
	]
	biome_label.text = "Biome: %s" % biome_names[current_biome_index]
	wave_label.text = "Wave: %d (%s)" % [wave_number, "active" if wave_active else "prep"]
	boss_label.text = "Boss: Overlord Vex engaged" if boss_active else "Boss: pending"
	var input_locked := game_ended or tutorial_panel.visible
	rhino_button.disabled = player_state == PlayerState.RHINO_CHARGE or input_locked
	pause_button.disabled = game_ended or tutorial_panel.visible
	travel_biome_button.disabled = input_locked
	scavenge_button.disabled = input_locked
	recipe_select.disabled = input_locked
	craft_button.disabled = input_locked
	gain_page_button.disabled = input_locked
	action_button.disabled = input_locked
	dash_button.disabled = input_locked or dash_cooldown_remaining > 0.0 or player_state == PlayerState.RHINO_CHARGE

	if player_state == PlayerState.RHINO_CHARGE:
		rhino_timer_label.text = "Rhino timer: %.1fs" % rhino_time_left
	else:
		rhino_timer_label.text = "Rhino ready (6.0s burst) | Run time: %s" % _format_time(run_elapsed_seconds)

	var scrap := int(inventory.get("human_scrap", 0))
	var crystals := int(inventory.get("alien_crystals", 0))
	var melons := int(inventory.get("star_melons", 0))
	var berries := int(inventory.get("glow_berries", 0))
	inventory_label.text = "Inventory -> Scrap:%d  Crystals:%d  Star-Melons:%d  Glow-Berries:%d" % [scrap, crystals, melons, berries]

	var recipe := _current_recipe()
	progression_label.text = "Lv %d (%d/%d XP) | Bestiary pages:%d | Entries:%d | Skins:%d | Recipe:%s [S:%d C:%d L:%d]" % [
		player_level,
		player_xp,
		_xp_for_next_level(player_level),
		bestiary_pages,
		_bestiary_progress_count(),
		skins_unlocked,
		recipe.get("name", ""),
		int(recipe.get("scrap", 0)),
		int(recipe.get("crystal", 0)),
		int(recipe.get("unlock_level", 1))
	]
	quest_label.text = "Objectives: %s" % _objective_summary()

	loot_label.text = "Annalize active: +30%% drops" if companion_id == "annalize" else "Keeley active: crowd control on 5+ enemies"
	combo_label.text = "Combo x%.2f (%d)" % [combo_multiplier, combo_streak] if combo_streak > 1 else "Combo x1.00"
	if dash_time_left > 0.0:
		dash_label.text = "Dash: ACTIVE"
		dash_button.text = "DASHING"
	elif dash_cooldown_remaining > 0.0:
		dash_label.text = "Dash CD: %.1fs" % dash_cooldown_remaining
		dash_button.text = "DASH CD"
	else:
		dash_label.text = "Dash: READY"
		dash_button.text = "DASH"
	var active_hotbar_item := String(hotbar_items[selected_hotbar_index].get("label", "Item"))
	hotbar_title.text = "Hotbar - %s" % active_hotbar_item
	var ui_pulse := 0.88 + 0.12 * (0.5 + 0.5 * sin(Time.get_ticks_msec() / 300.0))
	action_button.modulate = Color(0.85 + 0.15 * ui_pulse, 0.95, 1.0, 1.0)
	rhino_button.modulate = Color(0.92, 0.80 + 0.20 * ui_pulse, 1.0, 1.0)
	scavenge_button.modulate = Color(0.90, 0.96, 0.98 + 0.02 * ui_pulse, 1.0)
	dash_button.modulate = Color(0.94, 0.94 + 0.06 * ui_pulse, 1.0, 1.0)
	perf_metrics_label.visible = show_perf_hud
	if show_perf_hud:
		perf_metrics_label.text = "FPS:%d | Enemies:%d/%d | Projectiles:%d/%d | VFX:%d/%d" % [
			Engine.get_frames_per_second(),
			active_enemies.size(),
			max_active_enemies,
			enemy_projectiles.size(),
			max_active_projectiles,
			vfx_particles.size(),
			max_active_vfx_particles
		]

	for i in hotbar_buttons.size():
		hotbar_buttons[i].modulate = Color(1, 1, 1, 1)
		if i == selected_hotbar_index:
			hotbar_buttons[i].modulate = Color("#7ff5ff")


func _state_text(state: int) -> String:
	match state:
		PlayerState.NORMAL:
			return "NORMAL"
		PlayerState.EXHAUSTED:
			return "EXHAUSTED"
		PlayerState.RHINO_CHARGE:
			return "RHINO_CHARGE"
		PlayerState.SUPER_BEAST:
			return "SUPER_BEAST"
		PlayerState.RIFT_WEAVER:
			return "RIFT_WEAVER"
	return "UNKNOWN"


func _input_text(mode: int) -> String:
	match mode:
		InputMode.ATTACK_MODE:
			return "ATTACK_MODE"
		InputMode.EAT_MODE:
			return "EAT_MODE"
		InputMode.RHINO_BOOST_MODE:
			return "RHINO_BOOST_MODE"
	return "UNKNOWN"


func _on_hotbar_selected(index: int) -> void:
	selected_hotbar_index = index
	status_label.text = "Selected slot %d: %s" % [index + 1, hotbar_items[index].get("label", "Item")]
	_play_sfx("ui_click")
	_apply_hotbar_context_rules()


func _on_action_pressed() -> void:
	if game_ended:
		return
	if input_mode == InputMode.EAT_MODE:
		_consume_food()
	elif input_mode == InputMode.RHINO_BOOST_MODE:
		_fire_attack("Action button", player_direction)
	else:
		var aim_direction := right_vector.normalized() if right_vector.length() > 0.2 else player_direction
		_fire_attack("Action button", aim_direction)


func _on_dash_pressed() -> void:
	if game_ended:
		return
	if dash_cooldown_remaining > 0.0:
		return
	if player_state == PlayerState.RHINO_CHARGE:
		return
	var dash_vector := left_vector
	if dash_vector.length() < 0.25:
		dash_vector = right_vector
	if dash_vector.length() < 0.25:
		dash_vector = player_direction
	dash_direction = dash_vector.normalized()
	dash_time_left = dash_duration_seconds
	dash_cooldown_remaining = dash_cooldown_seconds
	dash_uses_this_run += 1
	status_label.text = "Dash burst activated."
	feedback_bus.emit_feedback("attack")
	_play_sfx("dash")
	_spawn_vfx_burst(player_position, Color(0.72, 0.95, 1.0, 0.95), 10, 210.0, 0.30, 6.0)


func _on_rhino_pressed() -> void:
	if game_ended:
		return
	player_state = PlayerState.RHINO_CHARGE
	rhino_time_left = float(config.get("mutationStates", {}).get("rhinoCharge", {}).get("durationSeconds", 6.0))
	secret_walls_broken += randi_range(0, 2)
	_add_objective_progress("rhino", 1)
	status_label.text = "Rhino Charge activated!"
	feedback_bus.emit_feedback("rhino")
	_apply_hotbar_context_rules()


func _on_travel_biome_pressed() -> void:
	if game_ended:
		return
	current_biome_index = (current_biome_index + 1) % biome_names.size()
	status_label.text = "Moved to biome: %s" % biome_names[current_biome_index]
	_play_sfx("ui_click")
	_update_biome_music()


func _on_companion_changed(index: int) -> void:
	companion_id = "keeley" if index == 0 else "annalize"
	companion_label.text = "Companion switched to %s" % companion_select.get_item_text(index)
	_play_sfx("ui_click")
	_apply_companion_portrait()


func _on_keeley_upgrade_toggled(enabled: bool) -> void:
	keeley_dna_upgrade = enabled
	status_label.text = "Keeley DNA upgrade %s" % ("enabled" if enabled else "disabled")


func _on_recipe_selected(index: int) -> void:
	recipe_index = index


func _on_craft_pressed() -> void:
	if game_ended:
		return
	_craft_current_recipe()


func _on_scavenge_pressed() -> void:
	if game_ended:
		return
	var scrap_gain := _scaled_loot_value(randi_range(2, 5))
	var crystal_gain := _scaled_loot_value(randi_range(1, 3))
	var melon_gain := _scaled_loot_value(1 if randf() > 0.55 else 0)
	var berry_gain := _scaled_loot_value(1 if randf() > 0.45 else 0)
	_scavenge_resources(scrap_gain, crystal_gain, melon_gain, berry_gain)
	_grant_xp(10)
	status_label.text = "Scavenge burst: +%d scrap, +%d crystals." % [scrap_gain, crystal_gain]


func _on_gain_page_pressed() -> void:
	if game_ended:
		return
	bestiary_pages += 1
	pages_collected_this_run += 1
	_grant_xp(12)
	feedback_bus.emit_feedback("objective")
	if _can_unlock_super_beast():
		status_label.text = "Titan Protocol complete: Super Beast ready for Overlord arena."
	else:
		status_label.text = "Collected a holographic Bestiary page."


func _on_pause_pressed() -> void:
	if game_ended:
		return
	if tutorial_panel.visible:
		return
	is_soft_paused = true
	pause_panel.visible = true
	_play_sfx("ui_click")


func _on_resume_pressed() -> void:
	is_soft_paused = false
	pause_panel.visible = false
	_play_sfx("ui_click")


func _on_save_and_menu_pressed() -> void:
	var snapshot := _build_continue_snapshot()
	var result := _build_session_summary(false, snapshot, "Paused and returned to menu")
	session_finished.emit(false, result)
	queue_free()


func _on_end_run_pressed() -> void:
	_end_run(false, "Run manually ended from pause menu.")


func _on_retry_pressed() -> void:
	var result := pending_result.duplicate(true)
	if result.is_empty():
		result = _build_session_summary(false, {}, "Run restarted from end panel")
	result["request_restart"] = true
	session_finished.emit(bool(result.get("victory", false)), result)
	queue_free()


func _on_return_menu_pressed() -> void:
	var result := pending_result.duplicate(true)
	if result.is_empty():
		result = _build_session_summary(end_title.text == "VICTORY", {}, "Run finished")
	session_finished.emit(bool(result.get("victory", false)), result)
	queue_free()
