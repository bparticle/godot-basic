class_name EnemyChaseState
extends State

# Enemy chase state - follows the player

var parent: Enemy
var animated_sprite: AnimatedSprite2D
var movement_component: MovementComponent

func enter():
	parent = get_parent().get_parent()  # StateMachine -> Enemy
	animated_sprite = parent.get_node("AnimatedSprite2D")
	movement_component = parent.get_node("MovementComponent")

func update(delta: float):
	# Handle sprite flipping
	if parent.velocity.x < 0:
		animated_sprite.flip_h = true
	elif parent.velocity.x > 0:
		animated_sprite.flip_h = false

func physics_update(delta: float):
	# Move towards target
	var direction = parent.get_direction_to_target()
	parent.velocity.x = direction.x * parent.speed
	
	# Check for transitions
	check_transitions()

func check_transitions():
	# Check if player is out of detection range
	if parent.get_distance_to_target() > parent.detection_range:
		transition_to("idle")
		return
	
	# Check if player is in attack range
	if parent.get_distance_to_target() <= parent.attack_range:
		transition_to("attack")
		return
