extends CharacterBody2D

# Enums for better code organization
enum PlayerState {
	IDLE,
	WALKING,
	JUMPING,
	CROUCHING,
	CLIMBING,
	DEAD
}

enum JumpPhase {
	NONE,
	UP,
	PEAK,
	DOWN,
	LAND
}

# Movement constants - now configurable in editor
@export_group("Movement Settings")
@export var speed: float = 60.0
@export var crouch_speed: float = 30.0 # Slower when crouching
@export var climb_speed: float = 40.0 # Speed when climbing ladders
@export var jump_velocity: float = -240.0
@export var acceleration: float = 400.0
@export var friction: float = 400.0

# Visual settings
@export_group("Visual Settings")
@export var player_color: Color = Color(0.176471, 0.996078, 0.223529, 1)
@export var debug_draw_collision: bool = false
@export var debug_draw_movement: bool = false

# Audio settings
@export_group("Audio Settings")
@export var footstep_stream: AudioStream
@export var footstep_interval: float = 0.18
@export var footstep_min_speed: float = 5.0
@export var footstep_volume_db: float = -6.0
@export var land_stream: AudioStream
@export var land_volume_db: float = -6.0
@export var land_min_fall_speed: float = 140.0
@export var jump_stream: AudioStream
@export var jump_volume_db: float = -6.0

# Death tile visual feedback
@export_group("Death Tile Effects")
@export var flash_intensity_max: float = 0.7 # Maximum flash intensity (0.0 = no effect, 1.0 = full white)
@export var flash_duration: float = 0.3 # How long the flash lasts in seconds
@export var debug_death_tiles: bool = true

# Touch controls (web/mobile)
@export_group("Touch Controls")
@export var touch_controls_enabled: bool = true
@export var touch_deadzone: float = 16.0
@export var touch_tap_max_time: float = 0.18
@export var touch_tap_max_distance: float = 12.0
@export var touch_climb_threshold: float = 18.0
@export var touch_jump_hold_time: float = 0.12

# Jump system - simple UP key jumping
@export var jump_power: float = 1.0 # Jump power multiplier

# Platformer improvements
@export_group("Platformer Improvements")
@export var jump_buffer_time: float = 0.1 # How long to buffer jump input
@export var coyote_time: float = 0.1 # How long to allow jumping after leaving ground
@export var fall_gravity_scale: float = 2.0 # Higher gravity when falling
@export var low_jump_gravity_scale: float = 1.8 # Gravity when releasing jump early
@export var ledge_push_amount: float = 6.0 # How far to push when hitting ceiling
@export var ledge_probe_offset: float = 6.0 # Distance to probe for ledge push

# Collision system - easily tweakable in Godot editor
@export_group("Collision Shapes")
@export var collision_idle_size: Vector2 = Vector2(4, 14)
@export var collision_idle_offset: Vector2 = Vector2(0, -7)

@export var collision_walk_size: Vector2 = Vector2(4, 14)
@export var collision_walk_offset: Vector2 = Vector2(0, -7)

@export var collision_jump_size: Vector2 = Vector2(4, 12)
@export var collision_jump_offset: Vector2 = Vector2(0, -6)

@export var collision_crouch_size: Vector2 = Vector2(4, 8)
@export var collision_crouch_offset: Vector2 = Vector2(0, -4)

@export var collision_climb_size: Vector2 = Vector2(4, 14)
@export var collision_climb_offset: Vector2 = Vector2(0, -7)

# References - Using $ for direct child references (more reliable for current scene structure)
@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var footstep_player = $FootstepPlayer
@onready var land_player = $LandPlayer
@onready var jump_player = $JumpPlayer
@onready var room_manager = get_node("/root/RoomManager")
@onready var state_machine = $StateMachine
@onready var movement_component = $MovementComponent

func _ready():
	# Add player to a group for easy access
	add_to_group("player")
	# Listen for room changes to briefly lock input and reset motion
	if room_manager:
		room_manager.room_changed.connect(_on_room_changed)
	# Listen for health changes to detect death
	if health_manager:
		health_manager.health_changed.connect(_on_health_changed)
		if health_manager.has_method("get_current_lives"):
			last_lives = health_manager.get_current_lives()
	
	# Apply visual settings
	if animated_sprite:
		animated_sprite.modulate = player_color

	# Apply audio settings
	if footstep_player:
		footstep_player.volume_db = footstep_volume_db
		if footstep_stream:
			footstep_player.stream = footstep_stream
	if land_player:
		land_player.volume_db = land_volume_db
		if land_stream:
			land_player.stream = land_stream
	if jump_player:
		jump_player.volume_db = jump_volume_db
		if jump_stream:
			jump_player.stream = jump_stream
	
	# Load and setup white flash shader
	white_flash_shader = load("res://shaders/white_flash.gdshader")
	if white_flash_shader and animated_sprite:
		animated_sprite.material = ShaderMaterial.new()
		animated_sprite.material.shader = white_flash_shader

func _input(event: InputEvent) -> void:
	if not touch_controls_enabled:
		return
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			touch_points[touch_event.index] = {
				"start_pos": touch_event.position,
				"current_pos": touch_event.position,
				"start_time_ms": Time.get_ticks_msec()
			}
		else:
			if touch_points.has(touch_event.index):
				var point = touch_points[touch_event.index]
				var duration_sec = float(Time.get_ticks_msec() - int(point.start_time_ms)) / 1000.0
				var move_distance = (point.current_pos as Vector2).distance_to(point.start_pos as Vector2)
				if touch_event.index == move_touch_index:
					touch_active = false
					move_touch_index = -1
					_reset_touch_axes()
				elif duration_sec <= touch_tap_max_time and move_distance <= touch_tap_max_distance:
					touch_jump_queued = true
					touch_jump_hold_timer = touch_jump_hold_time
				touch_points.erase(touch_event.index)
	elif event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		if touch_points.has(drag_event.index):
			var point = touch_points[drag_event.index]
			point.current_pos = drag_event.position
			touch_points[drag_event.index] = point
			if drag_event.index == move_touch_index:
				touch_current_pos = drag_event.position
				_update_touch_axes()
			elif move_touch_index == -1:
				var delta = (point.current_pos as Vector2) - (point.start_pos as Vector2)
				if abs(delta.x) >= touch_deadzone or abs(delta.y) >= touch_climb_threshold:
					move_touch_index = drag_event.index
					touch_active = true
					touch_start_pos = point.start_pos
					touch_current_pos = point.current_pos
					touch_start_time_ms = int(point.start_time_ms)
					_update_touch_axes()

