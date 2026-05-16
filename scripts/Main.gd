extends Node2D

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
const SAVE_FILE_PATH := "user://rift_save.json"

var config: Dictionary = {}

var player_state: int = PlayerState.NORMAL
var input_mode: int = InputMode.ATTACK_MODE
var companion_id := "keeley"
var keeley_dna_upgrade := false

var health := 100.0
var hunger := 100.0
var max_health := 100.0
var max_hunger := 100.0

var base_move_speed := 310.0
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
	{"key": "collect", "label": "Collect resources", "progress": 0, "target": 25, "reward_xp": 40, "completed": false},
	{"key": "defeat", "label": "Defeat Vexian drones", "progress": 0, "target": 18, "reward_xp": 45, "completed": false},
	{"key": "craft", "label": "Craft weapons", "progress": 0, "target": 3, "reward_xp": 60, "completed": false},
	{"key": "rhino", "label": "Use Rhino Charge", "progress": 0, "target": 2, "reward_xp": 35, "completed": false}
]

var player_level := 1
var player_xp := 0
var skins_unlocked := 1

var bestiary_pages := 0
var bestiary_entries: Dictionary = {}
var secret_walls_broken := 0

var wave_number := 0
var wave_active := false
var wave_spawn_remaining := 0
var wave_spawn_tick := 0.0
var wave_wait_tick := 1.6
var enemy_touch_damage_tick := 0.0
var active_enemies: Array[Dictionary] = []
var next_enemy_id := 1
var wave_base_enemies := 4
var wave_enemy_growth := 2
var wave_spawn_radius := 430.0
var enemy_contact_cooldown_seconds := 0.65

var rhino_time_left := 0.0
var attack_cooldown := 0.0
var companion_tick := 0.0
var passive_scavenge_tick := 0.0
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
var companion_label: Label
var loot_label: Label
var rhino_timer_label: Label
var inventory_label: Label
var quest_label: Label
var progression_label: Label
var action_button: Button
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
var save_button: Button
var load_button: Button
var reset_objectives_button: Button
var left_stick_base: Panel
var left_stick_knob: Panel
var right_stick_base: Panel
var right_stick_knob: Panel


func _ready() -> void:
	randomize()
	_load_config()
	_build_hud()
	_recalculate_input_regions()
	player_position = get_viewport_rect().size * 0.5
	status_label.text = "Welcome to RIFT - Code Max Studios prototype"
	_apply_hotbar_context_rules()
	_start_next_wave()
	_update_hud()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_recalculate_input_regions()


func _unhandled_input(event: InputEvent) -> void:
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

	_update_survival(delta)
	_update_player_state(delta)
	_apply_hotbar_context_rules()
	_update_movement(delta)
	_update_combat(delta)
	_update_companion_logic(delta)
	_update_wave_system(delta)
	_update_passive_scavenge(delta)
	_update_enemy_contacts(delta)
	_update_hud()
	queue_redraw()


func _draw() -> void:
	var screen_size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color("#0b1022"))

	# Edge dead-zones used to ignore accidental palm touches on tablets.
	draw_rect(Rect2(0, 0, left_dead_zone_px, screen_size.y), Color(1, 0.2, 0.35, 0.18))
	draw_rect(Rect2(screen_size.x - right_dead_zone_px, 0, right_dead_zone_px, screen_size.y), Color(1, 0.2, 0.35, 0.18))

	# Dynamic joystick spawn areas.
	draw_rect(left_spawn_rect, Color(0.15, 0.8, 1.0, 0.08), true)
	draw_rect(right_spawn_rect, Color(0.66, 0.42, 1.0, 0.08), true)

	draw_rect(Rect2(0, 70, screen_size.x, 8), Color(0.26, 0.85, 1.0, 0.4))

	var player_color := Color("#76efff")
	if player_state == PlayerState.EXHAUSTED:
		player_color = Color("#ff8db1")
	elif player_state == PlayerState.RHINO_CHARGE:
		player_color = Color("#8af7ff")
		draw_circle(player_position, 56, Color(0.42, 0.49, 1.0, 0.35))
		draw_circle(player_position, 76, Color(0.33, 0.82, 1.0, 0.2))

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
		draw_circle(enemy_position, 16, enemy_color)
		var bar_width := 34.0
		var hp_ratio := clamp(enemy_hp / max(enemy_max_hp, 0.001), 0.0, 1.0)
		draw_rect(Rect2(enemy_position.x - bar_width * 0.5, enemy_position.y - 28, bar_width, 4), Color(0.08, 0.08, 0.2, 1))
		draw_rect(Rect2(enemy_position.x - bar_width * 0.5, enemy_position.y - 28, bar_width * hp_ratio, 4), Color("#69f2b0"))


