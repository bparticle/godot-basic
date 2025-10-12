class_name PlayerCrouchState
extends State

# Player crouch state - handles crouching movement

var parent: CharacterBody2D
var animated_sprite: AnimatedSprite2D
var movement_component: MovementComponent

func enter():
	parent = get_parent().get_parent()  # StateMachine -> Player
	animated_sprite = parent.get_node("AnimatedSprite2D")
	movement_component = parent.get_node("MovementComponent")
	
	# Set crouching state
	parent.is_crouching = true

func exit():
	# Only exit crouch if not forced
	if not parent.forced_crouch:
		parent.is_crouching = false

func update(delta: float):
	# Handle sprite flipping
	if parent.velocity.x < 0:
		animated_sprite.flip_h = true
	elif parent.velocity.x > 0:
		animated_sprite.flip_h = false

func physics_update(delta: float):
	if not movement_component:
		return
	
	var direction = movement_component.get_movement_direction()
	
	# Handle horizontal movement (slower when crouching)
	if direction != 0:
		parent.velocity.x = move_toward(parent.velocity.x, direction * parent.CROUCH_SPEED, parent.ACCELERATION * delta)
	else:
		parent.velocity.x = move_toward(parent.velocity.x, 0, parent.FRICTION * delta)

func check_transitions():
	if not movement_component:
		return
	
	# Check for jump (can't jump while crouching)
	if movement_component.wants_to_jump() and parent.is_on_floor():
		# Can't jump while crouching
		pass
	
	# Check for climb
	if movement_component.wants_to_climb() and parent.should_be_climbing():
		transition_to("climb")
		return
	
	# Check for standing up (only if not forced to crouch)
	if not movement_component.wants_to_crouch() and not parent.forced_crouch:
		# Check if there's enough ceiling clearance
		if parent.check_ceiling_clearance_for_full_height():
			transition_to("idle")
			return
	
	# Check for movement while crouching
	if abs(movement_component.get_movement_direction()) > 0:
		# Stay in crouch but allow movement
		pass
	elif abs(movement_component.get_movement_direction()) == 0 and abs(parent.velocity.x) <= 5:
		# Idle crouch
		pass