func _update_touch_axes() -> void:
	var delta = touch_current_pos - touch_start_pos
	touch_horizontal_dir = 0.0
	if abs(delta.x) >= touch_deadzone:
		touch_horizontal_dir = 1.0 if delta.x > 0.0 else -1.0
	touch_up_pressed = delta.y <= -touch_climb_threshold
	touch_down_pressed = delta.y >= touch_climb_threshold

func _reset_touch_axes() -> void:
	touch_horizontal_dir = 0.0
	touch_up_pressed = false
	touch_down_pressed = false

func update_touch_timers(delta: float) -> void:
	if not touch_controls_enabled:
		return
	if touch_jump_hold_timer > 0.0:
		touch_jump_hold_timer = max(0.0, touch_jump_hold_timer - delta)

func _get_horizontal_input() -> float:
	var axis = Input.get_axis("ui_left", "ui_right")
	if touch_controls_enabled and touch_active and abs(touch_horizontal_dir) > 0.0:
		axis = touch_horizontal_dir
	return axis

func _is_up_pressed() -> bool:
	return Input.is_action_pressed("ui_up") or (touch_controls_enabled and touch_up_pressed)

func _is_down_pressed() -> bool:
	return Input.is_action_pressed("ui_down") or (touch_controls_enabled and touch_down_pressed)

func _is_jump_just_pressed() -> bool:
	return Input.is_action_just_pressed("ui_up") or (touch_controls_enabled and touch_jump_queued)

func _is_jump_held() -> bool:
	return Input.is_action_pressed("ui_up") or (touch_controls_enabled and touch_jump_hold_timer > 0.0)

# State
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_animation = ""
var input_locked_until_ms: int = 0
@export var input_lock_duration_ms: int = 150

# Player state with getter/setter
var _player_state: PlayerState = PlayerState.IDLE
var player_state: PlayerState:
	get:
		return _player_state
	set(value):
		_player_state = value
		# Add any state change logic here if needed

# Movement states with getters/setters
var _is_crouching: bool = false
var is_crouching: bool:
	get:
		return _is_crouching
	set(value):
		_is_crouching = value
		# Add crouch state change logic here if needed

var _is_climbing: bool = false
var is_climbing: bool:
	get:
		return _is_climbing
	set(value):
		_is_climbing = value
		# Add climb state change logic here if needed

var climb_direction = 0 # -1 for left, 1 for right
var forced_crouch = false # When we're forced to crouch due to low ceiling
var climb_animation_timer = 0.0 # Timer for climb animation

# Blinking state
var idle_timer = 0.0 # Timer for how long we've been idle
var blink_timer = 0.0 # Timer for blink animation
var is_blinking = false # Whether we're currently in a blink animation
var last_blink_time = 0.0 # When we last blinked
var blink_interval_min = 2.0 # Minimum time between blinks
var blink_interval_max = 5.0 # Maximum time between blinks
var blink_duration = 0.33 # How long the blink animation lasts (faster now)
var idle_animation_timer = 0.0 # Timer to sync with idle animation cycle
var use_mirrored_idle = false # Whether to use mirrored idle after blinking
var mirrored_idle_timer = 0.0 # Timer for how long we've been in mirrored idle
var mirrored_idle_duration = 3.0 # How long to stay in mirrored idle

# Jump state tracking with enum
var jump_phase: JumpPhase = JumpPhase.NONE
var jump_land_timer = 0.0 # Timer for landing animation
var jump_land_duration = 0.25 # How long landing animation lasts
var last_velocity_y = 0.0 # Previous frame's Y velocity for jump phase detection
var jump_stuck_timer = 0.0 # Timer for detecting stuck jump phases

# Simple jump system
var just_jumped_off_ladder = false # Flag to prevent crouching after ladder jump

# Platformer improvement timers (now handled by PlatformerImprovements component)
var jump_buffer_timer: float = 0.0 # Timer for jump buffering
var coyote_timer: float = 0.0 # Timer for coyote time
var was_on_floor: bool = false # Track previous frame floor state

# Ladder centering system
var ladder_center_x: float = 0.0 # X position of the ladder center
var ladder_centering_strength: float = 200.0 # How strong the centering force is
var was_climbing: bool = false # Track if we were climbing in the previous frame

# Ladder tile coordinates (atlas coordinates)
const LADDER_TILES = [
	Vector2i(3, 2), # Original ladder tile
	Vector2i(5, 2), # Platform-ladder tile (one-way collision)
	Vector2i(5, 3) # Half ladder sprite
]

# Platform-ladder specific handling
const PLATFORM_LADDER_TILE = Vector2i(5, 2) # Platform-ladder tile with one-way collision
var platform_ladder_pass_through = false # Flag for passing through platform-ladder
var platform_ladder_pass_timer = 0.0 # Timer for pass-through duration
const PLATFORM_LADDER_PASS_DURATION = 0.15 # How long to allow pass-through (slightly shorter for snappier feel)

