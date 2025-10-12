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
	
	# Reset attack state
	attack_timer = 0.0
	has_attacked = false

func update(delta: float):
	attack_timer += delta
	
	# Perform attack once during the attack duration
	if not has_attacked and attack_timer >= attack_duration * 0.5:
		perform_attack()
		has_attacked = true

func physics_update(delta: float):
	# Stop moving during attack
	parent.velocity.x = 0
	
	# Check for transitions
	check_transitions()

func perform_attack():
	"""Perform the actual attack on the player"""
	if not parent.target:
		return
	
	# Check if target is still in range
	if parent.get_distance_to_target() <= parent.attack_range:
		# Deal damage to player
		var health_manager = get_node("/root/HealthManager")
		if health_manager:
			health_manager.take_damage(parent.attack_damage)
		print("Enemy attacked player for ", parent.attack_damage, " damage!")

func check_transitions():
	# Check if attack duration is over
	if attack_timer >= attack_duration:
		# Check if player is still in range
		if parent.get_distance_to_target() <= parent.attack_range:
			# Stay in attack state for another attack
			transition_to("attack")
		else:
			# Player moved away, go back to chase
			transition_to("chase")
		return
	
	# Check if player moved out of attack range
	if parent.get_distance_to_target() > parent.attack_range:
		transition_to("chase")
		return
	
	# Check if player moved out of detection range
	if parent.get_distance_to_target() > parent.detection_range:
		transition_to("idle")
		return
