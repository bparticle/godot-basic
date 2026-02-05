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
var player_scene = preload("res://scenes/player/Player.tscn")
var player_instance: CharacterBody2D

# Game container reference
var game_container: Node2D

func _ready():
	# Set up room data
	setup_rooms()

func setup_rooms():
	# Define all rooms with their scene paths
	rooms["room_0"] = RoomData.new("room_0", "res://scenes/rooms/Room0.tscn", 600.0, 600.0)
	rooms["room_1"] = RoomData.new("room_1", "res://scenes/rooms/Room1.tscn", 600.0, 600.0)
	rooms["room_2"] = RoomData.new("room_2", "res://scenes/rooms/Room2.tscn", 600.0, 600.0)
	rooms["room_3"] = RoomData.new("room_3", "res://scenes/rooms/Room3.tscn", 600.0, 600.0)
	rooms["room_4"] = RoomData.new("room_4", "res://scenes/rooms/Room4.tscn", 600.0, 600.0)

func set_game_container(container: Node2D):
	game_container = container

func load_initial_room(room_id: String):
	change_room(room_id)

func cleanup():
	"""Clean up all references - call this before changing to non-game scenes"""
	current_room = null
	current_room_instance = null
	player_instance = null
	game_container = null

func change_room(room_id: String, play_spawn_animation: bool = false, override_spawn_pos: Vector2 = Vector2.INF):
	if not rooms.has(room_id):
		return
	
	# Unload current room
	if current_room_instance:
		current_room_instance.queue_free()
		current_room_instance = null
	
	# Load new room
	current_room = rooms[room_id]
	var room_scene = load(current_room.scene_path)
	if not room_scene:
		return
	current_room_instance = room_scene.instantiate()
	if not current_room_instance:
		return
	
	if game_container:
		# Add room first (background layer)
		game_container.add_child(current_room_instance)
		# Move room to back to ensure it renders behind player
		game_container.move_child(current_room_instance, 0)
	
	# Get spawn position from room
	var spawn_marker = current_room_instance.get_node_or_null("PlayerSpawn")
	if not spawn_marker:
		push_warning("PlayerSpawn not found in %s" % current_room.scene_path)
	var spawn_pos = spawn_marker.global_position if spawn_marker else Vector2(64, 64)
	
	# Use override spawn position if provided (for elevated spawn during respawn)
	var actual_spawn_pos = override_spawn_pos if override_spawn_pos != Vector2.INF else spawn_pos
	
	# Spawn or move player
	if not player_instance:
		player_instance = player_scene.instantiate()
		if not player_instance:
			return
		if game_container:
			# Add player after room (foreground layer)
			game_container.add_child(player_instance)
	else:
		# Ensure player is on top
		if game_container:
			game_container.move_child(player_instance, -1)
	
	player_instance.global_position = actual_spawn_pos
	# Ensure player starts stationary after room change
	player_instance.velocity = Vector2.ZERO
	# Reset death state when changing rooms (with spawn animation if respawning from deathzone)
	if player_instance.has_method("reset_death_state"):
		player_instance.reset_death_state(play_spawn_animation)
	
	# Update spawn point in HealthManager (use original spawn_pos, not elevated)
	var health_manager = get_node_or_null("/root/HealthManager")
	if health_manager:
		health_manager.update_spawn_point(spawn_pos, room_id)
	
	# Emit signal for camera and other systems
	room_changed.emit(current_room, spawn_pos)

# Spawn animation settings
const SPAWN_ELEVATION: float = 24.0 # How high above spawn point to appear during spawn animation

func respawn_player():
	"""Respawn player at last spawn point after dying in a deathzone"""
	var health_manager = get_node_or_null("/root/HealthManager")
	if not health_manager:
		return
	
	var respawn_room = health_manager.get_last_room_id()
	var respawn_pos = health_manager.get_last_spawn_position()
	
	# Elevate spawn position so player appears in the air and drops down after spawn animation
	var elevated_respawn_pos = respawn_pos - Vector2(0, SPAWN_ELEVATION)
	
	# If we're in a different room, change to the respawn room
	if current_room and current_room.id != respawn_room:
		change_room(respawn_room, true, elevated_respawn_pos) # Pass elevated position
	else:
		# Same room, just move player to elevated position
		if player_instance:
			player_instance.global_position = elevated_respawn_pos
			# Reset player velocity
			player_instance.velocity = Vector2.ZERO
			# Reset death state with spawn animation (deathzone respawn)
			if player_instance.has_method("reset_death_state"):
				player_instance.reset_death_state(true)

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
	
	# Get actual room bounds from tilemap for more accurate clamping
	var room_bounds = get_room_bounds()
	
	# Use actual room bounds if available, otherwise fall back to room data
	var min_x = half_viewport_x
	var max_x = current_room.width - half_viewport_x
	var min_y = half_viewport_y
	var max_y = current_room.height - half_viewport_y
	
	if room_bounds != Vector4.ZERO:
		# Use actual room bounds with minimal padding
		var padding = 16.0  # Small padding to ensure content isn't clipped
		min_x = room_bounds.x + half_viewport_x + padding
		max_x = room_bounds.z - half_viewport_x - padding
		min_y = room_bounds.y + half_viewport_y + padding
		max_y = room_bounds.w - half_viewport_y - padding
		
		# Ensure bounds are valid (min < max)
		if min_x >= max_x:
			min_x = half_viewport_x
			max_x = current_room.width - half_viewport_x
		if min_y >= max_y:
			min_y = half_viewport_y
			max_y = current_room.height - half_viewport_y
	
	# Clamp camera position to stay within room bounds
	var camera_x = clamp(player_pos.x, min_x, max_x)
	var camera_y = clamp(player_pos.y, min_y, max_y)
	
	# Debug output removed for clean console
	
	return Vector2(camera_x, camera_y)

# Get the actual bounds of the current room by analyzing the tilemap
func get_room_bounds() -> Vector4:
	if not current_room_instance:
		return Vector4.ZERO
	
	var tilemap = current_room_instance.get_node_or_null("TileMapLayer")
	if not tilemap:
		return Vector4.ZERO
	
	# Get the used rect from the tilemap
	var used_rect = tilemap.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		return Vector4.ZERO
	
	# Convert tile coordinates to world coordinates
	var tile_size = tilemap.tile_set.tile_size
	var world_pos = tilemap.map_to_local(used_rect.position)
	var world_size = Vector2(used_rect.size) * Vector2(tile_size)
	
	# Add some padding to the bounds to ensure we don't clip content
	var padding = 32.0
	
	# Return bounds as Vector4: x_min, y_min, x_max, y_max
	var bounds = Vector4(
		world_pos.x - padding,
		world_pos.y - padding,
		world_pos.x + world_size.x + padding,
		world_pos.y + world_size.y + padding
	)
	
	# Debug output removed for clean console
	
	return bounds