# Touch control state
var touch_active = false
var move_touch_index: int = -1
var touch_points: Dictionary = {}
var touch_start_pos: Vector2 = Vector2.ZERO
var touch_current_pos: Vector2 = Vector2.ZERO
var touch_start_time_ms: int = 0
var touch_horizontal_dir: float = 0.0
var touch_up_pressed = false
var touch_down_pressed = false
var touch_jump_queued = false
var touch_jump_hold_timer: float = 0.0

# Damage / hazard handling
@onready var health_manager = get_node("/root/HealthManager")
@export var damage_immunity_duration_ms: int = 2000  # Platformer standard: ~2s invulnerability + blink after hit
@export var stomp_bounce_velocity: float = -200.0
@export var spike_knockback_speed: float = 100.0
@export var spike_knockup_velocity: float = -180.0
var damage_immunity_until_ms: int = 0
const SPIKE_ATLAS_COORD: Vector2i = Vector2i(1, 1) # (col=1,row=1) second column/row in 0-based atlas

# Death state
var is_dead = false
var has_shown_death_knockback = false
var death_tile_hit = false # Flag for death tile contact
var was_touching_death_tile = false # Persistent flag for death tile contact
var damage_animation_timer = 0.0 # Timer for damage animation
var show_damage_animation = false # Flag to show damage animation
var last_lives: int = -1
var suppress_landing_sfx_until_ms: int = 0
# Death from enemy: damage jump + death_tile animation
var last_damage_from_enemy_position: Vector2 = Vector2.ZERO
var damaged_by_enemy_at_ms: int = -99999
var killed_by_enemy: bool = false
var enemy_death_knockback_timer: float = 0.0
@export var enemy_death_knockback_duration: float = 0.4
@export var enemy_death_knockback_speed: float = 80.0
@export var enemy_death_knockup_velocity: float = -160.0

# Shader for white flash effect
var white_flash_shader: Shader
var flash_intensity: float = 0.0
# Blink during invulnerability (platformer standard)
var _blink_invuln_timer: float = 0.0
@export var blink_interval_sec: float = 0.08

# Footstep timing
var footstep_timer: float = 0.0

# Death tile coordinates (atlas coordinates) - standing on these triggers respawn at last checkpoint
const DEATH_TILES = [
	Vector2i(0, 1), # (0,1)
	Vector2i(1, 0), # (1,0) spike
	Vector2i(1, 1), # (1,1)
	Vector2i(6, 0), # (6,0) spike
	Vector2i(6, 1), # (6,1) spike
	Vector2i(7, 2)  # (7,2) spike
]

func _physics_process(delta: float) -> void:
	# Always check for spike damage first, even when dead
	handle_spike_damage()
	
	# Check for death tiles
	handle_death_tiles()
	
	# If dead (game over: lives = 0), show death animation only; no respawn from damage
	if is_dead:
		if animated_sprite:
			animated_sprite.visible = true
		if killed_by_enemy and not has_shown_death_knockback:
			enemy_death_knockback_timer -= delta
			if enemy_death_knockback_timer <= 0:
				has_shown_death_knockback = true
			apply_gravity(delta)
			move_and_slide()
		update_animation()
		update_white_flash_shader(delta)
		return
	
	# Handle platform-ladder pass-through
	handle_platform_ladder_pass_through(delta)
	
	# Update damage animation timer
	if damage_animation_timer > 0:
		damage_animation_timer -= delta
		if damage_animation_timer <= 0:
			show_damage_animation = false
	
	# Update white flash shader
	update_white_flash_shader(delta)
	
	# Blink during invulnerability (platformer standard: visible feedback that you can't be hit)
	_update_invulnerability_blink(delta)
	
	# Update platformer timers (coyote time, jump buffering)
	update_platformer_timers(delta)
	update_touch_timers(delta)
	
	# Apply gravity if not climbing
	if not is_climbing:
		apply_gravity(delta)
	
	# Handle basic movement (this was missing!)
	handle_movement(delta)
	
	# Handle input processing
	process_inputs()
	
	# Handle climbing if in climb state
	if is_climbing:
		handle_climbing(delta)

	# Play footsteps while moving or climbing
	update_footsteps(delta)
	
	# Try to consume buffered jump after movement
	try_consume_buffered_jump()
	
	# Update animation and collision
	update_animation()
	update_collision_shape() # Update collision based on animation
	var pre_move_velocity_y = velocity.y
	move_and_slide()
	handle_stomp_on_enemies(pre_move_velocity_y)
	handle_landing_sfx(pre_move_velocity_y)

# State machine integration methods
func should_be_climbing() -> bool:
	"""Check if player should be in climbing state"""
	# Check if we're near a ladder (regardless of input)
	var tilemap = room_manager.current_room_instance.get_node("TileMapLayer") if room_manager and room_manager.current_room_instance else null
	if not tilemap:
		return false
	
	# Check for ladder tiles in a radius around the player
	var check_radius = 8
	for x in range(-check_radius, check_radius + 1, 4):
		for y in range(-check_radius, check_radius + 1, 4):
			var check_pos = global_position + Vector2(x, y)
			var tile_pos = tilemap.local_to_map(tilemap.to_local(check_pos))
			var tile_atlas_coords = tilemap.get_cell_atlas_coords(tile_pos)
			
			# Check if this is any ladder tile variant
			if tile_atlas_coords in LADDER_TILES:
				# Found ladder - can climb
				return true
	
	return false

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		var gravity_scale = 1.0
		
		# Higher gravity when falling
		if velocity.y > 0.0:
			gravity_scale = fall_gravity_scale
		# Variable jump height - cut jump if releasing early
		elif not _is_jump_held() and velocity.y < 0.0:
			gravity_scale = low_jump_gravity_scale
		
		velocity.y += gravity * gravity_scale * delta

func handle_movement(delta: float) -> void:
	"""Handle basic horizontal movement"""
	if _is_input_locked():
		return
		
	var direction = _get_horizontal_input()
	var current_speed = crouch_speed if is_crouching else speed
	
	# Handle horizontal movement
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * current_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

