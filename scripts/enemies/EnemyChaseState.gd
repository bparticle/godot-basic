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
	
	# Play walk animation
	if animated_sprite:
		animated_sprite.play("walk")
	# Keep current walk_direction; flipping is handled only by obstacle/edge in physics_update via turn_around()

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
	parent.velocity.x = parent.walk_direction * parent.speed * parent.chase_speed_multiplier
	
	# Check for transitions
	check_transitions()

func check_transitions():
	# Check if player is out of detection range
	if parent.get_distance_to_target() > parent.detection_range:
		transition_to("idle")
		return
	
	# Attack phase as soon as we see the player on the same level (chase toward them with attack animation)
	if parent.is_player_on_same_level():
		transition_to("attack")
		return
