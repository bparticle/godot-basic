class_name PlayerWalkState
extends State

# Walk state - player is moving horizontally

func enter():
	"""Called when entering walk state"""
	pass

func update(_delta: float):
	"""Update walk state logic"""
	pass

func physics_update(delta: float):
	"""Physics update for walk state"""
	var direction = entity.movement_component.get_movement_direction()
	var current_speed = entity.crouch_speed if entity.is_crouching else entity.speed
	
	# Handle horizontal movement
	if direction != 0:
		var target_velocity = direction * current_speed
		var velocity = entity.get_velocity()
		velocity.x = move_toward(velocity.x, target_velocity, entity.acceleration * delta)
		entity.set_velocity(velocity)
	else:
		# Apply friction when no input
		var velocity = entity.get_velocity()
		velocity.x = move_toward(velocity.x, 0, entity.friction * delta)
		entity.set_velocity(velocity)

func handle_input(_event: InputEvent):
	"""Handle input while in walk state"""
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
	
	# Transition to idle if no movement input
	if abs(entity.movement_component.get_movement_direction()) == 0:
		state_machine.change_state("Idle")
		return
