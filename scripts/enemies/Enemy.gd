class_name Enemy
extends CharacterBody2D

# Simple enemy with state machine AI
# Walks on platforms and turns at edges and walls only (ignores ladders and collectibles)

# Enums for better code organization
enum EnemyState {
	IDLE,
	SUSPICIOUS,
	CHASING,
	ATTACKING,
	SEARCHING,
	HURT,
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

# Ladder / passthrough tiles: enemy walks through these (no turn). Same as player ladder tiles + (5,3).
const PASSTHROUGH_TILES = [
	Vector2i(3, 2),
	Vector2i(5, 2),
	Vector2i(5, 3)
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
@export var attack_speed_multiplier: float = 1.5  # When player in sight (attack state), move faster toward them
@export var same_level_y_threshold: float = 20.0  # Max vertical distance for "same platform"; attack only when player on floor (not on ladder/jumping)
@export var idle_wait_time: float = 2.0
@export var attack_cooldown: float = 1.0

@export_group("Vision")
@export var vision_range: float = 120.0  # Direct vision range
@export var vision_angle: float = 60.0  # Half-angle of vision cone in degrees
@export var peripheral_range: float = 60.0  # Shorter range for peripheral vision
@export var peripheral_angle: float = 120.0  # Wider angle for peripheral detection

@export_group("Awareness")
@export var suspicion_buildup_rate: float = 2.0  # How fast awareness increases when player glimpsed
@export var suspicion_decay_rate: float = 0.5  # How fast awareness decreases when player not seen
@export var alert_threshold: float = 1.0  # Awareness level needed to become fully alert
@export var search_duration: float = 4.0  # How long to search after losing player

@export_group("Personality")
@export_range(0.0, 1.0) var aggression: float = 0.5  # Affects attack range, chase speed, telegraph duration
@export_range(0.0, 1.0) var caution: float = 0.5  # Affects detection range, retreat threshold
@export_range(0.0, 1.0) var persistence: float = 0.5  # Affects search duration, awareness decay

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

# Awareness system state
var awareness_level: float = 0.0  # 0 = unaware, 1+ = fully alert
var last_known_player_position: Vector2 = Vector2.ZERO
var time_since_player_seen: float = 999.0  # Large initial value = haven't seen player
var _can_currently_see_player: bool = false  # Cached each frame

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
	
	# Visual settings - keep sprite at original colors
	if animated_sprite:
		animated_sprite.modulate = Color.WHITE
	
	# Find player target
	target = get_tree().get_first_node_in_group("player")
	
	# Start state machine in idle
	if state_machine:
		state_machine.change_state("idle")
		# Run state physics before this node so attack state can set safe velocity before move_and_slide (avoid stepping off edges)
		state_machine.set_physics_process_priority(50)

func _physics_process(delta: float):
	if is_dead:
		return
	
	# Update awareness system
	update_awareness(delta)
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	
	move_and_slide()
	
	# Check collisions with player: stomp from above = kill enemy (no player damage), side = damage player
	_check_player_collision()
	
	# Safety: if we still detect edge/wall after moving (e.g. we slipped), turn and stop horizontal movement this frame
	# (Skip in attack or hurt state - state already set safe velocity before we moved)
	var current_state = state_machine.get_current_state_name()
	if current_state != "attack" and current_state != "hurt" and should_turn_around():
		turn_around()
		velocity.x = 0
	
	# Request redraw for debug visualization
	if debug_draw_ai or debug_draw_detection:
		queue_redraw()

func take_damage(amount: int):
	health -= amount
	if health <= 0:
		die()
	elif state_machine and not is_dead:
		# Transition to hurt state when damaged (if not dead)
		state_machine.change_state("hurt")
		# Become fully alert when hit
		awareness_level = 2.0
		if target:
			last_known_player_position = target.global_position

func die():
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	if state_machine:
		state_machine.set_physics_process(false)
		state_machine.set_process(false)
	if animated_sprite:
		if not animated_sprite.animation_finished.is_connected(_on_dead_animation_finished):
			animated_sprite.animation_finished.connect(_on_dead_animation_finished)
		animated_sprite.play("dead")
		# Fallback: remove after delay in case animation_finished doesn't fire
		# Enemy2 has 21 frames @ 15 FPS = 1.4s
		_dead_remove_timer = get_tree().create_timer(1.5)
		_dead_remove_timer.timeout.connect(_on_dead_remove_timeout)
	else:
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
	"""Handle stomp and contact damage."""
	if not target:
		return
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if not collider or not collider.is_in_group("player"):
			continue
		if _is_stomp(collider):
			stomp_kill()
			return
		# Side contact: deal contact damage with knockback
		_damage_player()
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
		# Enemy2 has 21 frames @ 15 FPS = 1.4s
		_dead_remove_timer = get_tree().create_timer(1.5)
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

# ============================================
# VISION SYSTEM
# ============================================

func can_see_player() -> bool:
	"""Check if player is within direct vision cone and not blocked by walls."""
	if not target:
		return false
	var to_player = target.global_position - global_position
	var distance = to_player.length()
	# Apply personality: cautious enemies have shorter vision
	var effective_range = vision_range * (1.0 - caution * 0.3)
	if distance > effective_range:
		return false
	# Check if player is within vision cone (based on facing direction)
	var facing = Vector2(walk_direction, 0)
	var angle_to_player = rad_to_deg(facing.angle_to(to_player))
	if abs(angle_to_player) > vision_angle:
		return false
	# Raycast to check for walls blocking line of sight
	return _raycast_to_player()

func can_see_player_peripheral() -> bool:
	"""Check if player is in peripheral vision (wider angle, shorter range)."""
	if not target:
		return false
	var to_player = target.global_position - global_position
	var distance = to_player.length()
	if distance > peripheral_range:
		return false
	# Peripheral vision is wider but doesn't include direct cone
	var facing = Vector2(walk_direction, 0)
	var angle_to_player = rad_to_deg(facing.angle_to(to_player))
	# Must be outside direct vision but within peripheral angle
	if abs(angle_to_player) <= vision_angle:
		return false  # Already in direct vision
	if abs(angle_to_player) > peripheral_angle:
		return false
	return _raycast_to_player()

func _raycast_to_player() -> bool:
	"""Raycast to check if there's a clear line of sight to player (no walls)."""
	if not target:
		return false
	var space = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position + Vector2(0, -4),  # Start from enemy's eye level
		target.global_position + Vector2(0, -4)  # Aim at player's center
	)
	query.exclude = [get_rid()]
	query.collision_mask = 1  # Only check terrain layer
	var result = space.intersect_ray(query)
	# Clear if nothing hit, or if we hit the player directly
	return result.is_empty() or (result.collider and result.collider.is_in_group("player"))

func update_awareness(delta: float) -> void:
	"""Update awareness level based on player visibility."""
	_can_currently_see_player = can_see_player()
	
