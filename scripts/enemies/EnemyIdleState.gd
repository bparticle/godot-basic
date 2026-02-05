class_name EnemyIdleState
extends State

# Enemy idle/patrol state - walks on platforms, uses vision system for detection
# Transitions to: Suspicious (peripheral sight), Chase (direct sight)

var parent: Enemy
var animated_sprite: AnimatedSprite2D
var movement_component: MovementComponent

func enter():
	parent = get_parent().get_parent()  # StateMachine -> Enemy
	animated_sprite = parent.get_node("AnimatedSprite2D")
	movement_component = parent.get_node("MovementComponent")
	
	# Play idle/walk animation for patrol
	if animated_sprite:
		animated_sprite.play("idle")
	
	# Random starting direction if this is a fresh start; turn_around() handles walls/edges
	if parent.awareness_level <= 0.0:
		parent.walk_direction = 1.0 if RNG.randf() > 0.5 else -1.0
	
	# Reset awareness when entering idle (returning to unaware state)
	parent.awareness_level = 0.0

func exit():
	pass

func update(_delta: float):
	# Face movement direction
	if animated_sprite:
		animated_sprite.flip_h = parent.walk_direction < 0

func physics_update(_delta: float):
	if parent.is_dead:
		return
	
	# Check for edge/wall/ladder BEFORE setting velocity so we never step off the platform
	if parent.should_turn_around():
		parent.turn_around()
	
	# Patrol at slower speed
	parent.velocity.x = parent.walk_direction * parent.speed * 0.5
	
	# Check for transitions
	check_transitions()

func check_transitions():
	# DIRECT SIGHT: Immediately become alert and chase
	if parent.can_see_player():
		parent.awareness_level = parent.alert_threshold
		if parent.target:
			parent.last_known_player_position = parent.target.global_position
		transition_to("chase")
		return
	
	# PERIPHERAL SIGHT: Become suspicious (something caught our attention)
	if parent.can_see_player_peripheral():
		# Build some awareness
		parent.awareness_level = 0.3
		transition_to("suspicious")
		return
	
	# AWARENESS BUILDUP: If awareness is building (from update_awareness in Enemy.gd)
	# This catches cases where player is just at edge of peripheral vision
	if parent.awareness_level > 0.5:
		transition_to("suspicious")
		return
