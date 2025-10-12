class_name PlayerClimbState
extends State

# Player climb state - handles ladder climbing

var parent: CharacterBody2D
var animated_sprite: AnimatedSprite2D
var movement_component: MovementComponent

# Ladder centering system
var ladder_center_x: float = 0.0
var ladder_centering_strength: float = 200.0
var was_climbing: bool = false
var climb_animation_timer: float = 0.0

func enter():
	parent = get_parent().get_parent()  # StateMachine -> Player
	animated_sprite = parent.get_node("AnimatedSprite2D")
	movement_component = parent.get_node("MovementComponent")
	
	# Set climbing state
	parent.is_climbing = true
	parent.is_crouching = false  # Can't crouch while climbing
	
	# Calculate ladder center
	calculate_ladder_center()

func exit():
	parent.is_climbing = false
	was_climbing = false

func update(delta: float):
	handle_climb_animation(delta)

func physics_update(delta: float):
	# Stop gravity while climbing
	parent.velocity.y = 0
	
	# Check if we just started climbing (immediate centering)
	if parent.is_climbing and not was_climbing:
		# Just started climbing - immediately center on ladder
		if ladder_center_x != 0.0:
			parent.global_position.x = ladder_center_x
			parent.velocity.x = 0  # Stop any horizontal velocity
	
	# Handle vertical movement on ladder
	var vertical_input = 0.0
	if movement_component:
		if movement_component.wants_to_climb():
			if Input.is_action_pressed("ui_up"):
				vertical_input = -1.0
			elif Input.is_action_pressed("ui_down"):
				vertical_input = 1.0
	
	parent.velocity.y = vertical_input * parent.CLIMB_SPEED
	
	# Handle horizontal movement while climbing
	if movement_component:
		var horizontal_input = movement_component.get_movement_direction()
		if abs(horizontal_input) > 0:
			# Pressing left or right makes you fall off the ladder
			parent.is_climbing = false
			# Give a small horizontal push in the direction pressed
			parent.velocity.x = horizontal_input * 50.0
			# Let gravity take over
			parent.velocity.y = 0
		else:
			# Apply gentle ladder centering when no horizontal input
			apply_ladder_centering(delta)
	
	# Update climbing state for next frame
	was_climbing = parent.is_climbing

func calculate_ladder_center():
	"""Calculate the center position of the ladder"""
	var room_manager = parent.get_node("/root/RoomManager")
	if not room_manager or not room_manager.current_room_instance:
		return
	
	var tilemap = room_manager.current_room_instance.get_node("TileMapLayer")
	if not tilemap:
		return
	
	# Check for ladder tiles and find the center position
	var ladder_found = false
	var ladder_tile_positions: Array[Vector2i] = []
	var check_radius = 1
	
	# Create a grid of positions to check around the player
	for x in range(-check_radius, check_radius + 1, 4):
		for y in range(-check_radius, check_radius + 1, 4):
			var check_pos = parent.global_position + Vector2(x, y)
			var tile_pos = tilemap.local_to_map(check_pos)
			var tile_atlas_coords = tilemap.get_cell_atlas_coords(tile_pos)
			
			# Check if this is any ladder tile variant
			if tile_atlas_coords in parent.LADDER_TILES:
				ladder_found = true
				ladder_tile_positions.append(tile_pos)
	
	# Calculate ladder center if found
	if ladder_found and ladder_tile_positions.size() > 0:
		var total_x = 0
		for tile_pos in ladder_tile_positions:
			total_x += tile_pos.x
		var center_tile_x = float(total_x) / float(ladder_tile_positions.size())
		
		# Convert tile position to world position (center of the tile)
		var tile_size = tilemap.tile_set.tile_size
		ladder_center_x = center_tile_x * tile_size.x + (tile_size.x / 2.0)

func apply_ladder_centering(delta: float):
	"""Apply gentle centering force to maintain ladder center during climb"""
	if ladder_center_x == 0.0:
		return
	
	# Calculate distance from ladder center
	var distance_from_center = ladder_center_x - parent.global_position.x
	
	# Only apply centering if we're not already close to center
	if abs(distance_from_center) > 1.0:
		# Apply gentler centering force to maintain position during climb
		var centering_force = distance_from_center * (ladder_centering_strength * 0.5) * delta
		
		# Apply the centering force to velocity
		parent.velocity.x = move_toward(parent.velocity.x, centering_force, (ladder_centering_strength * 0.5) * delta)
	else:
		# If we're close to center, just decelerate smoothly
		parent.velocity.x = move_toward(parent.velocity.x, 0, parent.FRICTION * delta)

func handle_climb_animation(delta: float):
	"""Handle dynamic climbing animation based on vertical movement"""
	if not parent.is_climbing:
		climb_animation_timer = 0.0
		return
	
	# Only animate when moving vertically (up or down)
	if abs(parent.velocity.y) > 0:
		climb_animation_timer += delta
		
		# Alternate between normal and mirrored sprite every 0.2 seconds
		var frame_duration = 0.2
		var should_mirror = int(climb_animation_timer / frame_duration) % 2 == 1
		
		# Set mirroring based on animation timing
		animated_sprite.flip_h = should_mirror
	else:
		# Not moving vertically, reset to normal orientation
		animated_sprite.flip_h = false
		climb_animation_timer = 0.0

func check_transitions():
	if not movement_component:
		return
	
	# Check if we should still be climbing
	if not parent.should_be_climbing():
		# No ladder nearby, stop climbing
		if abs(movement_component.get_movement_direction()) == 0:
			transition_to("idle")
		else:
			transition_to("walk")
		return
	
	# Check for jump (can jump off ladder)
	if movement_component.wants_to_jump():
		# Break out of climbing and jump
		parent.is_climbing = false
		parent.just_jumped_off_ladder = true
		transition_to("jump")
		return
	
	# Check for crouch (can't crouch while climbing)
	# This is handled by the climbing state itself
