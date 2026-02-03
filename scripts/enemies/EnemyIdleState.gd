class_name EnemyIdleState
extends State

# Enemy idle state - patrols or waits

var parent: Enemy
var animated_sprite: AnimatedSprite2D
var movement_component: MovementComponent

func enter():
	parent = get_parent().get_parent()  # StateMachine -> Enemy
	animated_sprite = parent.get_node("AnimatedSprite2D")
	movement_component = parent.get_node("MovementComponent")
	
	# Play idle animation
	if animated_sprite:
		animated_sprite.play("idle")
	
	# Random starting direction; turn_around() handles walls/edges/ladders
	parent.walk_direction = 1.0 if RNG.randf() > 0.5 else -1.0

func update(delta: float):
	# Face movement direction
	if animated_sprite:
		animated_sprite.flip_h = parent.walk_direction < 0

func physics_update(delta: float):
	if parent.is_dead:
		return
	# Check for edge/wall/ladder BEFORE setting velocity so we never step off the platform
	if parent.should_turn_around():
		parent.turn_around()
	# Walk on platforms; turn only at walls/edges/ladders
	parent.velocity.x = parent.walk_direction * parent.speed * 0.5  # Slower patrol speed
	
	# Check for transitions
	check_transitions()

func check_transitions():
	# Check if player is in detection range
	if parent.get_distance_to_target() <= parent.detection_range:
		transition_to("chase")
		return