	if _can_currently_see_player:
		# Direct sight: rapid awareness buildup
		awareness_level += suspicion_buildup_rate * 2.0 * delta
		last_known_player_position = target.global_position
		time_since_player_seen = 0.0
	elif can_see_player_peripheral():
		# Peripheral sight: slower buildup
		awareness_level += suspicion_buildup_rate * delta
		time_since_player_seen += delta
	else:
		# No sight: awareness decays
		# Apply personality: persistent enemies decay slower
		var effective_decay = suspicion_decay_rate * (1.0 - persistence * 0.5)
		awareness_level -= effective_decay * delta
		time_since_player_seen += delta
	
	awareness_level = clamp(awareness_level, 0.0, 2.0)  # Cap at 2.0 (hyper-alert)

func is_player_on_same_level() -> bool:
	"""True if the player is on the same platform: on the floor (not climbing/jumping) and within vertical threshold."""
	if not target:
		return false
	# Ignore player when they're on a ladder or in the air - don't trigger attack until they're on the platform
	if not target.is_on_floor():
		return false
	var dy = abs(target.global_position.y - global_position.y)
	return dy <= same_level_y_threshold

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

func is_near_ladder() -> bool:
	"""Check if the enemy is standing on or very close to a ladder tile."""
	var feet_pos = global_position + Vector2(0, edge_check_feet_offset)
	# Check current position
	var atlas_at = get_tile_atlas_at_position(feet_pos)
	if atlas_at in PASSTHROUGH_TILES:
		return true
	# Check slightly left and right (in case we're at the edge of a ladder)
	var atlas_left = get_tile_atlas_at_position(feet_pos + Vector2(-tile_size, 0))
	if atlas_left in PASSTHROUGH_TILES:
		return true
	var atlas_right = get_tile_atlas_at_position(feet_pos + Vector2(tile_size, 0))
	if atlas_right in PASSTHROUGH_TILES:
		return true
	# Check below (ladder might be below feet level)
	var atlas_below = get_tile_atlas_at_position(feet_pos + Vector2(0, tile_size))
	if atlas_below in PASSTHROUGH_TILES:
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
	
