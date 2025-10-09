extends CharacterBody2D

# Movement constants
const SPEED = 60.0
const CROUCH_SPEED = 30.0  # Slower when crouching
const CLIMB_SPEED = 40.0   # Speed when climbing ladders
const JUMP_VELOCITY = -240.0
const ACCELERATION = 400.0
const FRICTION = 400.0

# Jump system - easily tweakable values
@export var quick_jump_power: float = 0.5  # Quick tap jump power (0.5 = 50% of normal)
@export var charged_jump_power: float = 1.1  # Hold and release jump power (1.1 = 110% of normal)

# Collision system - easily tweakable in Godot editor
@export_group("Collision Shapes")
@export var collision_idle_size: Vector2 = Vector2(7, 14)
@export var collision_idle_offset: Vector2 = Vector2(0, -7)

@export var collision_walk_size: Vector2 = Vector2(7, 14)
@export var collision_walk_offset: Vector2 = Vector2(0, -7)

@export var collision_jump_size: Vector2 = Vector2(7, 12)
@export var collision_jump_offset: Vector2 = Vector2(0, -6)

@export var collision_crouch_size: Vector2 = Vector2(7, 8)
@export var collision_crouch_offset: Vector2 = Vector2(0, -4)

@export var collision_charge_size: Vector2 = Vector2(7, 14)
@export var collision_charge_offset: Vector2 = Vector2(0, -7)

@export var collision_climb_size: Vector2 = Vector2(7, 14)
@export var collision_climb_offset: Vector2 = Vector2(0, -7)

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
	# Listen for health changes to detect death
	if health_manager:
		health_manager.health_changed.connect(_on_health_changed)

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

# Blinking state
var idle_timer = 0.0  # Timer for how long we've been idle
var blink_timer = 0.0  # Timer for blink animation
var is_blinking = false  # Whether we're currently in a blink animation
var last_blink_time = 0.0  # When we last blinked
var blink_interval_min = 2.0  # Minimum time between blinks
var blink_interval_max = 5.0  # Maximum time between blinks
var blink_duration = 0.33  # How long the blink animation lasts (faster now)
var idle_animation_timer = 0.0  # Timer to sync with idle animation cycle
var use_mirrored_idle = false  # Whether to use mirrored idle after blinking
var mirrored_idle_timer = 0.0  # Timer for how long we've been in mirrored idle
var mirrored_idle_duration = 3.0  # How long to stay in mirrored idle

# Jump state tracking
var jump_phase = "none"  # none, off, up, peak, down, land, charge
var jump_off_timer = 0.0  # Timer for jump-off animation
var jump_off_duration = 0.25  # How long jump-off animation lasts
var jump_land_timer = 0.0  # Timer for landing animation
var jump_land_duration = 0.25  # How long landing animation lasts
var last_velocity_y = 0.0  # Previous frame's Y velocity for jump phase detection

# Simple jump system
var is_charging = false  # Whether we're currently charging a jump
var was_charging = false  # Whether we were charging in the previous frame
var jump_hold_timer = 0.0  # Timer to detect if we're holding jump
var jump_hold_threshold = 0.15  # Time in seconds to distinguish tap vs hold (150ms)
var jump_just_pressed_this_frame = false  # Whether jump was just pressed this frame

# Damage / hazard handling
@onready var health_manager = get_node("/root/HealthManager")
@export var damage_immunity_duration_ms: int = 500
@export var spike_knockback_speed: float = 100.0
@export var spike_knockup_velocity: float = -180.0
var damage_immunity_until_ms: int = 0
const SPIKE_ATLAS_COORD: Vector2i = Vector2i(1, 1)  # (col=1,row=1) second column/row in 0-based atlas

# Death state
var is_dead = false
var has_shown_death_knockback = false

