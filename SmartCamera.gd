extends Camera2D

# Smart Camera that follows the player but respects room boundaries
# This camera will smoothly follow the player horizontally and vertically
# but will not exceed the boundaries of the current room

@onready var room_manager = get_node("/root/RoomManager")

var viewport_size: Vector2
var follow_speed: float = 5.0
var player: CharacterBody2D

# Camera bounds debugging
@export var debug_bounds: bool = false
var last_bounds_check: float = 0.0
const BOUNDS_CHECK_INTERVAL: float = 1.0  # Check bounds every second

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
	
	# Debug output (can be removed in production)
	if distance_to_target > 50.0:
		print("Camera: Distance to target: ", distance_to_target, " Target: ", target_position, " Current: ", global_position)
	
	# Periodic bounds checking for debugging
	if debug_bounds:
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - last_bounds_check > BOUNDS_CHECK_INTERVAL:
			debug_camera_bounds()
			last_bounds_check = current_time

func _on_room_changed(_room_data, spawn_pos):
	# Get player reference
	if room_manager:
		player = room_manager.get_player()
	
	# When room changes, immediately snap camera to spawn position
	# Use spawn_pos directly to ensure camera is positioned correctly
	var target_position = room_manager.get_camera_position(spawn_pos, viewport_size)
	global_position = target_position
	
	# Debug output removed for clean console

# Debug method to visualize camera bounds (call this from debug console if needed)
func debug_camera_bounds():
	if not room_manager:
		print("No room manager available")
		return
	
	var room_bounds = room_manager.get_room_bounds()
	var current_room = room_manager.get_current_room()
	
	print("=== Camera Bounds Debug ===")
	if current_room:
		print("Room ID: ", current_room.id)
		print("Room Size: ", current_room.width, "x", current_room.height)
	else:
		print("Room ID: None")
		print("Room Size: N/A")
	print("Viewport Size: ", viewport_size)
	print("Room Bounds (actual): ", room_bounds)
	print("Camera Position: ", global_position)
	if player:
		print("Player Position: ", player.global_position)
	else:
		print("Player Position: No player")
	
	# Calculate effective camera bounds
	var half_viewport_x = viewport_size.x / 2.0
	var half_viewport_y = viewport_size.y / 2.0
	
	if room_bounds != Vector4.ZERO:
		var padding = 32.0
		var min_x = room_bounds.x + half_viewport_x + padding
		var max_x = room_bounds.z - half_viewport_x - padding
		var min_y = room_bounds.y + half_viewport_y + padding
		var max_y = room_bounds.w - half_viewport_y - padding
		print("Effective Camera Bounds: X(", min_x, " to ", max_x, ") Y(", min_y, " to ", max_y, ")")
	else:
		print("Using fallback bounds from room data")

# Method to test camera bounds by moving player to edges
func test_camera_bounds():
	if not player or not room_manager:
		print("Cannot test bounds - missing player or room manager")
		return
	
	var room_bounds = room_manager.get_room_bounds()
	if room_bounds == Vector4.ZERO:
		print("Cannot test bounds - no room bounds available")
		return
	
	print("=== Testing Camera Bounds ===")
	
	# Test each edge
	var test_positions = [
		Vector2(room_bounds.x - 50, room_bounds.y + 100),  # Left edge
		Vector2(room_bounds.z + 50, room_bounds.y + 100),  # Right edge
		Vector2(room_bounds.x + 100, room_bounds.y - 50),  # Top edge
		Vector2(room_bounds.x + 100, room_bounds.w + 50),  # Bottom edge
		Vector2(room_bounds.x + 100, room_bounds.y + 100)  # Center (should work normally)
	]
	
	for i in range(test_positions.size()):
		var test_pos = test_positions[i]
		var camera_pos = room_manager.get_camera_position(test_pos, viewport_size)
		print("Test ", i + 1, ": Player at ", test_pos, " -> Camera at ", camera_pos)
		
		# Check if camera is properly clamped
		var half_viewport_x = viewport_size.x / 2.0
		var half_viewport_y = viewport_size.y / 2.0
		var padding = 32.0
		
		var min_x = room_bounds.x + half_viewport_x + padding
		var max_x = room_bounds.z - half_viewport_x - padding
		var min_y = room_bounds.y + half_viewport_y + padding
		var max_y = room_bounds.w - half_viewport_y - padding
		
		var is_clamped_x = camera_pos.x >= min_x and camera_pos.x <= max_x
		var is_clamped_y = camera_pos.y >= min_y and camera_pos.y <= max_y
		
		print("  Clamped X: ", is_clamped_x, " (", min_x, " <= ", camera_pos.x, " <= ", max_x, ")")
		print("  Clamped Y: ", is_clamped_y, " (", min_y, " <= ", camera_pos.y, " <= ", max_y, ")")
