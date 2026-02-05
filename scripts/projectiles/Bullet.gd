extends Area2D
class_name Bullet

# Bullet - Projectile fired by the player's gun
# Features:
# - Constant velocity movement
# - Collision detection with enemies
# - Auto-destroy on hit or after max lifetime
# - Visual feedback (green pixel)

## Speed of the bullet in pixels per second
@export var speed: float = 200.0

## Maximum lifetime in seconds before auto-destroy
@export var max_lifetime: float = 2.0

## Damage dealt to enemies
@export var damage: int = 1

## Direction of travel (-1 = left, 1 = right)
var direction: int = 1

## Timer tracking bullet lifetime
var lifetime: float = 0.0

## Reference to effects manager for impact effects
var effects_manager: Node

func _ready():
	# Connect collision signal
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Get effects manager for impact effects
	effects_manager = get_node_or_null("/root/EffectsManager")
	
	# Add to bullets group for easy management
	add_to_group("bullets")

func _physics_process(delta: float):
	# Move bullet
	position.x += direction * speed * delta
	
	# Track lifetime and destroy if exceeded
	lifetime += delta
	if lifetime >= max_lifetime:
		queue_free()

func _on_body_entered(body: Node2D):
	# Check if we hit an enemy
	if body.is_in_group("enemies"):
		_hit_enemy(body)
	# Check if we hit a wall/tilemap (layer 1 collision)
	elif body is TileMapLayer or body.collision_layer & 1:
		_hit_wall()

func _on_area_entered(area: Area2D):
	# Can be used for special collision areas if needed
	pass

func _hit_enemy(enemy: Node2D):
	"""Handle hitting an enemy"""
	# Deal damage if enemy has take_damage method
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
	elif enemy.has_method("stomp_kill"):
		# Fallback: use stomp_kill if no take_damage method
		enemy.stomp_kill()
	
	# Impact effect
	if effects_manager:
		effects_manager.impact(0.02, 2.0)  # Brief hit stop and shake
	
	# Destroy bullet
	queue_free()

func _hit_wall():
	"""Handle hitting a wall"""
	# Could spawn particles here in the future
	queue_free()

func initialize(dir: int, start_pos: Vector2):
	"""Initialize bullet with direction and starting position"""
	direction = dir
	global_position = start_pos
	
	# Flip visual if shooting left
	if direction < 0:
		scale.x = -1

func _draw():
	"""Draw a simple green rectangle as the bullet visual"""
	# 3x2 pixel green bullet
	var bullet_color = Color(0.176471, 0.996078, 0.223529, 1)  # Bright green matching player
	draw_rect(Rect2(-1.5, -1, 3, 2), bullet_color)
