class_name PlayerClimbState
extends State

# Climb state - player is climbing a ladder

func enter():
	"""Called when entering climb state"""
	entity.is_climbing = true
	entity.is_crouching = false  # Can't crouch while climbing

func update(_delta: float):
	"""Update climb state logic"""
	# Handle climb animation
	entity.handle_climb_animation()

func physics_update(delta: float):
	"""Physics update for climb state"""
	# Stop gravity while climbing
	var velocity = entity.get_velocity()
	velocity.y = 0
	
	# Handle vertical movement on ladder
	var vertical_input = 0.0
	if entity.movement_component.wants_to_climb():
		if Input.is_action_pressed("ui_up"):
			vertical_input = -1.0
		elif Input.is_action_pressed("ui_down"):
			vertical_input = 1.0
	
	velocity.y = vertical_input * entity.climb_speed
	
	# Handle horizontal movement while climbing
	var horizontal_input = entity.movement_component.get_movement_direction()
	if abs(horizontal_input) > 0:
		# Pressing left or right makes you fall off the ladder
		state_machine.change_state("Jump")
		# Give a small horizontal push in the direction pressed
		velocity.x = horizontal_input * 50.0
		velocity.y = 0
		entity.set_velocity(velocity)
		return
	else:
		# Apply gentle ladder centering when no horizontal input
		entity.apply_ladder_centering(delta)
	
	entity.set_velocity(velocity)

func handle_input(_event: InputEvent):
	"""Handle input while in climb state"""
	# Check for state transitions
	if entity.movement_component.wants_to_jump():
		# Jump off ladder
		state_machine.change_state("Jump")
		return

func exit():
	"""Called when exiting climb state"""
	entity.is_climbing = false
