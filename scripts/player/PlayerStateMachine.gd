class_name PlayerStateMachine
extends StateMachine

# Player state machine - manages player movement states
# This replaces the complex state management in the original Player.gd

var parent: CharacterBody2D
var animated_sprite: AnimatedSprite2D
var movement_component: MovementComponent

# Platformer improvement timers
var jump_buffer_timer: float = 0.0
var coyote_timer: float = 0.0
var was_on_floor: bool = false

func _ready():
	parent = get_parent()
	animated_sprite = parent.get_node("AnimatedSprite2D")
	movement_component = parent.get_node("MovementComponent")
	
	# Set initial state
	change_state("idle")

func _physics_process(delta: float):
	# Update platformer improvement timers
	update_platformer_timers(delta)
	
	# Handle jump buffering
	handle_jump_buffering()
	
	# Call parent physics process
	super._physics_process(delta)

func update_platformer_timers(delta: float):
	"""Update jump buffering and coyote time timers"""
	# Update jump buffer timer
	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta
	
	# Update coyote timer
	if parent.is_on_floor():
		coyote_timer = parent.coyote_time
	else:
		coyote_timer = max(0.0, coyote_timer - delta)
	
	# Reset jump phase when coyote time expires and we're not actually jumping
	# This fixes the issue where jump animation gets stuck after coyote time
	if coyote_timer <= 0.0 and parent.jump_phase != parent.JumpPhase.NONE and not parent.is_on_floor() and parent.velocity.y >= 0:
		# Only reset if we're not in a proper jump (velocity.y >= 0 means we're falling, not jumping up)
		# and we're not in the middle of a legitimate jump sequence
		if parent.jump_phase == parent.JumpPhase.UP or parent.jump_phase == parent.JumpPhase.PEAK:
			parent.jump_phase = parent.JumpPhase.NONE
	
	# Track floor state for next frame
	was_on_floor = parent.is_on_floor()

func handle_jump_buffering():
	"""Handle jump input buffering"""
	if not movement_component:
		return
	
	# Check for jump input and buffer it
	if movement_component.wants_to_jump():
		jump_buffer_timer = parent.jump_buffer_time
	
	# Try to consume buffered jump
	if jump_buffer_timer > 0.0:
		# Can jump if on floor or in coyote time, and not crouching/climbing
		if (parent.is_on_floor() or coyote_timer > 0.0) and not parent.is_crouching and not parent.is_climbing:
			# Transition to jump state
			change_state("jump")
			jump_buffer_timer = 0.0
			coyote_timer = 0.0

func get_current_animation() -> String:
	"""Get the current animation based on state"""
	match get_current_state_name():
		"idle":
			return "idle"
		"walk":
			return "walk"
		"jump":
			return "jump"
		"crouch":
			return "crouch"
		"climb":
			return "climb"
		_:
			return "idle"
