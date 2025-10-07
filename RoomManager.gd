extends Node

# Room Manager - Singleton to handle room boundaries and transitions
# Loads rooms dynamically and manages player spawning

signal room_changed(room_scene, spawn_position)

# Room data structure
class RoomData:
	var id: String
	var scene_path: String
	var width: float
	var height: float
	
	func _init(room_id: String, path: String, room_width: float, room_height: float):
		id = room_id
		scene_path = path
		width = room_width
		height = room_height

# Current room
var current_room: RoomData
var current_room_instance: Node2D
var rooms: Dictionary = {}

# Player instance
var player_scene = preload("res://Player.tscn")
var player_instance: CharacterBody2D

# Game container reference
var game_container: Node2D

func _ready():
	# Set up room data
	setup_rooms()

func setup_rooms():
	# Define all rooms with their scene paths
	rooms["room_1"] = RoomData.new("room_1", "res://Room1.tscn", 128.0, 128.0)
	rooms["room_2"] = RoomData.new("room_2", "res://Room2.tscn", 256.0, 128.0)
	# Add more rooms as needed
	# rooms["room_3"] = RoomData.new("room_3", "res://Room3.tscn", 192.0, 192.0)

func set_game_container(container: Node2D):
	game_container = container

func load_initial_room(room_id: String = "room_1"):
	change_room(room_id)

func change_room(room_id: String):
	if not rooms.has(room_id):
		print("Room '", room_id, "' not found!")
		return
	
	# Unload current room
	if current_room_instance:
		current_room_instance.queue_free()
		current_room_instance = null
	
	# Load new room
	current_room = rooms[room_id]
	var room_scene = load(current_room.scene_path)
	current_room_instance = room_scene.instantiate()
	
	if game_container:
		# Add room first (background layer)
		game_container.add_child(current_room_instance)
		# Move room to back to ensure it renders behind player
		game_container.move_child(current_room_instance, 0)
	
	# Get spawn position from room
	var spawn_marker = current_room_instance.get_node_or_null("PlayerSpawn")
	var spawn_pos = spawn_marker.global_position if spawn_marker else Vector2(64, 64)
	
	# Spawn or move player
	if not player_instance:
		player_instance = player_scene.instantiate()
		if game_container:
			# Add player after room (foreground layer)
			game_container.add_child(player_instance)
	else:
		# Ensure player is on top
		if game_container:
			game_container.move_child(player_instance, -1)
	
	player_instance.global_position = spawn_pos
	
	# Emit signal for camera and other systems
	room_changed.emit(current_room, spawn_pos)

func get_current_room() -> RoomData:
	return current_room

func get_player() -> CharacterBody2D:
	return player_instance

# Get camera position that follows player but stays within room bounds
func get_camera_position(player_pos: Vector2, viewport_size: Vector2) -> Vector2:
	if not current_room:
		return player_pos
	
	# Calculate camera bounds based on room size and viewport
	var half_viewport_x = viewport_size.x / 2.0
	var half_viewport_y = viewport_size.y / 2.0
	
	# Clamp camera position to stay within room bounds
	var camera_x = clamp(player_pos.x, half_viewport_x, current_room.width - half_viewport_x)
	var camera_y = clamp(player_pos.y, half_viewport_y, current_room.height - half_viewport_y)
	
	return Vector2(camera_x, camera_y)