func _load_config() -> void:
	var file := FileAccess.open("res://android_ui_state_config.json", FileAccess.READ)
	if file == null:
		push_warning("Config not found, using defaults.")
		return

	var parsed := JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Config parse failed, using defaults.")
		return

	config = parsed
	var input_layout: Dictionary = config.get("inputLayout", {})
	var deadzones: Dictionary = input_layout.get("edgeDeadZonesPx", {})
	left_dead_zone_px = float(deadzones.get("left", left_dead_zone_px))
	right_dead_zone_px = float(deadzones.get("right", right_dead_zone_px))

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

	var crafting: Dictionary = config.get("crafting", {})
	var recipe_overrides = crafting.get("recipes", [])
	if typeof(recipe_overrides) == TYPE_ARRAY:
		_apply_recipe_overrides(recipe_overrides)


func _apply_recipe_overrides(recipe_overrides: Array) -> void:
	for override_entry in recipe_overrides:
		if typeof(override_entry) != TYPE_DICTIONARY:
			continue
		var override_dict: Dictionary = override_entry
		var target_id := String(override_dict.get("id", ""))
		if target_id == "":
			continue
		for i in recipes.size():
			var recipe: Dictionary = recipes[i]
			if String(recipe.get("id", "")) != target_id:
				continue
			recipe["scrap"] = int(override_dict.get("scrap", recipe.get("scrap", 0)))
			recipe["crystal"] = int(override_dict.get("crystal", recipe.get("crystal", 0)))
			recipe["unlock_level"] = int(override_dict.get("unlockLevel", recipe.get("unlock_level", 1)))
			recipes[i] = recipe
			break


