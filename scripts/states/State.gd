class_name State
extends Node

# Base state class for all states in the state machine
# Follows the tutorial pattern with enter, exit, update, and physics_update

signal transition_requested(state_name: String)

# Called when entering this state
func enter() -> void:
	pass

# Called when exiting this state
func exit() -> void:
	pass

# Called every frame (tied to visual frame rate)
func update(delta: float) -> void:
	pass

# Called every physics frame (tied to physics server)
func physics_update(delta: float) -> void:
	pass

# Helper method to request state transition
func transition_to(state_name: String) -> void:
	transition_requested.emit(state_name)
