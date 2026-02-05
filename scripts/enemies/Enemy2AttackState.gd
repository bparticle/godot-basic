class_name Enemy2AttackState
extends State

# Enemy2 lunge attack state - jumps at the player during attack
# This enemy performs a leaping attack toward the player

enum AttackPhase { TELEGRAPH, LUNGE, RECOVERY }

var parent: Enemy
var animated_sprite: AnimatedSprite2D

var attack_phase: AttackPhase = AttackPhase.TELEGRAPH
var phase_timer: float = 0.0
var has_dealt_damage: bool = false
var has_lunged: bool = false

# Phase durations
var telegraph_duration: float = 0.25  # Brief wind-up before jump
var lunge_duration: float = 0.4  # Time in the air
var recovery_duration: float = 0.5  # Landing recovery

# Lunge parameters - tweak these to adjust the attack!
@export var lunge_speed_x: float = 60.0  # Horizontal lunge speed (pixels/sec)
@export var lunge_jump_force: float = -80.0  # Vertical jump force (negative = up, smaller = shorter hop)

func enter():
	parent = get_parent().get_parent()  # StateMachine -> Enemy
	animated_sprite = parent.get_node("AnimatedSprite2D")
	
	# Reset attack state
	attack_phase = AttackPhase.TELEGRAPH
	phase_timer = 0.0
	has_dealt_damage = false
	has_lunged = false
	
	# Apply personality: aggressive enemies have shorter telegraph
	telegraph_duration = 0.25 * (1.0 - parent.aggression * 0.3)
	
	_start_telegraph_phase()

func exit():
	if animated_sprite:
		animated_sprite.modulate = Color.WHITE

func _start_telegraph_phase():
	"""Wind-up phase - crouch before jumping."""
	attack_phase = AttackPhase.TELEGRAPH
	phase_timer = 0.0
	
	# Stop moving during wind-up
	parent.velocity.x = 0
	
	# Face the player
	if animated_sprite and parent.target:
		animated_sprite.flip_h = parent.target.global_position.x < parent.global_position.x
	
	if animated_sprite:
		# Play attack animation (first frames serve as telegraph)
		animated_sprite.play("attack")
		animated_sprite.modulate = Color.WHITE

func _start_lunge_phase():
	"""Lunge phase - jump toward the player."""
	attack_phase = AttackPhase.LUNGE
	phase_timer = 0.0
	has_dealt_damage = false
	has_lunged = false
	
	if animated_sprite:
		animated_sprite.play("attack")
		animated_sprite.modulate = Color.WHITE
	
	# Calculate lunge direction toward player
	if parent.target:
		var to_player = parent.target.global_position - parent.global_position
		var direction = sign(to_player.x) if abs(to_player.x) > 1.0 else parent.walk_direction
		
		# Apply lunge velocity - jump toward player
		parent.velocity.x = direction * lunge_speed_x
		parent.velocity.y = lunge_jump_force
		
		# Update walk direction and sprite facing
		parent.walk_direction = direction
		if animated_sprite:
			animated_sprite.flip_h = direction < 0
		
		has_lunged = true

func _start_recovery_phase():
	"""Recovery phase - landing and cooldown."""
	attack_phase = AttackPhase.RECOVERY
	phase_timer = 0.0
	
	if animated_sprite:
		animated_sprite.play("idle")
		animated_sprite.modulate = Color.WHITE

func update(delta: float):
	if parent.is_dead:
		return
	
	phase_timer += delta
	
	# Handle phase transitions
	match attack_phase:
		AttackPhase.TELEGRAPH:
			if phase_timer >= telegraph_duration:
				_start_lunge_phase()
		
		AttackPhase.LUNGE:
			# Deal damage when we're close to the player during lunge
			if not has_dealt_damage:
				if parent.get_distance_to_target() <= parent.attack_range * 1.2:
					perform_attack()
					has_dealt_damage = true
			
			# End lunge when we land
			if parent.is_on_floor() and has_lunged and phase_timer > 0.1:
				_start_recovery_phase()
			# Safety: end lunge after max duration
			elif phase_timer >= lunge_duration:
				_start_recovery_phase()
		
		AttackPhase.RECOVERY:
			if phase_timer >= recovery_duration:
				check_transitions()

func physics_update(_delta: float):
	if parent.is_dead:
		return
	
	# Don't block ladders - keep moving away if near one (except during lunge)
	if parent.is_near_ladder() and attack_phase != AttackPhase.LUNGE:
		parent.velocity.x = parent.walk_direction * parent.speed * 0.5
		return
	
	match attack_phase:
		AttackPhase.TELEGRAPH:
			# Stand still during wind-up
			parent.velocity.x = 0
		
		AttackPhase.LUNGE:
			# Keep horizontal momentum during lunge, gravity is applied by Enemy._physics_process
			# Slight air control toward player
			if parent.target and not parent.is_on_floor():
				var to_player_x = parent.target.global_position.x - parent.global_position.x
				var desired_dir = sign(to_player_x)
				parent.velocity.x = move_toward(parent.velocity.x, desired_dir * lunge_speed_x, 50.0 * _delta)
		
		AttackPhase.RECOVERY:
			# Slow down during recovery
			parent.velocity.x = move_toward(parent.velocity.x, 0, 300.0 * _delta)

func perform_attack():
	"""Perform the actual attack on the player."""
	if not parent.target or parent.is_dead:
		return
	# Don't damage if player is on top of us (stomp)
	if parent._is_stomp(parent.target):
		return
	# Don't damage if player center is above our center
	if parent.target.global_position.y < parent.global_position.y - 8:
		return
	# Deal damage
	parent._damage_player()

func check_transitions():
	# Lost sight of player -> search
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
	
	# Player jumped away -> chase
	if not parent.is_player_on_same_level():
		transition_to("chase")
		return
	
	# Player still in range -> attack again
	if parent.get_distance_to_target() <= parent.attack_range * 2.0:
		_start_telegraph_phase()
	else:
		# Too far for immediate attack -> chase
		transition_to("chase")
