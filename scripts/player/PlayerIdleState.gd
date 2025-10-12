class_name PlayerIdleState
extends State

# Player idle state - handles standing still, blinking, and transitions

var parent: CharacterBody2D
var animated_sprite: AnimatedSprite2D
var movement_component: MovementComponent

# Blinking state variables
var idle_timer: float = 0.0
var blink_timer: float = 0.0
var is_blinking: bool = false
var last_blink_time: float = 0.0
var blink_interval_min: float = 2.0
var blink_interval_max: float = 5.0
var blink_duration: float = 0.33
var idle_animation_timer: float = 0.0
var use_mirrored_idle: bool = false
var mirrored_idle_timer: float = 0.0
var mirrored_idle_duration: float = 3.0

func enter():
	parent = get_parent().get_parent()  # StateMachine -> Player
	animated_sprite = parent.get_node("AnimatedSprite2D")
	movement_component = parent.get_node("MovementComponent")

func update(delta: float):
	handle_blinking(delta)
	check_transitions()

func physics_update(delta: float):
	# Stop horizontal movement
	parent.velocity.x = move_toward(parent.velocity.x, 0, parent.FRICTION * delta)

func handle_blinking(delta: float):
	# Only blink when idle and not moving
	var is_idle = parent.is_on_floor() and abs(parent.velocity.x) <= 5 and not parent.is_crouching and not parent.is_climbing
	
	if is_idle:
		idle_timer += delta
		idle_animation_timer += delta
		
		# Handle mirrored idle timer
		if use_mirrored_idle:
			mirrored_idle_timer += delta
			if mirrored_idle_timer >= mirrored_idle_duration:
				use_mirrored_idle = false
				mirrored_idle_timer = 0.0
		
		# Check if we should start blinking
		if not is_blinking and idle_timer > 1.0:
			var time_since_last_blink = idle_timer - last_blink_time
			var should_blink = time_since_last_blink > randf_range(blink_interval_min, blink_interval_max)
			
			if should_blink:
				# Sync the blink with the idle animation cycle
				var idle_cycle_duration = 0.5
				var cycle_progress = fmod(idle_animation_timer, idle_cycle_duration)
				var time_to_next_cycle = idle_cycle_duration - cycle_progress
				if time_to_next_cycle < 0.1:
					is_blinking = true
					blink_timer = 0.0
					last_blink_time = idle_timer
					idle_animation_timer = 0.0
	else:
		# Reset timers when not idle
		idle_timer = 0.0
		is_blinking = false
		blink_timer = 0.0
		idle_animation_timer = 0.0
		use_mirrored_idle = false
		mirrored_idle_timer = 0.0
	
	# Handle blink animation duration
	if is_blinking:
		blink_timer += delta
		if blink_timer >= blink_duration:
			is_blinking = false
			blink_timer = 0.0
			use_mirrored_idle = true

func check_transitions():
	if not movement_component:
		return
	
	# Check for movement
	if abs(movement_component.get_movement_direction()) > 0:
		transition_to("walk")
		return
	
	# Check for jump
	if movement_component.wants_to_jump() and parent.is_on_floor():
		transition_to("jump")
		return
	
	# Check for crouch
	if movement_component.wants_to_crouch():
		transition_to("crouch")
		return
	
	# Check for climb
	if movement_component.wants_to_climb() and parent.should_be_climbing():
		transition_to("climb")
		return
