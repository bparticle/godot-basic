extends Camera2D

# Smart Camera that follows the player but respects room boundaries
# This camera will smoothly follow the player horizontally and vertically
# but will not exceed the boundaries of the current room

@onready var room_manager = get_node("/root/RoomManager")

var viewport_size: Vector2
var follow_speed: float = 5.0
var player: CharacterBody2D


func _ready():
	# Get viewport size
	viewport_size = get_viewport().get_visible_rect().size
	# Keep viewport size in sync if window/viewport changes
	get_viewport().size_changed.connect(func(): viewport_size = get_viewport().get_visible_rect().size)
	
	# Connect to room changes
	if room_manager:
		room_manager.room_changed.connect(_on_room_changed)

func _process(delta: float):
	# Get player reference from room manager if we don't have it
	if not player and room_manager:
		player = room_manager.get_player()
	
	if not player or not room_manager:
		return
	
	# Get the ideal camera position from room manager
	var target_position = room_manager.get_camera_position(player.global_position, viewport_size)
	
	# Debug output removed for clean console
	
	# Calculate distance to target for adaptive follow speed
	var distance_to_target = global_position.distance_to(target_position)
	
	# Use adaptive follow speed - faster when far, slower when close
	var adaptive_speed = follow_speed
	if distance_to_target > 100.0:
		adaptive_speed = follow_speed * 2.0  # Faster when far away
	elif distance_to_target < 10.0:
		adaptive_speed = follow_speed * 0.5  # Slower when close for smooth settling
	
	# Smoothly move camera towards target position
	global_position = global_position.lerp(target_position, adaptive_speed * delta)
	
	

func _on_room_changed(_room_data, spawn_pos):
	# Get player reference
	if room_manager:
		player = room_manager.get_player()
	
	# When room changes, immediately snap camera to spawn position
	# Use spawn_pos directly to ensure camera is positioned correctly
	var target_position = room_manager.get_camera_position(spawn_pos, viewport_size)
	global_position = target_position
	
	# Debug output removed for clean console
