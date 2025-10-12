class_name PlayerRefactored
extends CharacterBody2D

# Refactored player using state machine
# This is a cleaner version of the original Player.gd

# Movement constants
const SPEED = 60.0
const CROUCH_SPEED = 30.0
const CLIMB_SPEED = 40.0
const JUMP_VELOCITY = -240.0
const ACCELERATION = 400.0
const FRICTION = 400.0

# Platformer improvements
@export_group("Platformer Improvements")
@export var jump_buffer_time: float = 0.1
@export var coyote_time: float = 0.1
@export var fall_gravity_scale: float = 2.0
@export var low_jump_gravity_scale: float = 1.8

# Collision system
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

# References
@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var state_machine = $StateMachine
@onready var movement_component = $MovementComponent
@onready var room_manager = get_node("/root/RoomManager")
@onready var health_manager = get_node("/root/HealthManager")

# State variables
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_crouching = false
var is_climbing = false
var forced_crouch = false
var just_jumped_off_ladder = false

# Ladder system
const LADDER_TILES = [
	Vector2i(3, 2), # Original ladder tile
	Vector2i(5, 2), # Platform-ladder tile
	Vector2i(5, 3)  # Half ladder sprite
]

# Damage system
@export var damage_immunity_duration_ms: int = 500
@export var spike_knockback_speed: float = 100.0
@export var spike_knockup_velocity: float = -180.0
var damage_immunity_until_ms: int = 0
const SPIKE_ATLAS_COORD: Vector2i = Vector2i(1, 1)

# Death state
var is_dead = false
var has_shown_death_knockback = false

func _ready():
	# Add player to a group for easy access
	add_to_group("player")
	
	# Listen for room changes
	if room_manager:
		room_manager.room_changed.connect(_on_room_changed)
	
	# Listen for health changes
	if health_manager:
		health_manager.health_changed.connect(_on_health_changed)

func _physics_process(delta: float) -> void:
	# Always check for spike damage first
	handle_spike_damage()
	
	# If dead, only show dead animation
	if is_dead:
		update_animation()
		return
	
	# Apply gravity if not climbing
	if not is_climbing:
		apply_gravity(delta)
	
	# Update collision shape
	update_collision_shape()
	
	# Move the player
	move_and_slide()

func apply_gravity(delta: float) -> void:
	"""Apply gravity with variable jump height"""
	if not is_on_floor():
		var gravity_scale = 1.0
		
		# Higher gravity when falling
		if velocity.y > 0.0:
			gravity_scale = fall_gravity_scale
		# Variable jump height - cut jump if releasing early
		elif not Input.is_action_pressed("ui_up") and velocity.y < 0.0:
			gravity_scale = low_jump_gravity_scale
		
		velocity.y += gravity * gravity_scale * delta

func should_be_climbing() -> bool:
	"""Check if player should be in climbing state"""
	var tilemap = room_manager.current_room_instance.get_node("TileMapLayer") if room_manager and room_manager.current_room_instance else null
	if not tilemap:
		return false
	
	# Check for ladder tiles in a radius around the player
	var check_radius = 8
	for x in range(-check_radius, check_radius + 1, 4):
		for y in range(-check_radius, check_radius + 1, 4):
			var check_pos = global_position + Vector2(x, y)
			var tile_pos = tilemap.local_to_map(check_pos)
			var tile_atlas_coords = tilemap.get_cell_atlas_coords(tile_pos)
			
			if tile_atlas_coords in LADDER_TILES:
				return true
	
	return false

func handle_spike_damage() -> void:
	"""Handle spike damage detection"""
	# Respect damage immunity window
	if Time.get_ticks_msec() < damage_immunity_until_ms and not is_dead:
		return
	
	# If dead and already showed final knockback, stop checking
	if is_dead and has_shown_death_knockback:
		return
	
	var tilemap = room_manager.current_room_instance.get_node("TileMapLayer") if room_manager and room_manager.current_room_instance else null
	if not tilemap:
		return
	
	# Sample points around the player's body
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
		var map_pos: Vector2i = tilemap.local_to_map(p)
		var atlas: Vector2i = tilemap.get_cell_atlas_coords(map_pos)
		if atlas == SPIKE_ATLAS_COORD:
			spike_hit = true
			break

	if not spike_hit:
		return

	# Handle spike damage
	if not is_dead:
		if health_manager:
			if health_manager.has_method("take_damage_no_respawn"):
				health_manager.take_damage_no_respawn(1)
			else:
				health_manager.take_damage(1)
		
		damage_immunity_until_ms = Time.get_ticks_msec() + damage_immunity_duration_ms
	else:
		if not has_shown_death_knockback:
			has_shown_death_knockback = true

	# Apply knockback
	var knock_dir = -1 if velocity.x > 0 else 1
	if abs(velocity.x) < 1.0:
		knock_dir = 1 if animated_sprite.flip_h else -1
	
	velocity.x = knock_dir * spike_knockback_speed
	velocity.y = spike_knockup_velocity

func update_animation() -> void:
	"""Update player animation based on current state"""
	if is_dead:
		if not has_shown_death_knockback:
			animated_sprite.play("jump_down")
		else:
			animated_sprite.play("dead")
		return
	
	# Get animation from state machine
	var animation = state_machine.get_current_animation()
	if animated_sprite.animation != animation:
		animated_sprite.play(animation)

func update_collision_shape() -> void:
	"""Update collision shape based on current state"""
	var shape = collision_shape.shape as RectangleShape2D
	if not shape:
		return
	
	# Apply collision based on current state
	match state_machine.get_current_state_name():
		"idle":
			shape.size = collision_idle_size
			collision_shape.position = collision_idle_offset
		"walk":
			shape.size = collision_walk_size
			collision_shape.position = collision_walk_offset
		"jump":
			shape.size = collision_jump_size
			collision_shape.position = collision_jump_offset
		"crouch":
			shape.size = collision_crouch_size
			collision_shape.position = collision_crouch_offset
		"climb":
			shape.size = collision_climb_size
			collision_shape.position = collision_climb_offset

func check_ceiling_clearance_for_full_height() -> bool:
	"""Check if there's enough ceiling clearance for full height"""
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	
	var test_shape = RectangleShape2D.new()
	test_shape.size = collision_idle_size
	
	var test_transform = Transform2D(0, global_position + collision_idle_offset)
	
	query.shape = test_shape
	query.transform = test_transform
	query.collision_mask = 1
	query.exclude = [self.get_rid()]
	
	var result = space_state.intersect_shape(query, 1)
	return result.is_empty()

func handle_ledge_push_around() -> void:
	"""Try to push player around ledge when hitting ceiling"""
	var space_state = get_world_2d().direct_space_state
	
	var left_probe_pos = global_position + Vector2(-6, -collision_jump_size.y)
	var right_probe_pos = global_position + Vector2(6, -collision_jump_size.y)
	
	var left_free = space_state.intersect_point(left_probe_pos).is_empty()
	var right_free = space_state.intersect_point(right_probe_pos).is_empty()
	
	if right_free and not left_free:
		global_position.x += 6
	elif left_free and not right_free:
		global_position.x -= 6

func _on_health_changed(current_lives: int, _max_lives: int):
	"""Handle health changes"""
	if current_lives <= 0 and not is_dead:
		is_dead = true

func _on_room_changed(_room_data, _spawn_pos):
	"""Handle room changes"""
	velocity = Vector2.ZERO
