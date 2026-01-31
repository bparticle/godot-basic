extends Area2D

# Door that allows room transitions
# Leave empty by default; set in Inspector
@export var target_room: String = ""
@export var activation_delay: float = 0.3
@export var door_stream: AudioStream
@export var door_stream_path: String = "res://assets/audio/sfx/SFX 24.wav"
@export var door_volume_db: float = -6.0

@onready var room_manager = get_node("/root/RoomManager")
var is_active: bool = false
var door_player: AudioStreamPlayer2D

func _ready():
	door_player = AudioStreamPlayer2D.new()
	door_player.name = "DoorPlayer"
	door_player.volume_db = door_volume_db
	if door_stream == null and door_stream_path != "":
		door_stream = load(door_stream_path)
	if door_stream:
		door_player.stream = door_stream
	add_child(door_player)
	# Connect to body entered signal
	body_entered.connect(_on_body_entered)
	# Warn if target_room is not set
	if target_room == "":
		push_warning("Door '%s' has empty target_room; set it in the Inspector" % name)
	# Add a small delay before door becomes active to prevent immediate re-triggering
	await get_tree().create_timer(activation_delay).timeout
	is_active = true

func _on_body_entered(body):
	# Check if the body is the player and door is active
	if body.is_in_group("player") and is_active:
		# Deactivate door to prevent double-triggering
		is_active = false
		if door_player and door_player.stream:
			door_player.play()
		# Use call_deferred to avoid physics callback issues
		room_manager.call_deferred("change_room", target_room)
