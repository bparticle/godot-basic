extends Node2D

@onready var room_manager = get_node("/root/RoomManager")
@onready var health_manager = get_node("/root/HealthManager")

func _ready():
	# Connect to health manager signals
	if health_manager:
		health_manager.player_died.connect(_on_player_died)
		health_manager.game_over.connect(_on_game_over)
	
	# Register this node as the game container
	if room_manager:
		room_manager.set_game_container(self)
		# Load the initial room
		room_manager.load_initial_room("room_1")

func _on_player_died():
	"""Handle player death - respawn after a brief delay"""
	# Wait a moment before respawning
	await get_tree().create_timer(1.0).timeout
	
	if room_manager:
		room_manager.respawn_player()

func _on_game_over():
	"""Handle game over"""
	# Clean up room manager before changing scenes
	if room_manager:
		room_manager.cleanup()
	# Use call_deferred to avoid physics callback issues
	get_tree().call_deferred("change_scene_to_file", "res://GameOver.tscn")