func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	hud_root = Control.new()
	hud_root.name = "HUD"
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(hud_root)

	var title := Label.new()
	title.text = "RIFT: The Bestiary Protocol - Code Max Studios"
	title.position = Vector2(20, 12)
	title.add_theme_font_size_override("font_size", 24)
	hud_root.add_child(title)

	state_label = Label.new()
	state_label.position = Vector2(20, 48)
	state_label.add_theme_font_size_override("font_size", 18)
	hud_root.add_child(state_label)

	biome_label = Label.new()
	biome_label.position = Vector2(450, 48)
	biome_label.add_theme_font_size_override("font_size", 18)
	hud_root.add_child(biome_label)

	wave_label = Label.new()
	wave_label.position = Vector2(760, 48)
	wave_label.add_theme_font_size_override("font_size", 18)
	hud_root.add_child(wave_label)

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

	companion_label = Label.new()
	companion_label.position = Vector2(20, 196)
	companion_label.size = Vector2(980, 26)
	hud_root.add_child(companion_label)

	loot_label = Label.new()
	loot_label.position = Vector2(20, 224)
	loot_label.size = Vector2(980, 24)
	hud_root.add_child(loot_label)

	status_label = Label.new()
	status_label.position = Vector2(20, 252)
	status_label.size = Vector2(1200, 24)
	hud_root.add_child(status_label)

	rhino_timer_label = Label.new()
	rhino_timer_label.position = Vector2(20, 282)
	rhino_timer_label.size = Vector2(360, 24)
	hud_root.add_child(rhino_timer_label)

	inventory_label = Label.new()
	inventory_label.position = Vector2(20, 312)
	inventory_label.size = Vector2(1200, 24)
	hud_root.add_child(inventory_label)

	progression_label = Label.new()
	progression_label.position = Vector2(20, 340)
	progression_label.size = Vector2(1200, 24)
	hud_root.add_child(progression_label)

	quest_label = Label.new()
	quest_label.position = Vector2(20, 368)
	quest_label.size = Vector2(1240, 52)
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

	save_button = Button.new()
	save_button.text = "Save"
	save_button.position = Vector2(1730, 80)
	save_button.size = Vector2(80, 42)
	save_button.pressed.connect(_on_save_pressed)
	hud_root.add_child(save_button)

	load_button = Button.new()
	load_button.text = "Load"
	load_button.position = Vector2(1820, 80)
	load_button.size = Vector2(80, 42)
	load_button.pressed.connect(_on_load_pressed)
	hud_root.add_child(load_button)

	reset_objectives_button = Button.new()
	reset_objectives_button.text = "Reset Objectives"
	reset_objectives_button.position = Vector2(1730, 132)
	reset_objectives_button.size = Vector2(170, 42)
	reset_objectives_button.pressed.connect(_on_reset_objectives_pressed)
	hud_root.add_child(reset_objectives_button)

	hotbar_container = HBoxContainer.new()
	hotbar_container.position = Vector2(690, 980)
	hotbar_container.add_theme_constant_override("separation", 10)
	hud_root.add_child(hotbar_container)

	for i in hotbar_items.size():
		var button := Button.new()
		button.custom_minimum_size = Vector2(140, 74)
		button.text = "%d: %s" % [i + 1, hotbar_items[i].get("label", "Item")]
		button.pressed.connect(_on_hotbar_selected.bind(i))
		hotbar_container.add_child(button)
		hotbar_buttons.append(button)

	action_button = Button.new()
	action_button.position = Vector2(1570, 920)
	action_button.size = Vector2(280, 120)
	action_button.pressed.connect(_on_action_pressed)
	action_button.text = "ATTACK"
	hud_root.add_child(action_button)

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

	_on_hotbar_selected(selected_hotbar_index)


func _recalculate_input_regions() -> void:
	viewport_size = get_viewport_rect().size
	var input_layout: Dictionary = config.get("inputLayout", {})
	left_spawn_rect = _rect_from_norm(input_layout.get("leftJoystick", {}).get("spawnArea", {}), Rect2(0, viewport_size.y * 0.54, viewport_size.x * 0.4, viewport_size.y * 0.4))
	right_spawn_rect = _rect_from_norm(input_layout.get("rightJoystick", {}).get("spawnArea", {}), Rect2(viewport_size.x * 0.6, viewport_size.y * 0.52, viewport_size.x * 0.35, viewport_size.y * 0.42))

	if hotbar_container:
		hotbar_container.position = Vector2((viewport_size.x - hotbar_container.size.x) * 0.5, viewport_size.y - 96)
	if action_button:
		action_button.position = Vector2(viewport_size.x - 320, viewport_size.y - 150)


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
		if _is_dead_zone(position):
			return
		if left_touch_id == INVALID_TOUCH_ID and left_spawn_rect.has_point(position):
			left_touch_id = touch_id
			left_origin = position
			left_vector = Vector2.ZERO
			_show_stick(left_stick_base, left_stick_knob, left_origin)
			return
		if right_touch_id == INVALID_TOUCH_ID and right_spawn_rect.has_point(position):
			right_touch_id = touch_id
			right_origin = position
			right_touch_start = position
			right_touch_start_msec = Time.get_ticks_msec()
			right_vector = Vector2.ZERO
			_show_stick(right_stick_base, right_stick_knob, right_origin)
			return
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


func _update_survival(delta: float) -> void:
	var hunger_drain_rate := 1.4
	if player_state == PlayerState.RHINO_CHARGE:
		hunger_drain_rate = 2.4
	hunger = clamp(hunger - hunger_drain_rate * delta, 0.0, max_hunger)

	if player_state == PlayerState.EXHAUSTED:
		health = clamp(health - (1.8 * delta), 0.0, max_health)
	elif wave_active:
		health = clamp(health + (0.35 * delta), 0.0, max_health)


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


