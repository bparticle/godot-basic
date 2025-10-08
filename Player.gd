extends CharacterBody2D

# Movement constants
const SPEED = 60.0
const CROUCH_SPEED = 30.0  # Slower when crouching
const CLIMB_SPEED = 40.0   # Speed when climbing ladders
const JUMP_VELOCITY = -220.0
const ACCELERATION = 400.0
const FRICTION = 400.0

# Collision shape sizes for different states
const COLLISION_IDLE = Vector2(7, 14)
const COLLISION_WALK = Vector2(7, 14)
const COLLISION_JUMP = Vector2(7, 12)  # Slightly smaller when jumping
const COLLISION_CROUCH = Vector2(7, 8)  # Much smaller when crouching
const COLLISION_CLIMB = Vector2(7, 14)  # Normal size when climbing

# References
@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var room_manager = get_node("/root/RoomManager")

func _ready():
	# Add player to a group for easy access
	add_to_group("player")
	# Listen for room changes to briefly lock input and reset motion
	if room_manager:
		room_manager.room_changed.connect(_on_room_changed)

# State
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_animation = ""
var input_locked_until_ms: int = 0
@export var input_lock_duration_ms: int = 150
var is_crouching = false
var is_climbing = false
var climb_direction = 0  # -1 for left, 1 for right
var forced_crouch = false  # When we're forced to crouch due to low ceiling
var climb_animation_timer = 0.0  # Timer for climb animation

func _physics_process(delta: float) -> void:
	# Process all inputs first
	process_inputs()
	
	# Handle state-specific logic
	if is_climbing:
		handle_climbing(delta)
	else:
		apply_gravity(delta)
		handle_movement(delta)
	
	update_animation()
	update_collision_shape()  # Update collision based on animation
	move_and_slide()
	# Boundary constraints removed - using physics collisions instead

func process_inputs() -> void:
	"""Centralized input processing - handles all input states and transitions"""
	if _is_input_locked():
		return
	
	# Check for ladder interaction first
	check_ladder_interaction()
	
	# Handle crouch input
	handle_crouch_input()
	
	# Check ceiling clearance
	check_ceiling_clearance()
	
	# Handle jump input with priority
	handle_jump_input()
	
	# Handle state transitions
	handle_state_transitions()

func handle_jump_input() -> void:
	"""Handle jump input with proper priority and state management"""
	if not Input.is_action_just_pressed("ui_accept"):
		return
	
	# Don't allow jumping when crouching
	if is_crouching:
		return
	
	# Special case: jumping while climbing
	if is_climbing:
		# Break out of climbing and jump
		is_climbing = false
		velocity.y = JUMP_VELOCITY
		# Preserve any horizontal momentum from climbing
		return
	
	# Normal jumping when on floor
	if is_on_floor():
		velocity.y = JUMP_VELOCITY

func handle_state_transitions() -> void:
	"""Handle transitions between different movement states"""
	# If we were climbing and no longer should be, handle the transition
	if is_climbing and not should_be_climbing():
		is_climbing = false
		# Preserve any existing velocity for smooth transition

func should_be_climbing() -> bool:
	"""Check if player should be in climbing state"""
	# Check if we're near a ladder (regardless of input)
	var tilemap = room_manager.current_room_instance.get_node("TileMapLayer")
	if not tilemap:
		return false
	
	# Check for ladder tiles in a radius around the player
	var check_radius = 8
	for x in range(-check_radius, check_radius + 1, 4):
		for y in range(-check_radius, check_radius + 1, 4):
			var check_pos = global_position + Vector2(x, y)
			var tile_pos = tilemap.local_to_map(check_pos)
			var tile_atlas_coords = tilemap.get_cell_atlas_coords(tile_pos)
			
			if tile_atlas_coords == Vector2i(3, 2):
				# Found ladder - can climb
				return true
	
	return false

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta


