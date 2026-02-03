class_name EnemyAttackState
extends State

# Enemy attack state - attacks the player

var parent: Enemy
var animated_sprite: AnimatedSprite2D
var movement_component: MovementComponent

var attack_timer: float = 0.0
var attack_duration: float = 1.0
var has_attacked: bool = false

func enter():
	parent = get_parent().get_parent()  # StateMachine -> Enemy
	animated_sprite = parent.get_node("AnimatedSprite2D")
	movement_component = parent.get_node("MovementComponent")
	
	# Play attack (mouth open) animation
	if animated_sprite:
		animated_sprite.play("attack")
	
	# Reset attack state
	attack_timer = 0.0
	has_attacked = false

func update(delta: float):
	if parent.is_dead:
		return
	attack_timer += delta
	# Face the player while attacking (so the lunge looks correct)
	if animated_sprite and parent.target:
		animated_sprite.flip_h = parent.target.global_position.x < parent.global_position.x
	
	# Perform attack once during the attack duration
	if not has_attacked and attack_timer >= attack_duration * 0.5:
		perform_attack()
		has_attacked = true

func physics_update(delta: float):
	if parent.is_dead:
		return
	# Respect edges and walls: never run off the platform or push into a wall/ladder
	if parent.should_turn_around():
		parent.turn_around()
		parent.velocity.x = parent.walk_direction * parent.speed * parent.attack_speed_multiplier
	elif parent.is_on_wall() and parent.is_wall_ignorable():
		# Stuck against player/collectible/ladder - move in walk_direction to avoid left-right lock
		parent.velocity.x = parent.walk_direction * parent.speed * parent.attack_speed_multiplier
	elif parent.target:
		var to_player = parent.target.global_position.x - parent.global_position.x
		var dir = sign(to_player) if abs(to_player) > 1.0 else parent.walk_direction
		parent.velocity.x = dir * parent.speed * parent.attack_speed_multiplier
	else:
		parent.velocity.x = 0
	
	# Check for transitions
	check_transitions()

func perform_attack():
	"""Perform the actual attack on the player"""
	if not parent.target or parent.is_dead:
		return
	# Don't damage if player is on top of us (stomp) - only damage on side contact
	if parent._is_stomp(parent.target):
		return
	# Don't damage if player center is above our center (player on top)
	if parent.target.global_position.y < parent.global_position.y - 8:
		return
	# Check if target is still in range
	if parent.get_distance_to_target() <= parent.attack_range:
		# Single source of damage: _damage_player notifies player first, then take_damage (so death jump/tile work)
		parent._damage_player()

func check_transitions():
	# Leave attack only when player is out of detection range or no longer on same level
	if parent.get_distance_to_target() > parent.detection_range:
		transition_to("idle")
		return
	
	# Player left the same level (e.g. jumped to another platform) -> go back to chase/patrol
	if not parent.is_player_on_same_level():
		transition_to("chase")
		return
	
	# Stay in attack: same level and in sight, keep chasing toward the player
	# (attack timer and perform_attack handle the actual damage when in range)
	if attack_timer >= attack_duration:
		transition_to("attack")
	return
