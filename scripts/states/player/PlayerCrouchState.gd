class_name PlayerCrouchState
extends State

# Crouch state - player is crouching

func enter():
	"""Called when entering crouch state"""
	entity.is_crouching = true

func update(_delta: float):
	"""Update crouch state logic"""
	pass

func physics_update(delta: float):
	"""Physics update for crouch state"""
	var direction = entity.movement_component.get_movement_direction()
	
	# Handle horizontal movement while crouching (slower)
	if direction != 0:
		var velocity = entity.get_velocity()
		velocity.x = move_toward(velocity.x, direction * entity.crouch_speed, entity.acceleration * delta)
		entity.set_velocity(velocity)
	else:
		# Apply friction when no input
		var velocity = entity.get_velocity()
		velocity.x = move_toward(velocity.x, 0, entity.friction * delta)
		entity.set_velocity(velocity)

func handle_input(_event: InputEvent):
	"""Handle input while in crouch state"""
	# Check for state transitions
	if entity.movement_component.wants_to_jump() and entity.is_on_floor():
		state_machine.change_state("Jump")
		return
	
	if entity.movement_component.wants_to_climb() and entity.should_be_climbing():
		state_machine.change_state("Climb")
		return
	
	# Transition to idle if no crouch input and no movement
	if not entity.movement_component.wants_to_crouch() and abs(entity.movement_component.get_movement_direction()) == 0:
		state_machine.change_state("Idle")
		return
	
	# Transition to walk if no crouch input but there's movement
	if not entity.movement_component.wants_to_crouch() and abs(entity.movement_component.get_movement_direction()) > 0:
		state_machine.change_state("Walk")
		return

func exit():
	"""Called when exiting crouch state"""
	entity.is_crouching = false
