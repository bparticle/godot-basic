class_name PlayerJumpState
extends State

# Jump state - player is jumping with phase tracking

func enter():
	"""Called when entering jump state"""
	# Initialize jump
	entity.jump_phase = entity.JumpPhase.UP
	entity.do_jump()

func update(_delta: float):
	"""Update jump state logic"""
	# Handle jump phase transitions
	entity.handle_jump_phases()

func physics_update(delta: float):
	"""Physics update for jump state"""
	# Apply gravity with platformer improvements
	entity.apply_gravity(delta)
	
	# Handle horizontal movement while jumping
	var direction = entity.movement_component.get_movement_direction()
	if direction != 0:
		var velocity = entity.get_velocity()
		velocity.x = move_toward(velocity.x, direction * entity.speed, entity.acceleration * delta)
		entity.set_velocity(velocity)

func handle_input(_event: InputEvent):
	"""Handle input while in jump state"""
	# Check for state transitions
	if entity.movement_component.wants_to_climb() and entity.should_be_climbing():
		state_machine.change_state("Climb")
		return

func exit():
	"""Called when exiting jump state"""
	# Reset jump phase when leaving jump state
	entity.jump_phase = entity.JumpPhase.NONE
