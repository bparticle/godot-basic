class_name PlayerWalkState
extends State

# Player walking state - handles horizontal movement

var parent: CharacterBody2D
var animated_sprite: AnimatedSprite2D
var movement_component: MovementComponent

func enter():
	parent = get_parent().get_parent()  # StateMachine -> Player
	animated_sprite = parent.get_node("AnimatedSprite2D")
	movement_component = parent.get_node("MovementComponent")

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
	
	# Handle horizontal movement
	if direction != 0:
		parent.velocity.x = move_toward(parent.velocity.x, direction * parent.SPEED, parent.ACCELERATION * delta)
	else:
		parent.velocity.x = move_toward(parent.velocity.x, 0, parent.FRICTION * delta)

func check_transitions():
	if not movement_component:
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
	
	# Check for idle (no movement input)
	if abs(movement_component.get_movement_direction()) == 0 and abs(parent.velocity.x) <= 5:
		transition_to("idle")
		return
