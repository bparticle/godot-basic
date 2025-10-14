class_name MovementComponent
extends Node

# Movement component for handling player input
# Provides input state to the state machine

# Input state variables
var movement_direction: float = 0.0
var jump_pressed: bool = false
var jump_just_pressed: bool = false
var crouch_pressed: bool = false
var climb_pressed: bool = false

# Reference to the entity this component belongs to
var entity: Node

func _ready():
	entity = get_parent()

func _process(_delta: float):
	"""Update input state every frame"""
	_update_input_state()

func _update_input_state():
	"""Update all input state variables"""
	# Horizontal movement
	movement_direction = Input.get_axis("ui_left", "ui_right")
	
	# Jump input
	jump_just_pressed = Input.is_action_just_pressed("ui_up")
	jump_pressed = Input.is_action_pressed("ui_up")
	
	# Crouch input
	crouch_pressed = Input.is_action_pressed("ui_down")
	
	# Climb input (up or down while near ladder)
	climb_pressed = Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down")

# Public interface methods for states to query input
func get_movement_direction() -> float:
	return movement_direction

func wants_to_jump() -> bool:
	return jump_just_pressed

func is_jumping() -> bool:
	return jump_pressed

func wants_to_crouch() -> bool:
	return crouch_pressed

func wants_to_climb() -> bool:
	return climb_pressed
