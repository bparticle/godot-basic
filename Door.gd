extends Area2D

# Door that allows room transitions
@export var target_room: String = "room_2"

@onready var room_manager = get_node("/root/RoomManager")

func _ready():
	# Connect to body entered signal
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Check if the body is the player
	if body.is_in_group("player"):
		# Change to target room (player will be spawned at room's PlayerSpawn marker)
		room_manager.change_room(target_room)