func update_footsteps(delta: float) -> void:
	"""Play spaced footsteps while walking or climbing."""
	var moving_on_floor = is_on_floor() and abs(velocity.x) > footstep_min_speed
	var moving_on_ladder = is_climbing and abs(velocity.y) > footstep_min_speed
	var should_play = moving_on_floor or moving_on_ladder

	if not should_play:
		footstep_timer = 0.0
		return

	footstep_timer -= delta
	if footstep_timer <= 0.0:
		if footstep_player and footstep_player.stream:
			footstep_player.play()
		footstep_timer = footstep_interval

func handle_stomp_on_enemies(pre_move_velocity_y: float) -> void:
	"""If we landed on an enemy (stomp), kill it and bounce. We get the collision; the enemy may not."""
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if not collider or not collider.is_in_group("enemies"):
			continue
		# Collision normal: when we land on top, normal points up (we hit floor below us)
		var n = col.get_normal()
		if n.y > -0.5:
			continue
		# We must have been falling (or at least not rising) to count as stomp
		if pre_move_velocity_y < -10:
			continue
		# Our feet at or above enemy top (we're above them)
		var my_bottom = global_position.y + 8
		var enemy_top = collider.global_position.y - 12
		if my_bottom > enemy_top + 8:
			continue
		# Stomp: kill enemy and bounce
		if collider.has_method("stomp_kill"):
			collider.stomp_kill()
			velocity.y = stomp_bounce_velocity
		return

func handle_landing_sfx(pre_move_velocity_y: float) -> void:
	"""Play landing sound when hitting the ground after a jump or big fall."""
	if Time.get_ticks_msec() < suppress_landing_sfx_until_ms:
		return
	if not was_on_floor and is_on_floor():
		var landing_speed = abs(pre_move_velocity_y)
		var from_jump = jump_phase != JumpPhase.NONE
		if from_jump or landing_speed >= land_min_fall_speed:
			if land_player and land_player.stream:
				land_player.play()

func process_inputs() -> void:
	"""Centralized input processing - handles all input states and transitions"""
	if _is_input_locked():
		return
	
	# Check for platform-ladder pass-through first
	check_platform_ladder_pass_through()
	
	# Check for ladder interaction
	check_ladder_interaction()
	
	# Handle crouch input
	handle_crouch_input()
	
	# Check ceiling clearance
	check_ceiling_clearance()
	
	# Handle jump input with priority (now includes buffering)
	handle_jump_input()
	
	# Handle state transitions
	handle_state_transitions()

func handle_jump_input() -> void:
	"""Handle jump input - UP key while moving with buffering"""
	# Check for UP key press and buffer it
	if _is_jump_just_pressed():
		jump_buffer_timer = jump_buffer_time
		touch_jump_queued = false
	
	# Try immediate jump if conditions are met
	if jump_buffer_timer > 0.0:
		# Can jump when on floor or in coyote time, and not crouching/climbing
		if (is_on_floor() or coyote_timer > 0.0) and not is_crouching and not is_climbing:
			do_jump()
			jump_buffer_timer = 0.0
			coyote_timer = 0.0
		# Special case: jumping while climbing
		elif is_climbing:
			# Break out of climbing and jump
			is_climbing = false
			
			# Reset crouching state when jumping off ladder
			is_crouching = false
			forced_crouch = false
			just_jumped_off_ladder = true
			
			# Jump off ladder
			do_jump()
			jump_buffer_timer = 0.0

func handle_state_transitions() -> void:
	"""Handle transitions between different movement states"""
	# If we were climbing and no longer should be, handle the transition
	if is_climbing and not should_be_climbing():
		is_climbing = false
		# Reset jump phase when transitioning away from climbing
		jump_phase = JumpPhase.NONE
		# Preserve any existing velocity for smooth transition

func do_jump(jump_strength: float = jump_velocity * jump_power) -> void:
	"""Centralized jump function for consistent behavior"""
	jump_phase = JumpPhase.UP
	velocity.y = jump_strength
	if jump_player and jump_player.stream:
		jump_player.play()
	# Clear any conflicting timers
	jump_buffer_timer = 0.0
	coyote_timer = 0.0

func try_consume_buffered_jump() -> void:
	"""Try to consume a buffered jump input after movement"""
	if jump_buffer_timer > 0.0:
		# Can jump if on floor or in coyote time, and not crouching/climbing
		if (is_on_floor() or coyote_timer > 0.0) and not is_crouching and not is_climbing:
			do_jump()
			jump_buffer_timer = 0.0
			coyote_timer = 0.0

func update_platformer_timers(delta: float) -> void:
	"""Update jump buffering and coyote time timers"""
	# Update jump buffer timer
	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta
	
	# Update coyote timer
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = max(0.0, coyote_timer - delta)
	
	# Reset jump phase when coyote time expires and we're not actually jumping
	if coyote_timer <= 0.0 and jump_phase != JumpPhase.NONE and not is_on_floor() and velocity.y >= 0:
		if jump_phase == JumpPhase.UP or jump_phase == JumpPhase.PEAK:
			jump_phase = JumpPhase.NONE
	
	# Track floor state for next frame
	was_on_floor = is_on_floor()

func handle_crouch_input() -> void:
	if _is_input_locked():
		return
	
	# Don't allow crouching immediately after jumping off ladder
	if just_jumped_off_ladder:
		# Reset the flag after a short delay
		just_jumped_off_ladder = false
		is_crouching = false
		forced_crouch = false
		return
	
	# Check if down is pressed (alone or with left/right)
	var down_pressed = _is_down_pressed()
	
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

