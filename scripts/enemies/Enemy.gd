class_name Enemy
extends CharacterBody2D

# Simple enemy with state machine AI
# Follows the tutorial pattern for enemy AI

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

@export_group("Enemy Stats")
@export var speed: float = 30.0
@export var detection_range: float = 100.0
@export var attack_range: float = 20.0
@export var attack_damage: int = 1
@export var max_health: int = 3
@export var enemy_color: Color = Color(0.176471, 0.996078, 0.223529, 1)

@export_group("AI Behavior")
@export var chase_speed_multiplier: float = 1.5
@export var idle_wait_time: float = 2.0
@export var attack_cooldown: float = 1.0

@export_group("Visual Settings")
@export var debug_draw_ai: bool = false
@export var debug_draw_detection: bool = false

@onready var animated_sprite = $AnimatedSprite2D
@onready var state_machine = $StateMachine
@onready var movement_component = $MovementComponent

var target: CharacterBody2D
var health: int
var is_dead: bool = false

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
	
	# Initialize health
	health = max_health
	
	# Apply visual settings
	if animated_sprite:
		animated_sprite.modulate = enemy_color
	
	# Find player target
	target = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float):
	if is_dead:
		return
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	
	move_and_slide()

func take_damage(amount: int):
	health -= amount
	if health <= 0:
		die()

func die():
	is_dead = true
	# Play death animation or remove from scene
	queue_free()

func get_distance_to_target() -> float:
	if not target:
		return 999.0
	return global_position.distance_to(target.global_position)

func get_direction_to_target() -> Vector2:
	if not target:
		return Vector2.ZERO
	return (target.global_position - global_position).normalized()

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
