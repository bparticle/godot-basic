class_name Enemy
extends CharacterBody2D

# Simple enemy with state machine AI
# Follows the tutorial pattern for enemy AI

@export var speed: float = 30.0
@export var detection_range: float = 100.0
@export var attack_range: float = 20.0
@export var attack_damage: int = 1

@onready var animated_sprite = $AnimatedSprite2D
@onready var state_machine = $StateMachine
@onready var movement_component = $MovementComponent

var target: CharacterBody2D
var health: int = 3
var is_dead: bool = false

func _ready():
	# Add to enemy group
	add_to_group("enemies")
	
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