func check_ceiling_clearance() -> void:
	# Only check ceiling clearance if we're not already crouching due to input
	var down_pressed = _is_down_pressed()
	
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
	query.collision_mask = 1 # Same collision mask as player
	query.exclude = [self.get_rid()] # Exclude the player's own collision
	
	# Check if there's any collision
	var result = space_state.intersect_shape(query, 1)
	
	# If no collision found, there's enough clearance
	return result.is_empty()

func check_ladder_interaction() -> void:
	if _is_input_locked():
		return
	
	# Use a more robust approach: check for ladder tiles in a radius around the player
	var tilemap = room_manager.current_room_instance.get_node("TileMapLayer") if room_manager and room_manager.current_room_instance else null
	if not tilemap:
		return
	
	# Check for ladder tiles and find the center position
	var ladder_found = false
	var ladder_tile_positions: Array[Vector2i] = []
	var check_radius = 1 # Check 8 pixels in each direction
	
	# Create a grid of positions to check around the player
	for x in range(-check_radius, check_radius + 1, 4): # Check every 4 pixels
		for y in range(-check_radius, check_radius + 1, 4):
			var check_pos = global_position + Vector2(x, y)
			var tile_pos = tilemap.local_to_map(tilemap.to_local(check_pos))
			var tile_atlas_coords = tilemap.get_cell_atlas_coords(tile_pos)
			
			# Check if this is any ladder tile variant
			if tile_atlas_coords in LADDER_TILES:
				ladder_found = true
				ladder_tile_positions.append(tile_pos)
	
	# Calculate ladder center if found
	if ladder_found and ladder_tile_positions.size() > 0:
		# Find the center tile position
		var total_x = 0
		for tile_pos in ladder_tile_positions:
			total_x += tile_pos.x
		var center_tile_x = float(total_x) / float(ladder_tile_positions.size())
		
		# Convert tile position to world position (center of the tile)
		var tile_size = tilemap.tile_set.tile_size
		ladder_center_x = center_tile_x * tile_size.x + (tile_size.x / 2.0)
	
	# Determine if player is actually inside a ladder tile (prevents snapping from nearby)
	var ladder_at_player = false
	if ladder_found:
		var player_tile_pos = tilemap.local_to_map(tilemap.to_local(global_position))
		var player_tile_atlas = tilemap.get_cell_atlas_coords(player_tile_pos)
		ladder_at_player = player_tile_atlas in LADDER_TILES
	
	# Handle ladder interaction
	if ladder_found and (_is_up_pressed() or _is_down_pressed()):
		var is_ascending = (not is_on_floor()) and velocity.y < 0.0
		# Special case: if we're standing ON TOP of platform-ladder and pressing down, don't start climbing
		# Let the pass-through mechanism handle it instead
		var should_prevent_climbing = false
		if _is_down_pressed():
			# Check if we're standing directly on top of a platform-ladder tile
			var check_pos = global_position + Vector2(0, 8) # Check 8 pixels below player center
			var tile_pos = tilemap.local_to_map(tilemap.to_local(check_pos))
			var tile_atlas_coords = tilemap.get_cell_atlas_coords(tile_pos)
			should_prevent_climbing = (tile_atlas_coords == PLATFORM_LADDER_TILE)
		
		# Start climbing unless we're standing on platform-ladder with down input
		# or we're still rising during a jump (prevents mid-air ladder snap)
		# and only when we're actually inside a ladder tile (prevents nearby grab)
		if not should_prevent_climbing and not is_ascending and ladder_at_player:
			is_climbing = true
			is_crouching = false # Can't crouch while climbing
	elif not ladder_found:
		# No ladder nearby, stop climbing
		if is_climbing:
			is_climbing = false

func check_platform_ladder_pass_through() -> void:
	"""Check if player is standing on platform-ladder and wants to pass through"""
	if _is_input_locked():
		return
	
	# Only check if we're on floor and not already climbing
	if not is_on_floor() or is_climbing:
		platform_ladder_pass_through = false
		platform_ladder_pass_timer = 0.0
		return
	
	# Check if we're standing on a platform-ladder tile
	var tilemap = room_manager.current_room_instance.get_node("TileMapLayer") if room_manager and room_manager.current_room_instance else null
	if not tilemap:
		return
	
	# Check tile directly below player's feet
	var check_pos = global_position + Vector2(0, 8) # Check 8 pixels below player center
	var tile_pos = tilemap.local_to_map(tilemap.to_local(check_pos))
	var tile_atlas_coords = tilemap.get_cell_atlas_coords(tile_pos)
	
	# Check if we're standing on platform-ladder and pressing down
	if tile_atlas_coords == PLATFORM_LADDER_TILE and _is_down_pressed():
		if not platform_ladder_pass_through:
			platform_ladder_pass_through = true
			platform_ladder_pass_timer = 0.0
	else:
		# Reset pass-through if not on platform-ladder or not pressing down
		if platform_ladder_pass_through:
			platform_ladder_pass_through = false
			platform_ladder_pass_timer = 0.0

func handle_climbing(delta: float) -> void:
	"""Handle climbing movement with smooth input processing and ladder centering"""
	# Stop gravity while climbing
	velocity.y = 0
	
	# Check if we just started climbing (immediate centering)
	if is_climbing and not was_climbing:
		# Just started climbing - immediately center on ladder
		if ladder_center_x != 0.0:
			global_position.x = ladder_center_x
			velocity.x = 0 # Stop any horizontal velocity
	
	# Handle vertical movement on ladder
	var vertical_input = 0.0
	if _is_up_pressed():
		vertical_input = -1.0
	elif _is_down_pressed():
		vertical_input = 1.0
	
	velocity.y = vertical_input * climb_speed
	
	# Handle horizontal movement while climbing
	var horizontal_input = _get_horizontal_input()
	if abs(horizontal_input) > 0:
		# Pressing left or right makes you fall off the ladder
		is_climbing = false
		# Reset jump phase when falling off ladder
		jump_phase = JumpPhase.NONE
		# Give a small horizontal push in the direction pressed
		velocity.x = horizontal_input * 50.0 # Small horizontal velocity
		# Let gravity take over
		velocity.y = 0
	else:
		# Apply gentle ladder centering when no horizontal input (maintains center during climb)
		apply_ladder_centering(delta)
	
	# Update climbing state for next frame
	was_climbing = is_climbing

