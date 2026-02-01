class_name State
extends Node

# Base state class for the state machine pattern
# All states inherit from this class

# Reference to the state machine that owns this state
var state_machine: StateMachine
# Reference to the entity this state belongs to
var entity: Node

func _ready():
	# Get references to parent state machine and entity
	state_machine = get_parent()
	if state_machine:
		entity = state_machine.get_parent()

# Called when entering this state
func enter() -> void:
	pass

# Called when exiting this state
func exit() -> void:
	pass

# Called every frame while in this state
func update(_delta: float) -> void:
	pass

# Called every physics frame while in this state
func physics_update(_delta: float) -> void:
	pass

# Called when input is received while in this state
func handle_input(_event: InputEvent) -> void:
	pass

# Helper to request a state transition via the state machine
func transition_to(state_name: String) -> void:
	if not state_machine:
		push_error("StateMachine not set for state: " + name)
		return
	state_machine.change_state(state_name)