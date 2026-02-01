class_name StateMachine
extends Node

# State machine manager for handling state transitions
# Follows the Godot 4 state machine pattern

# Current active state
var current_state: State
# Dictionary of all available states
var states: Dictionary = {}

# Reference to the entity this state machine belongs to
var entity: Node

func _ready():
	entity = get_parent()
	# Initialize all child states
	_initialize_states()

func _initialize_states():
	"""Initialize all child states and store them in the states dictionary"""
	for child in get_children():
		if child is State:
			var state = child as State
			states[state.name] = state
			state.state_machine = self

func change_state(state_name: String) -> void:
	"""Change to a new state by name"""
	if not states.has(state_name):
		push_error("State '" + state_name + "' not found in state machine")
		return
	
	var new_state = states[state_name]
	
	# Exit current state
	if current_state:
		current_state.exit()
	
	# Enter new state
	current_state = new_state
	current_state.enter()

func _process(delta: float):
	"""Update current state"""
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float):
	"""Physics update current state"""
	if current_state:
		current_state.physics_update(delta)

func _unhandled_input(event: InputEvent):
	"""Handle input for current state"""
	if current_state:
		current_state.handle_input(event)

func get_current_state_name() -> String:
	if current_state:
		return current_state.name
	return ""