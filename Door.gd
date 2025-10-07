extends Area2D

# Door that allows room transitions
# Leave empty by default; set in Inspector
@export var target_room: String = ""
@export var activation_delay: float = 0.3

@onready var room_manager = get_node("/root/RoomManager")
var is_active: bool = false

func _ready():
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
		print("Door triggered! target_room property = ", target_room)
		print("Door node name: ", name)
		print("Door position: ", global_position)
		# Deactivate door to prevent double-triggering
		is_active = false
		# Use call_deferred to avoid physics callback issues
		room_manager.call_deferred("change_room", target_room)