func _apply_hotbar_context_rules() -> void:
	loadout_move_speed_multiplier = 1.0
	if player_state == PlayerState.RHINO_CHARGE:
		input_mode = InputMode.RHINO_BOOST_MODE
		action_button.text = "RAMMING SPEED"
		hotbar_container.visible = false
		return

	hotbar_container.visible = true
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
	if velocity.length() > 0.05:
		player_direction = velocity.normalized()
	var speed := base_move_speed * state_move_speed_multiplier * loadout_move_speed_multiplier
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
	var attack_dir := facing
	if attack_dir.length() < 0.2:
		attack_dir = player_direction

	if input_mode == InputMode.RHINO_BOOST_MODE:
		var rhino_kills := _damage_enemies_radius(player_position, 150.0, 75.0)
		secret_walls_broken += 1 if rhino_kills > 0 else 0
		if rhino_kills > 0:
			status_label.text = "Rhino impact shattered %d targets! (%s)" % [rhino_kills, source]
		else:
			status_label.text = "Rhino impact missed. (%s)" % source
		return

	var selected_tag := String(hotbar_items[selected_hotbar_index].get("tag", "tool"))
	var damage := 26.0
	var range := 210.0
	if selected_tag == "heavy_weapon":
		damage = 42.0
		range = 240.0

	var kills_hit := _damage_enemies_arc(player_position, attack_dir, range, 0.88, damage)
	if kills_hit > 0:
		status_label.text = "Fired and downed %d drone(s). (%s)" % [kills_hit, source]
	else:
		status_label.text = "Fired at nearby drones. (%s)" % source


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
		var alignment := to_enemy.normalized().dot(direction)
		if alignment < dot_threshold:
			continue
		enemy["hp"] = float(enemy.get("hp", 0.0)) - damage
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
		var railgun_kills := _damage_enemies_arc(player_position, player_direction, 340.0, 0.72, 36.0)
		companion_label.text = "Annalize railgun support fired (%d kills)." % railgun_kills
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
	if health <= 0.0:
		health = max_health
		hunger = max_hunger * 0.55
		player_position = get_viewport_rect().size * 0.5
		status_label.text = "Cody was overwhelmed. Quick recovery activated."
		active_enemies.clear()
		wave_active = false
		wave_wait_tick = 3.0
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
		wave_wait_tick = 4.0
		_grant_xp(35 + wave_number * 5)
		status_label.text = "Wave %d cleared! Bonus rewards earned." % wave_number
		_scavenge_resources(3 + wave_number, 1 + int(wave_number / 2), 1, 1)


func _start_next_wave() -> void:
	wave_number += 1
	wave_active = true
	wave_spawn_remaining = wave_base_enemies + wave_number * wave_enemy_growth
	wave_spawn_tick = 0.15
	status_label.text = "Wave %d started: Vexian drones incoming." % wave_number


func _spawn_enemy() -> void:
	var spawn_radius := wave_spawn_radius
	var angle := randf_range(0.0, TAU)
	var enemy_position := player_position + Vector2.RIGHT.rotated(angle) * spawn_radius
	enemy_position.x = clamp(enemy_position.x, left_dead_zone_px + 50.0, viewport_size.x - right_dead_zone_px - 50.0)
	enemy_position.y = clamp(enemy_position.y, 360.0, viewport_size.y - 100.0)

	var enemy_type := "drone"
	var hp := 45.0 + (wave_number * 4.0)
	var speed := 72.0 + (wave_number * 2.5)
	var roll := randf()
	if roll > 0.85:
		enemy_type = "brute"
		hp *= 1.9
		speed *= 0.72
	elif roll > 0.62:
		enemy_type = "spitter"
		hp *= 1.2
		speed *= 1.12

	var enemy: Dictionary = {
		"id": next_enemy_id,
		"type": enemy_type,
		"position": enemy_position,
		"hp": hp,
		"max_hp": hp,
		"speed": speed
	}
	next_enemy_id += 1
	active_enemies.append(enemy)


