extends Node2D

@onready var room_manager = get_node("/root/RoomManager")

func _ready():
	# Register this node as the game container
	if room_manager:
		room_manager.set_game_container(self)
		# Load the initial room
		room_manager.load_initial_room("room_1")
