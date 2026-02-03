class_name Enemy
extends CharacterBody2D

# Simple enemy with state machine AI
# Walks on platforms and turns at edges and walls only (ignores ladders and collectibles)

# Enums for better code organization
enum EnemyState {
	IDLE,
	CHASING,
	ATTACKING,
	DEAD
}

enum EnemyType {
	BASIC,
	FAST,
	HEAVY
}

# Platform end tiles in arc_tileset: standing on or about to step onto these = turn around
# (1,2) = end of a longer platform, (0,3) = single-tile platform
const PLATFORM_END_TILES = [
	Vector2i(1, 2),
	Vector2i(0, 3)
]

@export_group("Enemy Stats")
@export var speed: float = 18.0
@export var detection_range: float = 100.0
@export var attack_range: float = 20.0
@export var attack_damage: int = 1
@export var max_health: int = 3
@export var enemy_color: Color = Color(0.176471, 0.996078, 0.223529, 1)

@export_group("AI Behavior")
@export var chase_speed_multiplier: float = 1.2
@export var idle_wait_time: float = 2.0
@export var attack_cooldown: float = 1.0

@export_group("Platform Walking")
@export var tile_size: int = 8
@export var edge_ray_length: float = 28.0
@export var edge_check_offset: float = 4.0  # How far ahead of center to check for floor drop-off (smaller = turn right at edge)
@export var edge_check_feet_offset: float = 8.0
@export var turn_around_cooldown: float = 0.5  # Minimum seconds between flips to avoid rapid flip-flop between two obstacles

@export_group("Stomp / Collision")
@export var enemy_top_offset: float = -12.0
@export var stomp_margin: float = 6.0
@export var overlap_horizontal_margin: float = 14.0

@export_group("Visual Settings")
@export var debug_draw_ai: bool = false
@export var debug_draw_detection: bool = false

@onready var animated_sprite = $AnimatedSprite2D
@onready var state_machine = $StateMachine
@onready var movement_component = $MovementComponent
@onready var room_manager = get_node_or_null("/root/RoomManager")

var target: CharacterBody2D
var health: int
var is_dead: bool = false

# Walk direction: 1 = right, -1 = left. Only change when hitting wall/edge/obstacle.
var walk_direction: float = 1.0
var _last_turn_around_time: float = -999.0  # For cooldown to prevent rapid flipping

# Enemy state with getter/setter
var _enemy_state: EnemyState = EnemyState.IDLE
var enemy_state: EnemyState:
	get:
		return _enemy_state
	set(value):
		_enemy_state = value
		# Add any state change logic here if needed

# Enemy type with getter/setter
var _enemy_type: EnemyType = EnemyType.BASIC
var enemy_type: EnemyType:
	get:
		return _enemy_type
	set(value):
		_enemy_type = value
		# Add any type change logic here if needed

func _ready():
	# Add to enemy group
	add_to_group("enemies")
	# Run after the player so stomp is detected before we can deal damage this frame
	set_physics_process_priority(100)
	
	# Initialize health
	health = max_health
	
	# Apply visual settings
	if animated_sprite:
		animated_sprite.modulate = enemy_color
	
	# Find player target
	target = get_tree().get_first_node_in_group("player")
	
	# Start state machine in idle
	if state_machine:
		state_machine.change_state("idle")

func _physics_process(delta: float):
	if is_dead:
		return
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	
	move_and_slide()
	
	# Check collisions with player: stomp from above = kill enemy (no player damage), side = damage player
	_check_player_collision()
	
	# Safety: if we still detect edge/wall after moving (e.g. we slipped), turn and stop horizontal movement this frame
	if should_turn_around():
		turn_around()
		velocity.x = 0

func take_damage(amount: int):
	health -= amount
	if health <= 0:
		die()

func die():
	is_dead = true
	queue_free()

func _is_stomp(collider: Node2D) -> bool:
	if not collider is CharacterBody2D:
		return false
	var player = collider as CharacterBody2D
	# Player must be moving downward (landing on us)
	if player.velocity.y < 0:
		return false
	# Player's feet must be at or above our top (player is above us)
	var player_bottom = player.global_position.y + 8
	var my_top = global_position.y + enemy_top_offset
	if player_bottom > my_top + stomp_margin:
		return false
	# Horizontally overlapping
	if abs(player.global_position.x - global_position.x) > overlap_horizontal_margin:
		return false
	return true

func _check_player_collision():
	"""Only handle stomp. Damage is dealt only from Attack state (perform_attack) so we get one hit per attack."""
	if not target:
		return
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if not collider or not collider.is_in_group("player"):
			continue
		if _is_stomp(collider):
			stomp_kill()
		# Side contact: no damage here; Attack state deals damage once per attack
		return

func _damage_player():
	"""Deal damage to player. Called only from Attack state. Notify player first so death jump/tile work."""
	if not target:
		return
	# Respect player invincibility (e.g. just respawned)
	if target.has_method("get_damage_immunity_remaining_ms") and target.get_damage_immunity_remaining_ms() > 0:
		return
	if target.has_method("on_damaged_by_enemy"):
		target.on_damaged_by_enemy(global_position)
	var health_manager = get_node_or_null("/root/HealthManager")
	if health_manager:
		health_manager.take_damage(attack_damage)

