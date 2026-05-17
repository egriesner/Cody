extends Node
class_name FeedbackBus

signal feedback_triggered(event_name: String, flash_color: Color, flash_duration: float)

var vibration_enabled := true
var master_volume := 0.85
var show_hit_flash := true

var audio_player: AudioStreamPlayer
var event_map := {
	"attack": {"flash_color": Color(0.35, 0.8, 1.0, 0.22), "flash_duration": 0.08, "vibrate_ms": 0},
	"hit": {"flash_color": Color(1.0, 0.25, 0.42, 0.28), "flash_duration": 0.16, "vibrate_ms": 18},
	"rhino": {"flash_color": Color(0.28, 0.92, 1.0, 0.34), "flash_duration": 0.18, "vibrate_ms": 22},
	"objective": {"flash_color": Color(0.48, 0.98, 0.72, 0.24), "flash_duration": 0.14, "vibrate_ms": 10},
	"boss": {"flash_color": Color(1.0, 0.34, 0.58, 0.34), "flash_duration": 0.22, "vibrate_ms": 26}
}


func _ready() -> void:
	audio_player = AudioStreamPlayer.new()
	audio_player.volume_db = linear_to_db(clamp(master_volume, 0.001, 1.0))
	add_child(audio_player)


func configure_from_profile(settings: Dictionary) -> void:
	vibration_enabled = bool(settings.get("vibration", vibration_enabled))
	master_volume = float(settings.get("master_volume", master_volume))
	show_hit_flash = bool(settings.get("show_hit_flash", show_hit_flash))
	if audio_player != null:
		audio_player.volume_db = linear_to_db(clamp(master_volume, 0.001, 1.0))


func emit_feedback(event_name: String) -> void:
	var entry: Dictionary = event_map.get(event_name, {"flash_color": Color(1, 1, 1, 0.1), "flash_duration": 0.08, "vibrate_ms": 0})
	var vibrate_ms := int(entry.get("vibrate_ms", 0))
	var can_vibrate := OS.has_feature("android") or OS.has_feature("ios")
	if vibration_enabled and vibrate_ms > 0 and can_vibrate:
		Input.vibrate_handheld(vibrate_ms)

	if show_hit_flash:
		feedback_triggered.emit(
			event_name,
			entry.get("flash_color", Color(1, 1, 1, 0.08)),
			float(entry.get("flash_duration", 0.08))
		)
