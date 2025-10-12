class_name StateMachine
extends Node

# State machine implementation following tutorial patterns
# Manages state transitions and lifecycle

@export var initial_state: String = ""

var states: Dictionary = {}
var current_state: State

func _ready():
	# Register all child states
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			# Connect transition signal
			child.transition_requested.connect(_on_state_transition_requested)
	
	# Set initial state
	if initial_state != "" and initial_state.to_lower() in states:
		change_state(initial_state.to_lower())

func _process(delta: float):
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float):
	if current_state:
		current_state.physics_update(delta)

func change_state(state_name: String) -> void:
	# Validate state exists
	if not state_name in states:
		push_error("State '%s' not found in state machine" % state_name)
		return
	
	# Exit current state
	if current_state:
		current_state.exit()
	
	# Enter new state
	current_state = states[state_name]
	current_state.enter()

func _on_state_transition_requested(state_name: String) -> void:
	change_state(state_name)

func get_current_state_name() -> String:
	return current_state.name if current_state else ""

func has_state(state_name: String) -> bool:
	return state_name in states
