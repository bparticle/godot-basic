class_name PlayerJumpState
extends State

# Player jump state - handles jumping and jump phases

var parent: CharacterBody2D
var animated_sprite: AnimatedSprite2D
var movement_component: MovementComponent

# Jump phase tracking
var jump_phase: String = "none"  # none, up, peak, down, land
var jump_land_timer: float = 0.0
var jump_land_duration: float = 0.25
var last_velocity_y: float = 0.0
var jump_stuck_timer: float = 0.0

func enter():
	parent = get_parent().get_parent()  # StateMachine -> Player
	animated_sprite = parent.get_node("AnimatedSprite2D")
	movement_component = parent.get_node("MovementComponent")
	
	# Start jump
	jump_phase = "up"
	parent.velocity.y = parent.JUMP_VELOCITY * parent.jump_power

func update(delta: float):
	handle_jump_phases(delta)
	check_transitions()

func physics_update(delta: float):
	# Apply gravity
	if not parent.is_on_floor():
		var gravity_scale = 1.0
		
		# Higher gravity when falling
		if parent.velocity.y > 0.0:
			gravity_scale = parent.fall_gravity_scale
		# Variable jump height - cut jump if releasing early
		elif not Input.is_action_pressed("ui_up") and parent.velocity.y < 0.0:
			gravity_scale = parent.low_jump_gravity_scale
		
		parent.velocity.y += parent.gravity * gravity_scale * delta
	
	# Handle horizontal movement while jumping
	if movement_component:
		var direction = movement_component.get_movement_direction()
		if direction != 0:
			parent.velocity.x = move_toward(parent.velocity.x, direction * parent.SPEED, parent.ACCELERATION * delta)

func handle_jump_phases(delta: float):
	"""Handle jump phase transitions for animation"""
	# Check for jump interruption conditions first
	check_jump_interruption()
	
	# Handle jump phase transitions based on velocity
	if not parent.is_on_floor() and jump_phase != "land":
		# Detect jump peak (velocity changes from negative to positive)
		if last_velocity_y < 0 and parent.velocity.y >= 0 and jump_phase == "up":
			jump_phase = "peak"
		# Detect going down (velocity is positive)
		elif parent.velocity.y > 0 and jump_phase == "peak":
			jump_phase = "down"
	
	# Handle landing phase
	if parent.is_on_floor() and jump_phase != "none":
		jump_phase = "land"
		jump_land_timer = 0.0
	
	# Handle landing animation duration
	if jump_phase == "land":
		jump_land_timer += delta
		if jump_land_timer >= jump_land_duration:
			jump_phase = "none"
	
	# Store current velocity for next frame
	last_velocity_y = parent.velocity.y

func check_jump_interruption():
	"""Check for conditions that should interrupt/reset the jump phase"""
	# Reset jump phase if we're climbing (ladder takes priority)
	if parent.is_climbing and jump_phase != "none":
		jump_phase = "none"
		return
	
	# Reset jump phase if we're forced to crouch due to ceiling
	if parent.forced_crouch and jump_phase != "none":
		jump_phase = "none"
		return
	
	# Check for ceiling collision during jump
	if jump_phase in ["up", "peak"] and parent.velocity.y >= 0 and last_velocity_y < -50:
		# Player hit ceiling during jump, try ledge push-around
		parent.handle_ledge_push_around()
		jump_phase = "down"
		return

func check_transitions():
	if not movement_component:
		return
	
	# Check for climb (can climb while jumping)
	if movement_component.wants_to_climb() and parent.should_be_climbing():
		transition_to("climb")
		return
	
	# Check for crouch (only when on floor)
	if movement_component.wants_to_crouch() and parent.is_on_floor():
		transition_to("crouch")
		return
	
	# Transition to idle when landing and no movement
	if parent.is_on_floor() and jump_phase == "none":
		if abs(movement_component.get_movement_direction()) == 0:
			transition_to("idle")
		else:
			transition_to("walk")
		return