func handle_movement(delta: float) -> void:
	var direction = 0.0 if _is_input_locked() else Input.get_axis("ui_left", "ui_right")
	var current_speed = CROUCH_SPEED if is_crouching else SPEED
	
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * current_speed, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

func update_animation() -> void:
	# Handle sprite flipping
	if velocity.x < 0:
		animated_sprite.flip_h = true
		climb_direction = -1
	elif velocity.x > 0:
		animated_sprite.flip_h = false
		climb_direction = 1
	
	# Handle animation states
	var new_animation = ""
	if is_climbing:
		new_animation = "climb"
		# For climbing, we need to handle the alternating frames manually
		handle_climb_animation()
	elif is_crouching:
		# Use duck animation for idle ducking, crouch animation for crouch walking
		if abs(velocity.x) > 5:
			new_animation = "crouch"
		else:
			new_animation = "duck"
	elif not is_on_floor():
		new_animation = "jump"
	elif abs(velocity.x) > 5:
		new_animation = "walk"
	else:
		new_animation = "idle"
	
	# Only change if different
	if new_animation != current_animation:
		current_animation = new_animation
		animated_sprite.play(current_animation)

func handle_climb_animation() -> void:
	# Handle dynamic climbing animation based on vertical movement only
	if not is_climbing:
		climb_animation_timer = 0.0
		return
	
	# Only animate when moving vertically (up or down)
	if abs(velocity.y) > 0:
		climb_animation_timer += get_physics_process_delta_time()
		
		# Alternate between normal and mirrored sprite every 0.2 seconds
		var frame_duration = 0.2
		var should_mirror = int(climb_animation_timer / frame_duration) % 2 == 1
		
		# Set mirroring based on animation timing
		animated_sprite.flip_h = should_mirror
	else:
		# Not moving vertically, reset to normal orientation
		animated_sprite.flip_h = false
		climb_animation_timer = 0.0

func update_collision_shape() -> void:
	# Get the shape resource
	var shape = collision_shape.shape as RectangleShape2D
	if not shape:
		return
	
	# Adjust collision size based on current animation
	match current_animation:
		"idle":
			shape.size = COLLISION_IDLE
		"walk":
			shape.size = COLLISION_WALK
		"jump":
			shape.size = COLLISION_JUMP
		"crouch":
			shape.size = COLLISION_CROUCH
		"duck":
			shape.size = COLLISION_CROUCH
		"climb":
			shape.size = COLLISION_CLIMB
	
	# Adjust collision position when crouching to prevent sinking
	if current_animation == "crouch" or current_animation == "duck":
		# Move collision box up so the bottom edge stays at the same position
		# Normal collision: bottom at -8 + 14 = 6
		# Crouch collision: bottom should also be at 6, so position = 6 - 8 = -2
		# But we're floating 2 pixels, so move down by 2: -2 - 2 = -4
		collision_shape.position.y = -4
	elif current_animation != "crouch" and current_animation != "duck":
		# Reset position when not crouching
		collision_shape.position.y = -8

func _on_room_changed(_room_data, _spawn_pos):
	# Lock input briefly and reset velocity when entering a new room
	input_locked_until_ms = Time.get_ticks_msec() + input_lock_duration_ms
	velocity = Vector2.ZERO

func _is_input_locked() -> bool:
	return Time.get_ticks_msec() < input_locked_until_ms

func handle_crouch_input() -> void:
	if _is_input_locked():
		return
	
	# Check if down is pressed (alone or with left/right)
	var down_pressed = Input.is_action_pressed("ui_down")
	
	# If we're not forced to crouch, allow normal crouch input
	if not forced_crouch:
		is_crouching = down_pressed
	else:
		# If we're forced to crouch, only allow standing if there's enough ceiling clearance
		if not down_pressed and check_ceiling_clearance_for_full_height():
			is_crouching = false
			forced_crouch = false
		else:
			is_crouching = true
	
	# If we were climbing, stop climbing when crouching
	if is_crouching and is_climbing:
		is_climbing = false

