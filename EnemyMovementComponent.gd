class_name EnemyMovementComponent
extends MovementComponent

# Enemy movement component that provides AI-based movement decisions

var parent: Enemy

func _ready():
	parent = get_parent()

func get_movement_direction() -> float:
	if not parent or parent.is_dead:
		return 0.0
	
	# Get direction to target
	var direction = parent.get_direction_to_target()
	return direction.x

func wants_to_jump() -> bool:
	# Enemies don't jump in this simple implementation
	return false

func wants_to_crouch() -> bool:
	# Enemies don't crouch in this simple implementation
	return false

func wants_to_climb() -> bool:
	# Enemies don't climb in this simple implementation
	return false
