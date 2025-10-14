class_name PlayerIdleState
extends State

# Idle state - player is standing still, can transition to other states

func enter():
	"""Called when entering idle state"""
	# Reset any movement-related variables
	if entity.has_method("set_velocity_x"):
		entity.set_velocity_x(0.0)

func update(_delta: float):
	"""Update idle state logic"""
	# Handle blinking logic here if needed
	pass

func physics_update(delta: float):
	"""Physics update for idle state"""
	# Apply friction to stop horizontal movement
	if entity.has_method("get_velocity"):
		var velocity = entity.get_velocity()
		velocity.x = move_toward(velocity.x, 0, entity.friction * delta)
		entity.set_velocity(velocity)

func handle_input(_event: InputEvent):
	"""Handle input while in idle state"""
	# Check for state transitions
	if entity.movement_component.wants_to_jump() and entity.is_on_floor():
		state_machine.change_state("Jump")
		return
	
	if entity.movement_component.wants_to_crouch():
		state_machine.change_state("Crouch")
		return
	
	if entity.movement_component.wants_to_climb() and entity.should_be_climbing():
		state_machine.change_state("Climb")
		return
	
	if abs(entity.movement_component.get_movement_direction()) > 0:
		state_machine.change_state("Walk")
		return