func check_ladder_interaction() -> void:
	if _is_input_locked():
		return
	
	# Use a more robust approach: check for ladder tiles in a radius around the player
	var tilemap = room_manager.current_room_instance.get_node("TileMapLayer")
	if not tilemap:
		return
	
	# Check for ladder tiles in a 16x16 pixel area around the player
	var ladder_found = false
	var check_radius = 1  # Check 8 pixels in each direction
	
	# Create a grid of positions to check around the player
	for x in range(-check_radius, check_radius + 1, 4):  # Check every 4 pixels
		for y in range(-check_radius, check_radius + 1, 4):
			var check_pos = global_position + Vector2(x, y)
			var tile_pos = tilemap.local_to_map(check_pos)
			var tile_atlas_coords = tilemap.get_cell_atlas_coords(tile_pos)
			
			# Debug output when up is pressed
			if Input.is_action_pressed("ui_up") and tile_atlas_coords != Vector2i(-1, -1):
				print("Checking position: ", check_pos, " -> Tile: ", tile_pos, " -> Atlas: ", tile_atlas_coords)
			
			# Check if this is a ladder tile (coordinates 3, 2 in the tileset)
			if tile_atlas_coords == Vector2i(3, 2):
				ladder_found = true
				if Input.is_action_pressed("ui_up"):
					print("LADDER FOUND at position: ", check_pos, "! Starting to climb.")
				break
		
		if ladder_found:
			break
	
	# Handle ladder interaction
	if ladder_found and Input.is_action_pressed("ui_up"):
		is_climbing = true
		is_crouching = false  # Can't crouch while climbing
	elif not ladder_found:
		# No ladder nearby, stop climbing
		if is_climbing:
			is_climbing = false

func handle_climbing(delta: float) -> void:
	"""Handle climbing movement with smooth input processing"""
	# Stop gravity while climbing
	velocity.y = 0
	
	# Handle vertical movement on ladder
	var vertical_input = 0.0
	if Input.is_action_pressed("ui_up"):
		vertical_input = -1.0
	elif Input.is_action_pressed("ui_down"):
		vertical_input = 1.0
	
	velocity.y = vertical_input * CLIMB_SPEED
	
	# Handle horizontal movement while climbing
	var horizontal_input = Input.get_axis("ui_left", "ui_right")
	if abs(horizontal_input) > 0:
		# Limited horizontal movement - 25% of climb speed
		velocity.x = horizontal_input * CLIMB_SPEED * 0.25
	else:
		# Smooth horizontal deceleration
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

func check_ceiling_clearance() -> void:
	# Only check ceiling clearance if we're not already crouching due to input
	var down_pressed = Input.is_action_pressed("ui_down")
	
	# If we're not forced to crouch and not manually crouching, check for low ceiling
	if not forced_crouch and not down_pressed:
		# Check if there's enough space for full height
		if not check_ceiling_clearance_for_full_height():
			forced_crouch = true
			is_crouching = true
	elif forced_crouch and not down_pressed:
		# Check if we can now stand up (only if not manually crouching)
		if check_ceiling_clearance_for_full_height():
			forced_crouch = false
			is_crouching = false

func check_ceiling_clearance_for_full_height() -> bool:
	# Create a temporary collision shape to test full height
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.new()
	
	# Check from current position upward for full height collision
	var full_height = COLLISION_IDLE.y
	var start_pos = global_position + Vector2(0, -8)  # Start from current collision top
	var end_pos = start_pos + Vector2(0, -full_height + 8)  # Check upward
	
	query.from = start_pos
	query.to = end_pos
	query.collision_mask = 1  # Same collision mask as player
	query.exclude = [self]  # Exclude the player's own collision
	
	var result = space_state.intersect_ray(query)
	
	# If no collision found, there's enough clearance
	return result.is_empty()
