class_name EnemySuspiciousState
extends State

# Enemy suspicious state - player glimpsed or noise heard, looking around
# Transitions to: Alert (found player), Patrol (timeout with no evidence)

var parent: Enemy
var animated_sprite: AnimatedSprite2D

var suspicious_timer: float = 0.0
var look_timer: float = 0.0
var look_interval: float = 0.8  # Time between direction changes
var initial_direction: float = 1.0

@export var suspicious_duration: float = 2.5  # How long to stay suspicious before returning to patrol

func enter():
	parent = get_parent().get_parent()  # StateMachine -> Enemy
	animated_sprite = parent.get_node("AnimatedSprite2D")
	
	# Play idle/suspicious animation (use idle if no suspicious animation exists)
	if animated_sprite:
		if animated_sprite.sprite_frames.has_animation("suspicious"):
			animated_sprite.play("suspicious")
		else:
			animated_sprite.play("idle")
	
	# Reset timers
	suspicious_timer = 0.0
	look_timer = 0.0
	initial_direction = parent.walk_direction
	
	# Stop moving while suspicious
	parent.velocity.x = 0

func exit():
	pass

func update(delta: float):
	suspicious_timer += delta
	look_timer += delta
	
	# Look around periodically (turn to face different directions)
	if look_timer >= look_interval:
		look_timer = 0.0
		parent.walk_direction = -parent.walk_direction
		# Face the look direction
		if animated_sprite:
			animated_sprite.flip_h = parent.walk_direction < 0

func physics_update(_delta: float):
	if parent.is_dead:
		return
	
	# Don't block ladders - keep moving if we're on one
	if parent.is_near_ladder():
		# Move toward player if we have a target, otherwise walk_direction
		if parent.target:
			var to_player = parent.target.global_position.x - parent.global_position.x
			var move_dir = sign(to_player) if abs(to_player) > 4.0 else parent.walk_direction
			parent.velocity.x = move_dir * parent.speed * 0.4
		else:
			parent.velocity.x = parent.walk_direction * parent.speed * 0.4
	else:
		# Stay still while suspicious (but not on ladders)
		parent.velocity.x = 0
	
	check_transitions()

func check_transitions():
	# Direct sight -> immediately become alert and chase
	if parent.can_see_player():
		parent.awareness_level = parent.alert_threshold
		transition_to("chase")
		return
	
	# Peripheral sight -> build more suspicion
	if parent.can_see_player_peripheral():
		# Turn toward the peripheral detection
		var to_player = parent.target.global_position.x - parent.global_position.x
		parent.walk_direction = sign(to_player)
		if animated_sprite:
			animated_sprite.flip_h = parent.walk_direction < 0
		return
	
	# Awareness built up enough -> become alert
	if parent.awareness_level >= parent.alert_threshold:
		transition_to("chase")
		return
	
	# Timeout with no evidence -> return to patrol
	if suspicious_timer >= suspicious_duration:
		parent.awareness_level = 0.0
		transition_to("idle")
		return
	
	# Awareness decayed completely -> return to patrol
	if parent.awareness_level <= 0.0:
		transition_to("idle")
		return
