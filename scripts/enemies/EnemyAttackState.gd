class_name EnemyAttackState
extends State

# Enemy attack state - attacks the player with telegraph -> strike -> recovery phases
# The telegraph phase gives players time to react, making combat feel fair

enum AttackPhase { TELEGRAPH, STRIKE, RECOVERY }

var parent: Enemy
var animated_sprite: AnimatedSprite2D
var movement_component: MovementComponent

var attack_phase: AttackPhase = AttackPhase.TELEGRAPH
var phase_timer: float = 0.0
var has_dealt_damage: bool = false

# Phase durations (adjusted by personality)
var telegraph_duration: float = 0.3  # Wind-up warning
var strike_duration: float = 0.2  # Active attack frames
var recovery_duration: float = 0.4  # Cool down after attack

func enter():
	parent = get_parent().get_parent()  # StateMachine -> Enemy
	animated_sprite = parent.get_node("AnimatedSprite2D")
	movement_component = parent.get_node("MovementComponent")
	
	# Reset attack state
	attack_phase = AttackPhase.TELEGRAPH
	phase_timer = 0.0
	has_dealt_damage = false
	
	# Apply personality: aggressive enemies have shorter telegraph (less warning)
	telegraph_duration = 0.3 * (1.0 - parent.aggression * 0.4)
	
	# Start telegraph phase - play wind-up animation
	_start_telegraph_phase()

func exit():
	# Restore normal sprite
	if animated_sprite:
		animated_sprite.modulate = Color.WHITE

func _start_telegraph_phase():
	"""Wind-up phase - visual warning before attack."""
	attack_phase = AttackPhase.TELEGRAPH
	phase_timer = 0.0
	
	if animated_sprite:
		# Try to play telegraph animation, fall back to idle
		if animated_sprite.sprite_frames.has_animation("attack_telegraph"):
			animated_sprite.play("attack_telegraph")
		else:
			animated_sprite.play("idle")
		animated_sprite.modulate = Color.WHITE
	
	# Stop moving during telegraph (winding up)
	parent.velocity.x = 0

func _start_strike_phase():
	"""Active attack phase - deal damage and lunge."""
	attack_phase = AttackPhase.STRIKE
	phase_timer = 0.0
	has_dealt_damage = false
	
	if animated_sprite:
		animated_sprite.play("attack")
		animated_sprite.modulate = Color.WHITE

func _start_recovery_phase():
	"""Recovery phase - brief vulnerability after attack."""
	attack_phase = AttackPhase.RECOVERY
	phase_timer = 0.0
	
	if animated_sprite:
		animated_sprite.modulate = Color.WHITE

func update(delta: float):
	if parent.is_dead:
		return
	
	phase_timer += delta
	
	# Face the player during all attack phases
	if animated_sprite and parent.target:
		animated_sprite.flip_h = parent.target.global_position.x < parent.global_position.x
	
	# Handle phase transitions
	match attack_phase:
		AttackPhase.TELEGRAPH:
			if phase_timer >= telegraph_duration:
				_start_strike_phase()
		
		AttackPhase.STRIKE:
			# Deal damage once during strike phase
			if not has_dealt_damage and phase_timer >= strike_duration * 0.3:
				perform_attack()
				has_dealt_damage = true
			
			if phase_timer >= strike_duration:
				_start_recovery_phase()
		
		AttackPhase.RECOVERY:
			if phase_timer >= recovery_duration:
				# Attack cycle complete - check if we should attack again
				check_transitions()

func physics_update(_delta: float):
	if parent.is_dead:
		return
	
	# Don't block ladders - keep moving toward player if on one
	if parent.is_near_ladder() and attack_phase != AttackPhase.STRIKE:
		# Move toward player, not just in walk_direction
		if parent.target:
			var to_player = parent.target.global_position.x - parent.global_position.x
			var move_dir = sign(to_player) if abs(to_player) > 4.0 else parent.walk_direction
			parent.velocity.x = move_dir * parent.speed * 0.5
		else:
			parent.velocity.x = parent.walk_direction * parent.speed * 0.5
		return
	
	match attack_phase:
		AttackPhase.TELEGRAPH:
			# Stand still during wind-up
			parent.velocity.x = 0
		
		AttackPhase.STRIKE:
			# Lunge toward player during strike
			if parent.should_turn_around():
				parent.turn_around()
				parent.velocity.x = parent.walk_direction * parent.speed * parent.attack_speed_multiplier
			elif parent.is_on_wall() and parent.is_wall_ignorable():
				parent.velocity.x = parent.walk_direction * parent.speed * parent.attack_speed_multiplier
			elif parent.target:
				var to_player = parent.target.global_position.x - parent.global_position.x
				var dir = sign(to_player) if abs(to_player) > 1.0 else parent.walk_direction
				parent.velocity.x = dir * parent.speed * parent.attack_speed_multiplier * 1.5  # Extra burst during strike
			else:
				parent.velocity.x = 0
		
		AttackPhase.RECOVERY:
			# Slow down during recovery (vulnerable)
			parent.velocity.x = move_toward(parent.velocity.x, 0, parent.speed * 2.0)

func perform_attack():
	"""Perform the actual attack on the player."""
	if not parent.target or parent.is_dead:
		return
	# Don't damage if player is on top of us (stomp)
	if parent._is_stomp(parent.target):
		return
	# Don't damage if player center is above our center (player on top)
	if parent.target.global_position.y < parent.global_position.y - 8:
		return
	# Check if target is still in range
	if parent.get_distance_to_target() <= parent.attack_range:
		parent._damage_player()

func check_transitions():
	# Lost sight of player -> search for them
	if not parent.can_see_player():
		if parent.awareness_level > 0:
			transition_to("search")
		else:
			transition_to("idle")
		return
	
	# Player out of detection range -> return to patrol
	if parent.get_distance_to_target() > parent.detection_range:
		transition_to("idle")
		return
	
	# Player left the same level (jumped away) -> chase
	if not parent.is_player_on_same_level():
		transition_to("chase")
		return
	
	# Player still in range and on same level -> attack again
	if parent.get_distance_to_target() <= parent.attack_range * 1.5:
		# Reset for another attack
		_start_telegraph_phase()
	else:
		# Too far for immediate attack -> chase to close distance
		transition_to("chase")
