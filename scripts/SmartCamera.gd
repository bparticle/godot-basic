extends Camera2D

# Smart Camera that follows the player but respects room boundaries
# This camera will smoothly follow the player horizontally and vertically
# but will not exceed the boundaries of the current room

@onready var room_manager = get_node("/root/RoomManager")
@onready var effects_manager = get_node_or_null("/root/EffectsManager")

# Hybrid mode: we use 3x viewport resolution but zoom camera to show focused game area
# This gives us smooth sub-pixel effects while maintaining a tight, focused view
# Zoom 4.0 = shows 225x225 game units (more zoomed in than original 300x300)
const HYBRID_ZOOM: float = 4.0

var viewport_size: Vector2
var follow_speed: float = 8.0  # Increased for more responsive camera in Godot 4.5
var player: CharacterBody2D


func _ready():
	# Set zoom for hybrid mode - shows same game area as original 300x300
	zoom = Vector2(HYBRID_ZOOM, HYBRID_ZOOM)
	
	# Get viewport size (divided by zoom to get effective game view size)
	viewport_size = get_viewport().get_visible_rect().size / HYBRID_ZOOM
	# Keep viewport size in sync if window/viewport changes
	get_viewport().size_changed.connect(func(): viewport_size = get_viewport().get_visible_rect().size / HYBRID_ZOOM)
	
	# Connect to room changes
	if room_manager:
		room_manager.room_changed.connect(_on_room_changed)
	
	# Register with effects manager
	if effects_manager:
		effects_manager.register_camera(self)

func _physics_process(delta: float):
	# Using _physics_process instead of _process for smoother camera movement in Godot 4.5
	# This ensures the camera updates in sync with the physics engine, reducing jitter
	
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
	
	# Smoothly move camera towards target position with sub-pixel precision
	# Using exponential smoothing for ultra-smooth camera movement
	var lerp_factor = 1.0 - exp(-adaptive_speed * delta)
	global_position = global_position.lerp(target_position, lerp_factor)
	
	

func _on_room_changed(_room_data, spawn_pos):
	# Get player reference
	if room_manager:
		player = room_manager.get_player()
	
	# When room changes, immediately snap camera to spawn position
	# Use spawn_pos directly to ensure camera is positioned correctly
	var target_position = room_manager.get_camera_position(spawn_pos, viewport_size)
	global_position = target_position
	
	# Debug output removed for clean console