func _update_enemies(delta: float) -> void:
	for i in active_enemies.size():
		var enemy: Dictionary = active_enemies[i]
		var enemy_position: Vector2 = enemy.get("position", Vector2.ZERO)
		var enemy_speed: float = enemy.get("speed", 60.0)
		var drift := Vector2(randf_range(-0.35, 0.35), randf_range(-0.35, 0.35))
		var direction := (player_position - enemy_position).normalized()
		enemy_position += (direction + drift).normalized() * enemy_speed * delta
		enemy_position.x = clamp(enemy_position.x, left_dead_zone_px + 35.0, viewport_size.x - right_dead_zone_px - 35.0)
		enemy_position.y = clamp(enemy_position.y, 330.0, viewport_size.y - 60.0)
		enemy["position"] = enemy_position
		active_enemies[i] = enemy


func _update_enemy_contacts(delta: float) -> void:
	enemy_touch_damage_tick = max(0.0, enemy_touch_damage_tick - delta)
	if enemy_touch_damage_tick > 0.0:
		return

	for enemy in active_enemies:
		var enemy_position: Vector2 = enemy.get("position", Vector2.ZERO)
		if enemy_position.distance_to(player_position) > 50.0:
			continue

		var damage := 6.5
		if enemy.get("type", "drone") == "brute":
			damage = 11.0
		health = clamp(health - damage, 0.0, max_health)
		enemy_touch_damage_tick = enemy_contact_cooldown_seconds
		status_label.text = "Took %.0f damage from %s." % [damage, enemy.get("type", "drone")]
		break


func _on_enemy_defeated(enemy: Dictionary) -> void:
	var enemy_type: String = enemy.get("type", "drone")
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

	_scavenge_resources(scrap_gain, crystal_gain, 0, 0)
	_grant_xp(7 + wave_number)


func _update_passive_scavenge(delta: float) -> void:
	passive_scavenge_tick += delta
	if passive_scavenge_tick < 5.0:
		return

	passive_scavenge_tick = 0.0
	var moving_bonus := 0
	if left_vector.length() > 0.2:
		moving_bonus = 1
	_scavenge_resources(1 + moving_bonus, 1 if randf() > 0.55 else 0, 0, 0)


func _scavenge_resources(scrap: int, crystals: int, melons: int, berries: int) -> void:
	inventory["human_scrap"] = int(inventory.get("human_scrap", 0)) + max(scrap, 0)
	inventory["alien_crystals"] = int(inventory.get("alien_crystals", 0)) + max(crystals, 0)
	inventory["star_melons"] = int(inventory.get("star_melons", 0)) + max(melons, 0)
	inventory["glow_berries"] = int(inventory.get("glow_berries", 0)) + max(berries, 0)
	_add_objective_progress("collect", max(scrap, 0) + max(crystals, 0) + max(melons, 0) + max(berries, 0))


func _consume_food() -> bool:
	var melons := int(inventory.get("star_melons", 0))
	var berries := int(inventory.get("glow_berries", 0))
	if melons <= 0 and berries <= 0:
		status_label.text = "No food in inventory. Scavenge berries or melons."
		return false

	if melons > 0:
		inventory["star_melons"] = melons - 1
		hunger = clamp(hunger + 34.0, 0.0, max_hunger)
	else:
		inventory["glow_berries"] = berries - 1
		hunger = clamp(hunger + 24.0, 0.0, max_hunger)

	status_label.text = "Consumed food. Energy restored."
	return true


func _grant_xp(amount: int) -> void:
	player_xp += max(amount, 0)
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
		objectives[i] = objective
		break


func _objective_summary() -> String:
	var lines: Array[String] = []
	for objective in objectives:
		var prefix := "[ ]"
		if bool(objective.get("completed", false)):
			prefix = "[x]"
		lines.append("%s %s %d/%d" % [
			prefix,
			objective.get("label", ""),
			int(objective.get("progress", 0)),
			int(objective.get("target", 0))
		])
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
	var crafted_id: String = recipe.get("id", "pulse_blade")
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
	return bestiary_pages >= 5 and _bestiary_progress_count() >= 20