func _physics_process(delta: float) -> void:
	# Always check for spike damage first, even when dead
	handle_spike_damage()
	
	# If dead, only show dead animation and don't process anything else
	if is_dead:
		update_animation()
		return
	
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
	# Jump input is now handled in handle_jump_phases() for charge system
	# This function is kept for climbing jump override
	if not Input.is_action_just_pressed("ui_accept"):
		return
	
	# Special case: jumping while climbing
	if is_climbing:
		# Break out of climbing and jump
		is_climbing = false
		velocity.y = JUMP_VELOCITY
		# Preserve any horizontal momentum from climbing
		return

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
	
	# Prevent horizontal movement while charging jump
	if is_charging:
		# Lock horizontal movement while charging
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	elif direction != 0:
		velocity.x = move_toward(velocity.x, direction * current_speed, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

func update_animation() -> void:
	# If dead, show appropriate animation using named clips
	if is_dead:
		if not has_shown_death_knockback:
			# During final knockback, show falling sprite via jump_down animation
			if animated_sprite.animation != "jump_down":
				animated_sprite.play("jump_down")
		else:
			# After knockback, show dedicated dead sprite
			if animated_sprite.animation != "dead":
				animated_sprite.play("dead")
		return
	
	# Handle sprite flipping
	if velocity.x < 0:
		animated_sprite.flip_h = true
		climb_direction = -1
	elif velocity.x > 0:
		animated_sprite.flip_h = false
		climb_direction = 1
	
	# Handle blinking logic
	handle_blinking()
	
	# Handle jump phases
	handle_jump_phases()
	
	# Handle animation states
	var new_animation = ""
	if is_blinking:
		new_animation = "blink"
	elif is_climbing:
		new_animation = "climb"
		# For climbing, we need to handle the alternating frames manually
		handle_climb_animation()
	elif is_crouching:
		# Use duck animation for idle ducking, crouch animation for crouch walking
		if abs(velocity.x) > 5:
			new_animation = "crouch"
		else:
			new_animation = "duck"
	elif is_charging:
		new_animation = "charge"
	elif not is_on_floor():
		# Use specific jump phase animation
		match jump_phase:
			"off":
				new_animation = "jump_off"
			"up":
				new_animation = "jump_up"
			"peak":
				new_animation = "jump_peak"
			"down":
				new_animation = "jump_down"
			"land":
				new_animation = "jump_land"
			_:
				new_animation = "jump"  # Fallback to original jump
	elif abs(velocity.x) > 5:
		new_animation = "walk"
	else:
		new_animation = "idle"
	
	# Only change if different
	if new_animation != current_animation:
		current_animation = new_animation
		animated_sprite.play(current_animation)
	
	# Handle mirrored idle after blinking
	if current_animation == "idle" and use_mirrored_idle:
		# Flip the sprite horizontally for mirrored idle
		animated_sprite.flip_h = true
	elif current_animation == "idle" and not use_mirrored_idle:
		# Reset to normal direction when not mirrored
		animated_sprite.flip_h = false

func handle_blinking() -> void:
	# Only blink when idle and not moving
	var is_idle = is_on_floor() and abs(velocity.x) <= 5 and not is_crouching and not is_climbing
	
	if is_idle:
		idle_timer += get_physics_process_delta_time()
		idle_animation_timer += get_physics_process_delta_time()
		
		# Handle mirrored idle timer
		if use_mirrored_idle:
			mirrored_idle_timer += get_physics_process_delta_time()
			if mirrored_idle_timer >= mirrored_idle_duration:
				use_mirrored_idle = false
				mirrored_idle_timer = 0.0
		
		# Check if we should start blinking
		if not is_blinking and idle_timer > 1.0:  # Wait at least 1 second before blinking
			var time_since_last_blink = idle_timer - last_blink_time
			var should_blink = time_since_last_blink > randf_range(blink_interval_min, blink_interval_max)
			
			if should_blink:
				# Sync the blink with the idle animation cycle
				# The idle animation has a 0.5 second cycle (2 frames at 4.0 speed = 0.5s total)
				var idle_cycle_duration = 0.5  # Matches idle animation speed
				var cycle_progress = fmod(idle_animation_timer, idle_cycle_duration)
				
				# Start blinking at the beginning of the next idle cycle
				var time_to_next_cycle = idle_cycle_duration - cycle_progress
				if time_to_next_cycle < 0.1:  # If we're very close to cycle start, start immediately
					is_blinking = true
					blink_timer = 0.0
					last_blink_time = idle_timer
					idle_animation_timer = 0.0  # Reset to sync with blink
	else:
		# Reset timers when not idle
		idle_timer = 0.0
		is_blinking = false
		blink_timer = 0.0
		idle_animation_timer = 0.0
		use_mirrored_idle = false  # Reset mirrored idle when moving
		mirrored_idle_timer = 0.0
	
	# Handle blink animation duration
	if is_blinking:
		blink_timer += get_physics_process_delta_time()
		if blink_timer >= blink_duration:
			is_blinking = false
			blink_timer = 0.0
			use_mirrored_idle = true  # Switch to mirrored idle after blinking

func handle_jump_phases() -> void:
	# Handle jump input detection
	var jump_pressed = Input.is_action_pressed("ui_accept")
	var jump_just_pressed = Input.is_action_just_pressed("ui_accept")
	var jump_just_released = Input.is_action_just_released("ui_accept")
	
	# Track when jump is just pressed
	jump_just_pressed_this_frame = jump_just_pressed
	
	# Handle jump input when on floor and not crouching/climbing
	if is_on_floor() and not is_crouching and not is_climbing:
		if jump_just_pressed:
			# Jump button just pressed - start micro timer
			jump_hold_timer = 0.0
			is_charging = false
		elif jump_pressed and not is_charging:
			# We're holding jump - increment timer
			jump_hold_timer += get_physics_process_delta_time()
			
			# If we've held long enough, start charging
			if jump_hold_timer >= jump_hold_threshold:
				is_charging = true
		elif jump_just_released:
			# Jump button just released
			if is_charging:
				# We were charging - do charged jump
				is_charging = false
				jump_phase = "off"
				jump_off_timer = 0.0
				velocity.y = JUMP_VELOCITY * charged_jump_power
			elif jump_hold_timer < jump_hold_threshold:
				# Quick tap - do quick jump
				jump_phase = "off"
				jump_off_timer = 0.0
				velocity.y = JUMP_VELOCITY * quick_jump_power
			
			# Reset timer
			jump_hold_timer = 0.0
		elif not jump_pressed:
			# Not holding jump - reset everything
			is_charging = false
			jump_hold_timer = 0.0
	else:
		# Not on floor or crouching/climbing - reset jump state
		is_charging = false
		jump_hold_timer = 0.0
	
	# Store charging state for next frame
	was_charging = is_charging
	
	# Handle jump-off animation duration
	if jump_phase == "off":
		jump_off_timer += get_physics_process_delta_time()
		if jump_off_timer >= jump_off_duration:
			jump_phase = "up"
	
	# Handle jump phase transitions based on velocity
	if not is_on_floor() and jump_phase != "off" and jump_phase != "land":
		# Detect jump peak (velocity changes from negative to positive)
		if last_velocity_y < 0 and velocity.y >= 0:
			jump_phase = "peak"
		# Detect going down (velocity is positive)
		elif velocity.y > 0 and jump_phase != "down":
			jump_phase = "down"
		# Detect going up (velocity is negative and we're not at peak)
		elif velocity.y < 0 and jump_phase == "peak":
			jump_phase = "up"
	
	# Handle landing phase
	if is_on_floor() and jump_phase != "none" and jump_phase != "off":
		jump_phase = "land"
		jump_land_timer = 0.0
	
	# Handle landing animation duration
	if jump_phase == "land":
		jump_land_timer += get_physics_process_delta_time()
		if jump_land_timer >= jump_land_duration:
			jump_phase = "none"
	
	# Reset jump phase when on floor and not jumping
	if is_on_floor() and not Input.is_action_pressed("ui_accept"):
		if jump_phase == "none" or jump_phase == "land":
			pass  # Already handled
		else:
			jump_phase = "none"
	
	# Store current velocity for next frame
	last_velocity_y = velocity.y

func handle_spike_damage() -> void:
	# Respect damage immunity window (but allow visual effects when dead)
	if Time.get_ticks_msec() < damage_immunity_until_ms and not is_dead:
		return
	
	# If dead and already showed final knockback, stop checking spikes entirely
	if is_dead and has_shown_death_knockback:
		return
	
	var tilemap = room_manager.current_room_instance.get_node("TileMapLayer") if room_manager and room_manager.current_room_instance else null
	if not tilemap:
		return
	
	# Sample a few points around the player's body to detect spike tiles
	var sample_points: Array[Vector2] = []
	var half_width = 3.0
	var half_height = 6.0
	# Feet row
	sample_points.append(global_position + Vector2(0, 0))
	sample_points.append(global_position + Vector2(-half_width, 0))
	sample_points.append(global_position + Vector2(half_width, 0))
	# Mid row
	sample_points.append(global_position + Vector2(0, -half_height))
	sample_points.append(global_position + Vector2(-half_width, -half_height))
	sample_points.append(global_position + Vector2(half_width, -half_height))

	var spike_hit = false
	for p in sample_points:
		var map_pos: Vector2i = tilemap.local_to_map(p)
		var atlas: Vector2i = tilemap.get_cell_atlas_coords(map_pos)
		if atlas == SPIKE_ATLAS_COORD:
			spike_hit = true
			break

	if not spike_hit:
		return

	print("Spike hit! is_dead: ", is_dead, " has_shown_death_knockback: ", has_shown_death_knockback)

	# If dead, only allow one spike hit to show the final knockback
	if is_dead:
		if has_shown_death_knockback:
			print("Dead player already showed knockback, ignoring")
			return
		has_shown_death_knockback = true
		print("Dead player showing final knockback")

	# Only apply damage if not dead
	if not is_dead:
		print("Applying damage...")
		# Apply damage without respawn
		if health_manager:
			if health_manager.has_method("take_damage_no_respawn"):
				health_manager.take_damage_no_respawn(1)
			else:
				health_manager.take_damage(1)

		# Start short immunity and input lock to prevent life-drain in a single cluster
		damage_immunity_until_ms = Time.get_ticks_msec() + damage_immunity_duration_ms
		input_locked_until_ms = max(input_locked_until_ms, Time.get_ticks_msec() + int(damage_immunity_duration_ms * 0.7))

	# Compute knockback: push opposite to current horizontal movement, and knock up
	var knock_dir = -1 if velocity.x > 0 else 1
	if abs(velocity.x) < 1.0:
		# If essentially stationary, use last facing as hint
		knock_dir = 1 if animated_sprite.flip_h else -1
	
	print("Applying knockback: ", knock_dir * spike_knockback_speed, " horizontal, ", spike_knockup_velocity, " vertical")
	velocity.x = knock_dir * spike_knockback_speed
	velocity.y = spike_knockup_velocity
	
	# Note: Sprite is now handled by update_animation() based on is_dead and has_shown_death_knockback

func _on_health_changed(current_lives: int, _max_lives: int):
	"""Handle health changes - set dead state when lives reach 0"""
	print("Health changed: ", current_lives, " lives remaining")
	if current_lives <= 0 and not is_dead:
		print("Player died! Setting is_dead = true")
		is_dead = true
		# Don't stop movement immediately - let spike damage handle knockback first
		# velocity = Vector2.ZERO

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
	
	# Apply collision based on current animation using exported values
	match current_animation:
		"idle", "blink":
			shape.size = collision_idle_size
			collision_shape.position = collision_idle_offset
		"walk":
			shape.size = collision_walk_size
			collision_shape.position = collision_walk_offset
		"charge":
			shape.size = collision_charge_size
			collision_shape.position = collision_charge_offset
		"jump", "jump_off", "jump_up", "jump_peak", "jump_down", "jump_land":
			shape.size = collision_jump_size
			collision_shape.position = collision_jump_offset
		"crouch":
			shape.size = collision_crouch_size
			collision_shape.position = collision_crouch_offset
		"duck":
			shape.size = collision_crouch_size
			collision_shape.position = collision_crouch_offset
		"climb":
			shape.size = collision_climb_size
			collision_shape.position = collision_climb_offset

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
	
	# If we're climbing and near a ladder, don't allow crouching to override climbing
	if is_climbing and should_be_climbing():
		# While climbing, don't set crouching state
		pass
	elif not forced_crouch:
		# If we're not forced to crouch, allow normal crouch input
		is_crouching = down_pressed
	else:
		# If we're forced to crouch, only allow standing if there's enough ceiling clearance
		if not down_pressed and check_ceiling_clearance_for_full_height():
			is_crouching = false
			forced_crouch = false
		else:
			is_crouching = true
	
	# If we were climbing, stop climbing when crouching (but not when near a ladder and trying to climb)
	if is_crouching and is_climbing and not should_be_climbing():
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
			
			
			# Check if this is a ladder tile (coordinates 3, 2 in the tileset)
			if tile_atlas_coords == Vector2i(3, 2):
				ladder_found = true
				break
		
		if ladder_found:
			break
	
	# Handle ladder interaction
	if ladder_found and (Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down")):
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
	var query = PhysicsShapeQueryParameters2D.new()
	
	# Create a test shape at the position where the full collision would be
	var test_shape = RectangleShape2D.new()
	test_shape.size = collision_idle_size
	
	# Position the test shape at where the idle collision would be
	var test_transform = Transform2D(0, global_position + collision_idle_offset)
	
	query.shape = test_shape
	query.transform = test_transform
	query.collision_mask = 1  # Same collision mask as player
	query.exclude = [self.get_rid()]  # Exclude the player's own collision
	
	# Check if there's any collision
	var result = space_state.intersect_shape(query, 1)
	
	# If no collision found, there's enough clearance
	return result.is_empty()