func stomp_kill():
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	# Stop state machine so it doesn't keep updating animation or velocity
	if state_machine:
		state_machine.set_physics_process(false)
		state_machine.set_process(false)
	if animated_sprite:
		if not animated_sprite.animation_finished.is_connected(_on_dead_animation_finished):
			animated_sprite.animation_finished.connect(_on_dead_animation_finished)
		animated_sprite.play("dead")
		# Fallback: remove after delay in case animation_finished doesn't fire
		_dead_remove_timer = get_tree().create_timer(0.45) # 4 frames @ 10 FPS = 0.4s, plus a small buffer
		_dead_remove_timer.timeout.connect(_on_dead_remove_timeout)
	else:
		queue_free()

var _dead_remove_timer: SceneTreeTimer

func _on_dead_animation_finished():
	if is_dead:
		queue_free()

func _on_dead_remove_timeout():
	if is_dead and is_instance_valid(self):
		queue_free()

func get_distance_to_target() -> float:
	if not target:
		return 999.0
	return global_position.distance_to(target.global_position)

func get_direction_to_target() -> Vector2:
	if not target:
		return Vector2.ZERO
	return (target.global_position - global_position).normalized()

func get_tilemap() -> TileMapLayer:
	if not room_manager or not room_manager.current_room_instance:
		return null
	return room_manager.current_room_instance.get_node_or_null("TileMapLayer")

func get_tile_atlas_at_position(world_pos: Vector2) -> Vector2i:
	var tilemap = get_tilemap()
	if not tilemap:
		return Vector2i(-1, -1)
	var local = tilemap.to_local(world_pos)
	var map_pos = tilemap.local_to_map(local)
	return tilemap.get_cell_atlas_coords(map_pos)

func at_platform_end() -> bool:
	var tilemap = get_tilemap()
	if not tilemap:
		return false
	var feet_pos = global_position + Vector2(0, edge_check_feet_offset)
	# Tile we're standing on: if it's a platform-end tile, we're at the end
	var atlas_under = get_tile_atlas_at_position(feet_pos)
	if atlas_under in PLATFORM_END_TILES:
		return true
	# Tile ahead in walk direction: if it's a platform-end tile, we're about to step onto the end
	var ahead_pos = feet_pos + Vector2(walk_direction * tile_size, 0)
	var atlas_ahead = get_tile_atlas_at_position(ahead_pos)
	if atlas_ahead in PLATFORM_END_TILES:
		return true
	return false

func no_floor_ahead() -> bool:
	var space = get_world_2d().direct_space_state
	# Check from in front of our feet: is there ground below?
	var check_x = walk_direction * edge_check_offset
	var from_pos = global_position + Vector2(check_x, edge_check_feet_offset)
	var to_pos = from_pos + Vector2(0, edge_ray_length)
	var query = PhysicsRayQueryParameters2D.create(from_pos, to_pos)
	query.exclude = [get_rid()]
	var result = space.intersect_ray(query)
	return result.is_empty()

func is_wall_ignorable() -> bool:
	"""True if we're touching a wall and every collision is with the player or a collectible (don't turn)."""
	if not is_on_wall():
		return false
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if not collider:
			return false
		if collider.is_in_group("player"):
			continue
		if collider.is_in_group("collectible"):
			continue
		return false
	return get_slide_collision_count() > 0

func should_turn_around() -> bool:
	if not is_on_floor():
		return false
	# Turn at walls (pipes, solid tiles), but not when only touching player or collectibles
	if is_on_wall() and not is_wall_ignorable():
		return true
	# Turn at platform end tiles: (1,2) end of longer platform, (0,3) single-tile platform
	if at_platform_end():
		return true
	# Turn at platform edge (no ground ahead) - fallback if tile check misses
	if no_floor_ahead():
		return true
	# Ladders and gems are ignored - enemy walks past them
	return false

func turn_around():
	var now = Time.get_ticks_msec() / 1000.0
	if now - _last_turn_around_time < turn_around_cooldown:
		return
	_last_turn_around_time = now
	walk_direction = -walk_direction

func _draw():
	"""Debug drawing for AI behavior and detection ranges"""
	if not debug_draw_ai and not debug_draw_detection:
		return
	
	if debug_draw_detection:
		# Draw detection range
		draw_arc(Vector2.ZERO, detection_range, 0, TAU, 32, Color(0.176471, 0.996078, 0.223529, 1), 2.0)
		# Draw attack range
		draw_arc(Vector2.ZERO, attack_range, 0, TAU, 16, Color(0.176471, 0.996078, 0.223529, 1), 2.0)
	
	if debug_draw_ai and target:
		# Draw line to target
		var target_pos = target.global_position - global_position
		draw_line(Vector2.ZERO, target_pos, Color(0.176471, 0.996078, 0.223529, 1), 2.0)
