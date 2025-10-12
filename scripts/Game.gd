extends Node2D

@export_group("Game Settings")
@export var initial_room: String = "room_1"
@export var respawn_delay: float = 1.0
@export var game_over_delay: float = 1.0

@export_group("Visual Settings")
@export var debug_show_room_info: bool = false
@export var debug_show_player_info: bool = false

@onready var room_manager = get_node("/root/RoomManager")
@onready var health_manager = get_node("/root/HealthManager")

func _ready():
	# Connect to health manager signals
	if health_manager:
		health_manager.player_died.connect(_on_player_died)
		health_manager.game_over.connect(_on_game_over)
		health_manager.health_changed.connect(_on_health_changed)
	
	# Register this node as the game container
	if room_manager:
		room_manager.set_game_container(self)
		# Load the initial room
		room_manager.load_initial_room(initial_room)

func _on_player_died():
	"""Handle player death - respawn after a brief delay"""
	# Wait a moment before respawning
	await get_tree().create_timer(respawn_delay).timeout
	
	if room_manager:
		room_manager.respawn_player()

func _on_game_over():
	"""Handle game over"""
	# Allow a short delay so the final knockback/life change is visible
	await get_tree().create_timer(game_over_delay).timeout
	# Clean up room manager before changing scenes
	if room_manager:
		room_manager.cleanup()
	# Use call_deferred to avoid physics callback issues
	get_tree().call_deferred("change_scene_to_file", "res://scenes/ui/GameOver.tscn")

func _on_health_changed(current_lives: int, _max_lives: int):
	"""Handle health changes - trigger game over when lives reach 0"""
	if current_lives <= 0:
		_on_game_over()

func _draw():
	"""Debug drawing for game information"""
	if not debug_show_room_info and not debug_show_player_info:
		return
	
	var y_offset = 20
	var font_size = 16
	
	if debug_show_room_info and room_manager:
		# Draw room information
		var room_info = "Room: " + str(room_manager.current_room.id if room_manager.current_room else "None")
		draw_string(ThemeDB.fallback_font, Vector2(10, y_offset), room_info, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
		y_offset += 25
	
	if debug_show_player_info and health_manager:
		# Draw player health information
		var health_info = "Lives: " + str(health_manager.current_lives) + "/" + str(health_manager.max_lives)
		draw_string(ThemeDB.fallback_font, Vector2(10, y_offset), health_info, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
