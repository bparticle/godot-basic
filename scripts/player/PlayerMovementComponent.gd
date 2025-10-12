class_name PlayerMovementComponent
extends MovementComponent

# Player-specific movement component that wraps input handling
# Implements the interface for player input

func get_movement_direction() -> float:
	return Input.get_axis("ui_left", "ui_right")

func wants_to_jump() -> bool:
	return Input.is_action_just_pressed("ui_up")

func wants_to_crouch() -> bool:
	return Input.is_action_pressed("ui_down")

func wants_to_climb() -> bool:
	return Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down")