	# If raycast found floor, there's floor ahead
	if not result.is_empty():
		return false
	
	# No physical floor detected - but check if there's a ladder tile ahead
	# Ladders have no collision but enemies should walk over them
	var ahead_pos = global_position + Vector2(check_x, edge_check_feet_offset)
	var atlas_ahead = get_tile_atlas_at_position(ahead_pos)
	if atlas_ahead in PASSTHROUGH_TILES:
		# There's a ladder here - treat as valid floor, don't turn around
		return false
	
	# Also check slightly below (ladder might be below our feet level)
	var below_pos = ahead_pos + Vector2(0, tile_size)
	var atlas_below = get_tile_atlas_at_position(below_pos)
	if atlas_below in PASSTHROUGH_TILES:
		return false
	
	# No floor and no ladder - turn around
	return true

func is_wall_ignorable() -> bool:
	"""True if we're touching a wall and every collision is player, collectible, or passthrough tile (don't turn)."""
	if not is_on_wall():
		return false
	var tilemap = get_tilemap()
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if not collider:
			return false
		if collider.is_in_group("player"):
			continue
		if collider.is_in_group("collectible"):
			continue
		# Tilemap: if we hit a ladder/passthrough tile (e.g. (5,3)), walk through it
		if tilemap and collider == tilemap:
			var hit_pos = col.get_position()
			var atlas = get_tile_atlas_at_position(hit_pos)
			if atlas in PASSTHROUGH_TILES:
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
	"""Debug drawing for AI behavior, vision cones, and detection ranges"""
	if not debug_draw_ai and not debug_draw_detection:
		return
	
	if debug_draw_detection:
		# Draw vision cone (direct vision)
		var facing_angle = 0.0 if walk_direction > 0 else PI
		var vision_color = Color(0.2, 1.0, 0.3, 0.3) if _can_currently_see_player else Color(0.5, 0.5, 0.5, 0.2)
		_draw_vision_cone(vision_range, vision_angle, facing_angle, vision_color)
		
		# Draw peripheral vision cone
		var peripheral_color = Color(1.0, 1.0, 0.3, 0.15)
		_draw_vision_cone(peripheral_range, peripheral_angle, facing_angle, peripheral_color)
		
		# Draw attack range
		draw_arc(Vector2.ZERO, attack_range, 0, TAU, 16, Color(1.0, 0.3, 0.3, 0.5), 2.0)
		
		# Draw awareness indicator (vertical bar)
		var bar_height = awareness_level * 20.0
		var bar_color = Color(1.0, 1.0 - awareness_level * 0.5, 0.0, 0.8)
		draw_rect(Rect2(Vector2(-2, -20 - bar_height), Vector2(4, bar_height)), bar_color)
	
	if debug_draw_ai:
		# Draw line to target (green if can see, red if blocked)
		if target:
			var target_pos = target.global_position - global_position
			var line_color = Color(0.2, 1.0, 0.3, 1.0) if _can_currently_see_player else Color(1.0, 0.3, 0.3, 0.5)
			draw_line(Vector2.ZERO, target_pos, line_color, 2.0)
		
		# Draw last known position marker
		if last_known_player_position != Vector2.ZERO and not _can_currently_see_player:
			var last_pos = last_known_player_position - global_position
			draw_circle(last_pos, 4.0, Color(1.0, 0.5, 0.0, 0.6))

func _draw_vision_cone(cone_range: float, cone_angle: float, facing_angle: float, color: Color) -> void:
	"""Draw a vision cone for debug visualization."""
	var angle_rad = deg_to_rad(cone_angle)
	var start_angle = facing_angle - angle_rad
	var end_angle = facing_angle + angle_rad
	var points = PackedVector2Array()
	points.append(Vector2.ZERO)
	var segments = 16
	for i in range(segments + 1):
		var angle = start_angle + (end_angle - start_angle) * (float(i) / segments)
		points.append(Vector2(cos(angle), sin(angle)) * cone_range)
	points.append(Vector2.ZERO)
	draw_colored_polygon(points, color)