func apply_ladder_centering(delta: float) -> void:
	"""Apply gentle centering force to maintain ladder center during climb"""
	if ladder_center_x == 0.0:
		return # No ladder center calculated yet
	
	# Calculate distance from ladder center
	var distance_from_center = ladder_center_x - global_position.x
	
	# Only apply centering if we're not already close to center (within 1 pixel for tighter control)
	if abs(distance_from_center) > 1.0:
		# Apply gentler centering force to maintain position during climb
		var centering_force = distance_from_center * (ladder_centering_strength * 0.5) * delta
		
		# Apply the centering force to velocity
		velocity.x = move_toward(velocity.x, centering_force, (ladder_centering_strength * 0.5) * delta)
	else:
		# If we're close to center, just decelerate smoothly
		velocity.x = move_toward(velocity.x, 0, friction * delta)

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

func handle_jump_phases() -> void:
	"""Handle jump phase transitions for animation"""
	# Check for jump interruption conditions first
	check_jump_interruption()
	
	# Handle jump phase transitions based on velocity
	if not is_on_floor() and jump_phase != JumpPhase.LAND:
		# Detect jump peak (velocity changes from negative to positive)
		if last_velocity_y < 0 and velocity.y >= 0 and jump_phase == JumpPhase.UP:
			jump_phase = JumpPhase.PEAK
		# Detect going down (velocity is positive)
		elif velocity.y > 0 and jump_phase == JumpPhase.PEAK:
			jump_phase = JumpPhase.DOWN
	
	# Handle landing phase
	if is_on_floor() and jump_phase != JumpPhase.NONE:
		if just_jumped_off_ladder:
			# Skip jump_land animation for ladder jumps
			jump_phase = JumpPhase.NONE
			just_jumped_off_ladder = false
		else:
			jump_phase = JumpPhase.LAND
			jump_land_timer = 0.0
	
	# Handle landing animation duration
	if jump_phase == JumpPhase.LAND:
		jump_land_timer += get_physics_process_delta_time()
		if jump_land_timer >= jump_land_duration:
			jump_phase = JumpPhase.NONE
	
	# Store current velocity for next frame
	last_velocity_y = velocity.y

func check_jump_interruption() -> void:
	"""Check for conditions that should interrupt/reset the jump phase"""
	# Reset jump phase if we're climbing (ladder takes priority)
	if is_climbing and jump_phase != JumpPhase.NONE:
		jump_phase = JumpPhase.NONE
		return
	
	# Reset jump phase if we're forced to crouch due to ceiling
	if forced_crouch and jump_phase != JumpPhase.NONE:
		jump_phase = JumpPhase.NONE
		return
	
	# Reset jump phase if we're manually crouching and on floor
	if is_crouching and is_on_floor() and jump_phase != JumpPhase.NONE:
		jump_phase = JumpPhase.NONE
		return
	
	# Check for ceiling collision during jump (velocity suddenly stops or reverses)
	if jump_phase in [JumpPhase.UP, JumpPhase.PEAK] and velocity.y >= 0 and last_velocity_y < -50:
		# Player hit ceiling during jump, try ledge push-around
		handle_ledge_push_around()
		# Transition to down phase
		jump_phase = JumpPhase.DOWN
		return
	
	# Reset jump phase if we've been in air too long without proper jump velocity
	# This handles cases where jump gets stuck due to collision issues
	if not is_on_floor() and jump_phase != JumpPhase.NONE:
		# If we're not moving up and have been in jump phase for too long, reset
		if velocity.y >= 0 and jump_phase in [JumpPhase.UP, JumpPhase.PEAK]:
			# Add a small timer to prevent premature reset
			jump_stuck_timer += get_physics_process_delta_time()
			if jump_stuck_timer > 0.5: # 0.5 seconds max
				jump_phase = JumpPhase.DOWN # Transition to down phase
				jump_stuck_timer = 0.0
		else:
			# Reset timer if we're moving properly
			jump_stuck_timer = 0.0
	else:
		# Reset timer when on floor
		jump_stuck_timer = 0.0

func handle_ledge_push_around() -> void:
	"""Try to push player around ledge when hitting ceiling"""
	var space_state = get_world_2d().direct_space_state
	
	# Check if there's space to the left and right
	var left_probe_pos = global_position + Vector2(-ledge_probe_offset, -collision_jump_size.y)
	var right_probe_pos = global_position + Vector2(ledge_probe_offset, -collision_jump_size.y)
	
	# Use the correct Godot 4 API for intersect_point
	var left_free = space_state.intersect_point(left_probe_pos).is_empty()
	var right_free = space_state.intersect_point(right_probe_pos).is_empty()
	
	# Push in the direction that has space
	if right_free and not left_free:
		global_position.x += ledge_push_amount
	elif left_free and not right_free:
		global_position.x -= ledge_push_amount

# All the existing methods for damage, death, animation, etc. are preserved below
# ... (continuing with all existing functionality)

