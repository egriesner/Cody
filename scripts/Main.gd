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

var rhino_time_left := 0.0
var attack_cooldown := 0.0
var companion_tick := 0.0
var biome_names := PackedStringArray(["Scrap Dunes", "Whispering Archives", "Plasma Crater"])
var current_biome_index := 0

var hud_root: Control
var health_bar: ProgressBar
var hunger_bar: ProgressBar
var status_label: Label
var state_label: Label
var biome_label: Label
var companion_label: Label
var loot_label: Label
var rhino_timer_label: Label
var action_button: Button
var rhino_button: Button
var travel_biome_button: Button
var hotbar_container: HBoxContainer
var hotbar_buttons: Array[Button] = []
var companion_select: OptionButton
var keeley_upgrade_toggle: CheckButton
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
	status_label.text = "Welcome to RIFT - build by Code Max Studios"
	_apply_hotbar_context_rules()
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
	_update_hud()
	queue_redraw()


func _draw() -> void:
	var screen_size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color("#0b1022"))

	# Dead-zones to prevent accidental palm presses.
	draw_rect(Rect2(0, 0, left_dead_zone_px, screen_size.y), Color(1, 0.2, 0.35, 0.18))
	draw_rect(Rect2(screen_size.x - right_dead_zone_px, 0, right_dead_zone_px, screen_size.y), Color(1, 0.2, 0.35, 0.18))

	# Visual hints for dynamic joystick spawn regions.
	draw_rect(left_spawn_rect, Color(0.15, 0.8, 1.0, 0.08), true)
	draw_rect(right_spawn_rect, Color(0.66, 0.42, 1.0, 0.08), true)

	# Biome atmosphere stripe.
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

	# Vexian drones as simple targets for attack feedback.
	var drone_points := [
		Vector2(screen_size.x * 0.72, screen_size.y * 0.32),
		Vector2(screen_size.x * 0.80, screen_size.y * 0.52),
		Vector2(screen_size.x * 0.64, screen_size.y * 0.60),
		Vector2(screen_size.x * 0.30, screen_size.y * 0.34)
	]
	for point in drone_points:
		draw_circle(point, 14, Color("#bc7bff"))


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
	biome_label.position = Vector2(520, 48)
	biome_label.add_theme_font_size_override("font_size", 18)
	hud_root.add_child(biome_label)

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
	companion_label.size = Vector2(740, 26)
	hud_root.add_child(companion_label)

	loot_label = Label.new()
	loot_label.position = Vector2(20, 224)
	loot_label.size = Vector2(740, 24)
	hud_root.add_child(loot_label)

	status_label = Label.new()
	status_label.position = Vector2(20, 252)
	status_label.size = Vector2(960, 24)
	hud_root.add_child(status_label)

	rhino_timer_label = Label.new()
	rhino_timer_label.position = Vector2(20, 282)
	rhino_timer_label.size = Vector2(360, 24)
	hud_root.add_child(rhino_timer_label)

	travel_biome_button = Button.new()
	travel_biome_button.text = "Travel Biome"
	travel_biome_button.position = Vector2(760, 80)
	travel_biome_button.size = Vector2(160, 42)
	travel_biome_button.pressed.connect(_on_travel_biome_pressed)
	hud_root.add_child(travel_biome_button)

	rhino_button = Button.new()
	rhino_button.text = "Activate Rhino Charge"
	rhino_button.position = Vector2(760, 132)
	rhino_button.size = Vector2(220, 42)
	rhino_button.pressed.connect(_on_rhino_pressed)
	hud_root.add_child(rhino_button)

	hotbar_container = HBoxContainer.new()
	hotbar_container.position = Vector2(690, 980)
	hotbar_container.add_theme_constant_override("separation", 10)
	hud_root.add_child(hotbar_container)

	for i in hotbar_items.size():
		var button := Button.new()
		button.custom_minimum_size = Vector2(140, 74)
		button.text = "%d: %s" % [i + 1, hotbar_items[i].get("label", "Item")]
		var slot_index := i
		button.pressed.connect(func() -> void:
			_on_hotbar_selected(slot_index)
		)
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
			_show_stick(left_stick_base, left_stick_knob, left_origin, 70.0)
			return
		if right_touch_id == INVALID_TOUCH_ID and right_spawn_rect.has_point(position):
			right_touch_id = touch_id
			right_origin = position
			right_touch_start = position
			right_touch_start_msec = Time.get_ticks_msec()
			right_vector = Vector2.ZERO
			_show_stick(right_stick_base, right_stick_knob, right_origin, 77.0)
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
				_fire_attack("Quick tap auto-fire")
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