func _save_game() -> bool:
	var save_file := FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if save_file == null:
		return false

	var save_data: Dictionary = {
		"health": health,
		"hunger": hunger,
		"max_health": max_health,
		"max_hunger": max_hunger,
		"player_level": player_level,
		"player_xp": player_xp,
		"companion_id": companion_id,
		"keeley_dna_upgrade": keeley_dna_upgrade,
		"inventory": inventory,
		"crafted_items": crafted_items,
		"bestiary_pages": bestiary_pages,
		"bestiary_entries": bestiary_entries,
		"wave_number": wave_number,
		"current_biome_index": current_biome_index,
		"objectives": objectives,
		"skins_unlocked": skins_unlocked,
		"secret_walls_broken": secret_walls_broken
	}

	save_file.store_string(JSON.stringify(save_data))
	return true


func _load_game_data() -> bool:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return false

	var save_file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if save_file == null:
		return false

	var parsed := JSON.parse_string(save_file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false

	var data: Dictionary = parsed
	health = float(data.get("health", health))
	hunger = float(data.get("hunger", hunger))
	max_health = float(data.get("max_health", max_health))
	max_hunger = float(data.get("max_hunger", max_hunger))
	player_level = int(data.get("player_level", player_level))
	player_xp = int(data.get("player_xp", player_xp))
	companion_id = String(data.get("companion_id", companion_id))
	keeley_dna_upgrade = bool(data.get("keeley_dna_upgrade", keeley_dna_upgrade))
	bestiary_pages = int(data.get("bestiary_pages", bestiary_pages))
	wave_number = int(data.get("wave_number", wave_number))
	current_biome_index = clamp(int(data.get("current_biome_index", current_biome_index)), 0, biome_names.size() - 1)
	skins_unlocked = int(data.get("skins_unlocked", skins_unlocked))
	secret_walls_broken = int(data.get("secret_walls_broken", secret_walls_broken))

	var loaded_inventory := data.get("inventory", {})
	if typeof(loaded_inventory) == TYPE_DICTIONARY:
		inventory = loaded_inventory

	var loaded_crafted := data.get("crafted_items", {})
	if typeof(loaded_crafted) == TYPE_DICTIONARY:
		crafted_items = loaded_crafted

	var loaded_entries := data.get("bestiary_entries", {})
	if typeof(loaded_entries) == TYPE_DICTIONARY:
		bestiary_entries = loaded_entries

	var loaded_objectives := data.get("objectives", [])
	if typeof(loaded_objectives) == TYPE_ARRAY:
		objectives = loaded_objectives

	companion_select.select(0 if companion_id == "keeley" else 1)
	keeley_upgrade_toggle.button_pressed = keeley_dna_upgrade
	active_enemies.clear()
	wave_active = false
	wave_wait_tick = 1.0
	return true


func _update_hud() -> void:
	health_bar.max_value = max_health
	hunger_bar.max_value = max_hunger
	health_bar.value = health
	hunger_bar.value = hunger
	biome_label.text = "Biome: %s" % biome_names[current_biome_index]
	wave_label.text = "Wave: %d (%s)" % [wave_number, "active" if wave_active else "prep"]
	state_label.text = "State: %s | Input: %s" % [_state_text(player_state), _input_text(input_mode)]
	rhino_button.disabled = player_state == PlayerState.RHINO_CHARGE

	if player_state == PlayerState.RHINO_CHARGE:
		rhino_timer_label.text = "Rhino timer: %.1fs" % rhino_time_left
	else:
		rhino_timer_label.text = "Rhino ready (6.0s burst)"

	var scrap := int(inventory.get("human_scrap", 0))
	var crystals := int(inventory.get("alien_crystals", 0))
	var melons := int(inventory.get("star_melons", 0))
	var berries := int(inventory.get("glow_berries", 0))
	inventory_label.text = "Inventory -> Scrap:%d  Crystals:%d  Star-Melons:%d  Glow-Berries:%d" % [scrap, crystals, melons, berries]

	var recipe := _current_recipe()
	progression_label.text = "Lv %d (%d/%d XP) | Bestiary pages:%d | Entries:%d | Skins:%d | Secret walls:%d | Recipe:%s [S:%d C:%d L:%d]" % [
		player_level,
		player_xp,
		_xp_for_next_level(player_level),
		bestiary_pages,
		_bestiary_progress_count(),
		skins_unlocked,
		secret_walls_broken,
		recipe.get("name", ""),
		int(recipe.get("scrap", 0)),
		int(recipe.get("crystal", 0)),
		int(recipe.get("unlock_level", 1))
	]
	quest_label.text = "Objectives: %s" % _objective_summary()

	if companion_id == "annalize":
		loot_label.text = "Annalize active: +30%% loot drops, Quantum Forge access enabled"
	else:
		loot_label.text = "Keeley active: Sonic Scream crowd control (5+ nearby enemies)"

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
	var item := hotbar_items[index]
	status_label.text = "Selected slot %d: %s" % [index + 1, item.get("label", "Item")]
	_apply_hotbar_context_rules()


func _on_action_pressed() -> void:
	if input_mode == InputMode.EAT_MODE:
		_consume_food()
	elif input_mode == InputMode.RHINO_BOOST_MODE:
		_fire_attack("Action button", player_direction)
	else:
		var aim_direction := right_vector.normalized() if right_vector.length() > 0.2 else player_direction
		_fire_attack("Action button", aim_direction)


func _on_rhino_pressed() -> void:
	player_state = PlayerState.RHINO_CHARGE
	rhino_time_left = float(config.get("mutationStates", {}).get("rhinoCharge", {}).get("durationSeconds", 6.0))
	secret_walls_broken += randi_range(0, 2)
	_add_objective_progress("rhino", 1)
	status_label.text = "Rhino Charge activated! Smash drones and secret walls."
	_apply_hotbar_context_rules()


func _on_travel_biome_pressed() -> void:
	current_biome_index = (current_biome_index + 1) % biome_names.size()
	status_label.text = "Moved to biome: %s" % biome_names[current_biome_index]


func _on_companion_changed(index: int) -> void:
	companion_id = "keeley" if index == 0 else "annalize"
	companion_label.text = "Companion switched to %s" % companion_select.get_item_text(index)


func _on_keeley_upgrade_toggled(enabled: bool) -> void:
	keeley_dna_upgrade = enabled
	status_label.text = "Keeley DNA upgrade %s" % ("enabled" if enabled else "disabled")


func _on_recipe_selected(index: int) -> void:
	recipe_index = index


func _on_craft_pressed() -> void:
	_craft_current_recipe()


func _on_scavenge_pressed() -> void:
	var scrap_gain := randi_range(2, 5)
	var crystal_gain := randi_range(1, 3)
	var melon_gain := 1 if randf() > 0.55 else 0
	var berry_gain := 1 if randf() > 0.45 else 0
	_scavenge_resources(scrap_gain, crystal_gain, melon_gain, berry_gain)
	_grant_xp(10)
	status_label.text = "Scavenge burst: +%d scrap, +%d crystals, food found." % [scrap_gain, crystal_gain]


func _on_gain_page_pressed() -> void:
	bestiary_pages += 1
	_grant_xp(12)
	if _can_unlock_super_beast():
		status_label.text = "Titan Protocol complete: Super Beast unlocked for Overlord arena."
	else:
		status_label.text = "Collected a holographic Bestiary page."


func _on_save_pressed() -> void:
	if _save_game():
		status_label.text = "Progress saved."
	else:
		status_label.text = "Save failed."


func _on_load_pressed() -> void:
	if _load_game_data():
		status_label.text = "Save loaded."
	else:
		status_label.text = "No valid save found."


func _on_reset_objectives_pressed() -> void:
	for i in objectives.size():
		var objective: Dictionary = objectives[i]
		objective["progress"] = 0
		objective["completed"] = false
		objectives[i] = objective
	status_label.text = "Objectives reset."