func handle_spike_damage() -> void:
	# Respect damage immunity (platformer standard: no damage during blink)
	if Time.get_ticks_msec() < damage_immunity_until_ms:
		return
	
	var tilemap = room_manager.current_room_instance.get_node("TileMapLayer") if room_manager and room_manager.current_room_instance else null
	if not tilemap:
		return
	
	var sample_points: Array[Vector2] = []
	var half_width = 3.0
	var half_height = 6.0
	sample_points.append(global_position + Vector2(0, 0))
	sample_points.append(global_position + Vector2(-half_width, 0))
	sample_points.append(global_position + Vector2(half_width, 0))
	sample_points.append(global_position + Vector2(0, -half_height))
	sample_points.append(global_position + Vector2(-half_width, -half_height))
	sample_points.append(global_position + Vector2(half_width, -half_height))

	var spike_hit = false
	for p in sample_points:
		var local_p = tilemap.to_local(p)
		var map_pos: Vector2i = tilemap.local_to_map(local_p)
		var atlas: Vector2i = tilemap.get_cell_atlas_coords(map_pos)
		if atlas == SPIKE_ATLAS_COORD and not (atlas in DEATH_TILES):
			spike_hit = true
			break

	if not spike_hit:
		return

	if health_manager:
		health_manager.take_damage(1)
	damage_immunity_until_ms = Time.get_ticks_msec() + damage_immunity_duration_ms
	input_locked_until_ms = max(input_locked_until_ms, Time.get_ticks_msec() + int(damage_immunity_duration_ms * 0.4))

	var knock_dir = -1 if velocity.x > 0 else 1
	if abs(velocity.x) < 1.0:
		knock_dir = 1 if animated_sprite.flip_h else -1
	velocity.x = knock_dir * spike_knockback_speed
	velocity.y = spike_knockup_velocity

func handle_death_tiles() -> void:
	"""Check if player is touching death tiles and set animation flag"""
	# If dead and already showed final knockback, stop checking death tiles entirely
	if is_dead and has_shown_death_knockback:
		return
	
	var tilemap = room_manager.current_room_instance.get_node("TileMapLayer") if room_manager and room_manager.current_room_instance else null
	if not tilemap:
		return
	
	# Sample a few points around the player's body to detect death tiles
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

	var death_tile_detected = false
	var death_hit_atlas: Vector2i = Vector2i(-1, -1)
	var death_hit_map: Vector2i = Vector2i(-1, -1)
	for p in sample_points:
		var local_p = tilemap.to_local(p)
		var map_pos: Vector2i = tilemap.local_to_map(local_p)
		var atlas: Vector2i = tilemap.get_cell_atlas_coords(map_pos)
		if atlas in DEATH_TILES:
			death_tile_detected = true
			death_hit_atlas = atlas
			death_hit_map = map_pos
			break

	if death_tile_detected:
		if debug_death_tiles:
			print("[DEATH] hit atlas=", death_hit_atlas, " map=", death_hit_map, " local_p=", tilemap.to_local(global_position), " was_touching=", was_touching_death_tile)
		death_tile_hit = true
		# Respawn at last checkpoint (same as falling into a pit) so player doesn't get stuck losing lives
		if not was_touching_death_tile and health_manager and health_manager.has_method("request_respawn_from_fall"):
			trigger_white_flash()
			health_manager.request_respawn_from_fall()
		was_touching_death_tile = true
	else:
		was_touching_death_tile = false

func _on_health_changed(current_lives: int, _max_lives: int):
	"""Handle health changes - set dead state when lives reach 0, and show damage filter on any damage."""
	var took_damage = last_lives != -1 and current_lives < last_lives
	var recently_hit_by_enemy = (Time.get_ticks_msec() - damaged_by_enemy_at_ms) < 500

	if took_damage:
		trigger_white_flash()
		if current_lives > 0:
			suppress_landing_sfx_until_ms = Time.get_ticks_msec() + 400
			# Grant i-frames after any damage so we don't get hit again immediately
			damage_immunity_until_ms = Time.get_ticks_msec() + damage_immunity_duration_ms
			# Non-fatal enemy hit: small knockback so the hit feels solid
			if recently_hit_by_enemy and last_damage_from_enemy_position != Vector2.ZERO:
				var away = (global_position - last_damage_from_enemy_position).normalized()
				velocity.x = away.x * enemy_death_knockback_speed * 0.6
				velocity.y = enemy_death_knockup_velocity * 0.5
	last_lives = current_lives

	if current_lives <= 0 and not is_dead:
		is_dead = true
		if recently_hit_by_enemy:
			killed_by_enemy = true
			has_shown_death_knockback = false
			enemy_death_knockback_timer = enemy_death_knockback_duration
			var away = (global_position - last_damage_from_enemy_position).normalized()
			if away.length_squared() < 0.01:
				away = Vector2(-1, 0) if animated_sprite.flip_h else Vector2(1, 0)
			velocity.x = away.x * enemy_death_knockback_speed
			velocity.y = enemy_death_knockup_velocity
		else:
			has_shown_death_knockback = true

