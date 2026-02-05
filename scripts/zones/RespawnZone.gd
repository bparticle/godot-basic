@tool
extends Area2D

# RespawnZone - Area that causes player to take 1 damage and respawn at a custom position
# 
# USAGE:
# 1. Instance RespawnZone in your level
# 2. In the Inspector, set "Zone Size" to cover the danger area
# 3. Set "Respawn Offset" to where the player should teleport (relative to this node)

## Size of the collision zone. Adjust this in the Inspector.
@export var zone_size: Vector2 = Vector2(64, 32):
	set(value):
		zone_size = value
		_update_collision_shape()

## Where the player respawns, relative to this node's position.
@export var respawn_offset: Vector2 = Vector2(0, -50):
	set(value):
		respawn_offset = value
		_update_marker_position()

## How high above the respawn position to spawn (for spawn animation drop effect)
@export var spawn_elevation: float = 8.0

## Delay before the zone becomes active (prevents triggering on spawn)
@export var activation_delay: float = 0.3

@onready var health_manager = get_node_or_null("/root/HealthManager")
var is_active: bool = false

func _ready():
	_update_collision_shape()
	_update_marker_position()
	
	# Don't run game logic in editor
	if Engine.is_editor_hint():
		return
	
	# Connect signal
	body_entered.connect(_on_body_entered)
	
	# Delay activation
	await get_tree().create_timer(activation_delay).timeout
	is_active = true
	print("[RespawnZone] Now active at ", global_position)

func _update_collision_shape():
	var shape_node = get_node_or_null("CollisionShape2D")
	if not shape_node:
		return
	
	# Always create a unique shape for this instance
	if shape_node.shape == null or not (shape_node.shape is RectangleShape2D):
		shape_node.shape = RectangleShape2D.new()
	elif not shape_node.shape.resource_local_to_scene:
		# Make sure we have our own copy
		shape_node.shape = shape_node.shape.duplicate()
	
	shape_node.shape.size = zone_size

func _update_marker_position():
	var marker = get_node_or_null("RespawnMarker")
	if marker:
		marker.position = respawn_offset

func _on_body_entered(body):
	print("[RespawnZone] Body entered: ", body.name, " is_active=", is_active)
	
	if not is_active:
		return
	
	if not body.is_in_group("player"):
		return
	
	# Check if player is invulnerable - skip damage but STILL teleport
	var is_invulnerable = body.has_method("get_damage_immunity_remaining_ms") and body.get_damage_immunity_remaining_ms() > 0
	
	if is_invulnerable:
		print("[RespawnZone] Player invulnerable, teleporting without damage")
	else:
		print("[RespawnZone] Triggering respawn with damage!")
		# Deal 1 damage only if not invulnerable
		if health_manager:
			health_manager.take_damage(1)
	
	# Teleport player to safety - elevated above respawn position for spawn animation
	var target_pos = global_position + respawn_offset - Vector2(0, spawn_elevation)
	body.global_position = target_pos
	body.velocity = Vector2.ZERO
	
	# Trigger spawn animation and grant invulnerability
	if body.has_method("reset_death_state"):
		body.reset_death_state(true) # true = play spawn animation
