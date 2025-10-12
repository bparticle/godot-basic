class_name DoorStateMachine
extends StateMachine

# Door state machine - manages door states (closed, opening, open, closing)

@export var open_duration: float = 2.0
@export var close_duration: float = 1.0

var door: Area2D
var animated_sprite: AnimatedSprite2D

func _ready():
	door = get_parent()
	animated_sprite = door.get_node("AnimatedSprite2D")
	
	# Set initial state
	change_state("closed")

func open_door():
	"""Public method to open the door"""
	if get_current_state_name() == "closed":
		change_state("opening")

func close_door():
	"""Public method to close the door"""
	if get_current_state_name() == "open":
		change_state("closing")

func is_open() -> bool:
	return get_current_state_name() == "open"

func is_closed() -> bool:
	return get_current_state_name() == "closed"