func update_animation() -> void:
	# If dead, show appropriate animation using named clips
	if is_dead:
		if not has_shown_death_knockback:
			# During final knockback, show falling sprite via jump_down animation
			if animated_sprite.animation != "jump_down":
				animated_sprite.play("jump_down")
		else:
			# After knockback, show appropriate dead sprite based on how death occurred
			if was_touching_death_tile or killed_by_enemy:
				# Show death tile sprite for death tile or enemy kill, and apply damage filter
				if animated_sprite.animation != "death_tile":
					animated_sprite.play("death_tile")
					trigger_white_flash()
			else:
				# Show regular dead sprite for other deaths
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
	elif not is_on_floor() or jump_phase != JumpPhase.NONE:
		# Jump animations have priority - use specific jump phase animation
		match jump_phase:
			JumpPhase.UP:
				new_animation = "jump_up"
			JumpPhase.PEAK:
				new_animation = "jump_peak"
			JumpPhase.DOWN:
				new_animation = "jump_down"
			JumpPhase.LAND:
				new_animation = "jump_land"
			_:
				new_animation = "jump_up" # Fallback to jump_up
	elif is_crouching:
		# Use duck animation for idle ducking, crouch animation for crouch walking
		if abs(velocity.x) > 5:
			new_animation = "crouch"
		else:
			new_animation = "duck"
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
		if not is_blinking and idle_timer > 1.0: # Wait at least 1 second before blinking
			var time_since_last_blink = idle_timer - last_blink_time
			var should_blink = time_since_last_blink > RNG.randf_range(blink_interval_min, blink_interval_max)
			
			if should_blink:
				# Sync the blink with the idle animation cycle
				# The idle animation has a 0.5 second cycle (2 frames at 4.0 speed = 0.5s total)
				var idle_cycle_duration = 0.5 # Matches idle animation speed
				var cycle_progress = fmod(idle_animation_timer, idle_cycle_duration)
				
				# Start blinking at the beginning of the next idle cycle
				var time_to_next_cycle = idle_cycle_duration - cycle_progress
				if time_to_next_cycle < 0.1: # If we're very close to cycle start, start immediately
					is_blinking = true
					blink_timer = 0.0
					last_blink_time = idle_timer
					idle_animation_timer = 0.0 # Reset to sync with blink
	else:
		# Reset timers when not idle
		idle_timer = 0.0
		is_blinking = false
		blink_timer = 0.0
		idle_animation_timer = 0.0
		use_mirrored_idle = false # Reset mirrored idle when moving
		mirrored_idle_timer = 0.0
	
	# Handle blink animation duration
	if is_blinking:
		blink_timer += get_physics_process_delta_time()
		if blink_timer >= blink_duration:
			is_blinking = false
			blink_timer = 0.0
			use_mirrored_idle = true # Switch to mirrored idle after blinking

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
		"jump", "jump_up", "jump_peak", "jump_down", "jump_land":
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

func trigger_white_flash():
	"""Trigger white flash effect when touching death tiles"""
	flash_intensity = flash_intensity_max
	damage_animation_timer = flash_duration # Flash for the configured duration

func update_white_flash_shader(_delta: float):
	"""Update white flash shader parameters"""
	if damage_animation_timer > 0:
		var progress = 1.0 - (damage_animation_timer / flash_duration) # Normalize to 0-1
		flash_intensity = flash_intensity_max * (1.0 - progress) # Fade out over time
	else:
		flash_intensity = 0.0
	
	# Apply shader parameters
	if animated_sprite and animated_sprite.material:
		animated_sprite.material.set_shader_parameter("flash_intensity", flash_intensity)
		animated_sprite.material.set_shader_parameter("flash_duration", 0.0) # Not used in current shader

func on_damaged_by_enemy(enemy_pos: Vector2) -> void:
	"""Called by enemies when they deal damage so we can show damage jump + death_tile if we die."""
	last_damage_from_enemy_position = enemy_pos
	damaged_by_enemy_at_ms = Time.get_ticks_msec()

func reset_death_state():
	"""Reset death state when respawning"""
	is_dead = false
	has_shown_death_knockback = false
	death_tile_hit = false
	was_touching_death_tile = false
	killed_by_enemy = false
	enemy_death_knockback_timer = 0.0
	show_damage_animation = false
	damage_animation_timer = 0.0
	flash_intensity = 0.0
	# Brief invincibility + blink after respawn (platformer standard)
	damage_immunity_until_ms = Time.get_ticks_msec() + damage_immunity_duration_ms
	if animated_sprite:
		animated_sprite.visible = true
	_blink_invuln_timer = 0.0

func _is_input_locked() -> bool:
	return Time.get_ticks_msec() < input_locked_until_ms

func get_damage_immunity_remaining_ms() -> int:
	"""Used by enemies to avoid damaging during i-frames (e.g. after respawn)."""
	return max(0, damage_immunity_until_ms - Time.get_ticks_msec())

func _update_invulnerability_blink(delta: float) -> void:
	"""Blink sprite while invulnerable (platformer standard)."""
	var invulnerable = Time.get_ticks_msec() < damage_immunity_until_ms
	if not animated_sprite:
		return
	if invulnerable:
		_blink_invuln_timer += delta
		if _blink_invuln_timer >= blink_interval_sec:
			_blink_invuln_timer = 0.0
			animated_sprite.visible = !animated_sprite.visible
	else:
		animated_sprite.visible = true
		_blink_invuln_timer = 0.0

func _draw():
	"""Debug drawing for collision shapes and movement"""
	if not debug_draw_collision and not debug_draw_movement:
		return
	
	if debug_draw_collision and collision_shape:
		var shape = collision_shape.shape as RectangleShape2D
		if shape:
			# Draw collision shape
			var rect = Rect2(collision_shape.position - shape.size / 2, shape.size)
			draw_rect(rect, Color(0.176471, 0.996078, 0.223529, 1), false, 2.0)
	
	if debug_draw_movement:
		# Draw velocity vector
		var velocity_end = global_position + velocity * 0.1
		draw_line(Vector2.ZERO, velocity_end - global_position, Color(0.176471, 0.996078, 0.223529, 1), 2.0)
		# Draw movement direction
		if abs(velocity.x) > 0:
			var direction = 1 if velocity.x > 0 else -1
			draw_line(Vector2.ZERO, Vector2(direction * 20, 0), Color(0.176471, 0.996078, 0.223529, 1), 3.0)

func handle_platform_ladder_pass_through(delta: float) -> void:
	"""Handle the platform-ladder pass-through mechanism"""
	if not platform_ladder_pass_through:
		return
	
	# Update timer
	platform_ladder_pass_timer += delta
	
	# Apply downward velocity to pass through the one-way collision
	if platform_ladder_pass_timer < PLATFORM_LADDER_PASS_DURATION:
		# Apply strong downward velocity to pass through
		velocity.y = 250.0 # Strong but not excessive downward movement
		
		# Smooth direct position adjustment based on delta time
		global_position.y += 4.0 # Direct position adjustment
	else:
		# Pass-through duration expired, reset
		platform_ladder_pass_through = false
		platform_ladder_pass_timer = 0.0
