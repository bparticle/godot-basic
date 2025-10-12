class_name MovementComponent
extends Node

# Movement component interface for flexible input handling
# Implements the duck typing approach from the tutorial

# Returns the desired horizontal movement direction (-1 to 1)
func get_movement_direction() -> float:
	return 0.0

# Returns true if the character wants to jump
func wants_to_jump() -> bool:
	return false

# Returns true if the character wants to crouch
func wants_to_crouch() -> bool:
	return false

# Returns true if the character wants to climb
func wants_to_climb() -> bool:
	return false