func _show_stick(base: Panel, knob: Panel, origin: Vector2, radius: float) -> void:
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


func _update_player_state(delta: float) -> void:
	state_move_speed_multiplier = 1.0
	if player_state == PlayerState.RHINO_CHARGE:
		rhino_time_left = max(0.0, rhino_time_left - delta)
		state_move_speed_multiplier = 1.8
		if rhino_time_left <= 0.0:
			player_state = PlayerState.NORMAL
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
		_fire_attack("Drag fire")
	elif input_mode == InputMode.RHINO_BOOST_MODE and right_vector.length() > 0.45 and attack_cooldown <= 0.0:
		_fire_attack("Rhino impact")


func _fire_attack(source: String) -> void:
	attack_cooldown = 0.24
	if input_mode == InputMode.RHINO_BOOST_MODE:
		status_label.text = "Rhino crashed through Vexian drones! (%s)" % source
	else:
		status_label.text = "Fired at nearby drones. (%s)" % source


func _update_companion_logic(delta: float) -> void:
	companion_tick += delta
	if companion_id == "annalize":
		loot_label.text = "Annalize passive active: +30%% loot drop and Quantum Forge unlocked"
		keeley_upgrade_toggle.visible = false
	else:
		loot_label.text = "Keeley companion active: crowd-control support"
		keeley_upgrade_toggle.visible = true

	if companion_tick < 2.0:
		return

	companion_tick = 0.0
	var nearby_enemies := randi_range(0, 8)
	if companion_id == "keeley" and nearby_enemies >= 5:
		if keeley_dna_upgrade:
			companion_label.text = "Keeley triggered Neuro-Toxic Wail! (%d enemies)" % nearby_enemies
		else:
			companion_label.text = "Keeley triggered Sonic Scream! (%d enemies)" % nearby_enemies
	elif companion_id == "annalize":
		companion_label.text = "Annalize railgun support pinged (%d targets tracked)" % nearby_enemies
	else:
		companion_label.text = "Keeley scanning... (%d nearby hostiles)" % nearby_enemies


func _update_hud() -> void:
	health_bar.value = health
	hunger_bar.value = hunger
	biome_label.text = "Biome: %s" % biome_names[current_biome_index]
	state_label.text = "State: %s | Input: %s" % [_state_text(player_state), _input_text(input_mode)]
	rhino_button.disabled = player_state == PlayerState.RHINO_CHARGE

	if player_state == PlayerState.RHINO_CHARGE:
		rhino_timer_label.text = "Rhino timer: %.1fs" % rhino_time_left
	else:
		rhino_timer_label.text = "Rhino ready (6.0s burst)"

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
		hunger = clamp(hunger + 28.0, 0.0, max_hunger)
		status_label.text = "Consumed food. Energy restored."
	elif input_mode == InputMode.RHINO_BOOST_MODE:
		_fire_attack("Action button")
	else:
		_fire_attack("Action button")


func _on_rhino_pressed() -> void:
	player_state = PlayerState.RHINO_CHARGE
	rhino_time_left = float(config.get("mutationStates", {}).get("rhinoCharge", {}).get("durationSeconds", 6.0))
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
