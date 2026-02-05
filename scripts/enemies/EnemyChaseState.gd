class_name EnemyChaseState
extends State

# Enemy chase state - actively follows the player using line-of-sight
# Key improvement: turns toward player when visible (smart chase direction)

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
	
	# Immediately face toward player if we can see them
	if parent.target and parent.can_see_player():
		var to_player_x = parent.target.global_position.x - parent.global_position.x
		if abs(to_player_x) > 4.0:
			parent.walk_direction = sign(to_player_x)

func exit():
	pass

func update(_delta: float):
	# Face movement direction
	if animated_sprite:
		animated_sprite.flip_h = parent.walk_direction < 0

func physics_update(_delta: float):
	if parent.is_dead:
		return
	
	# SMART CHASE: Turn toward player when we can see them
	if parent.target and parent.can_see_player():
		var to_player_x = parent.target.global_position.x - parent.global_position.x
		# Dead zone to prevent jitter when player is directly above/below
		if abs(to_player_x) > 4.0:
			var desired_direction = sign(to_player_x)
			# Only change direction if it won't immediately cause a turn-around
			if desired_direction != parent.walk_direction:
				# Check if turning toward player is safe (won't walk off edge)
				var old_direction = parent.walk_direction
				parent.walk_direction = desired_direction
				if parent.should_turn_around():
					# Unsafe to go that way - revert
					parent.walk_direction = old_direction
	
	# Still check for edge/wall BEFORE setting velocity
	if parent.should_turn_around():
		parent.turn_around()
	
	# Apply personality: aggressive enemies chase faster
	var effective_speed_mult = parent.chase_speed_multiplier * (1.0 + parent.aggression * 0.3)
	parent.velocity.x = parent.walk_direction * parent.speed * effective_speed_mult
	
	# Check for transitions
	check_transitions()

func check_transitions():
	# Lost line of sight -> search for player
	if not parent.can_see_player():
		# Only search if we had awareness built up
		if parent.awareness_level > 0.5 and parent.last_known_player_position != Vector2.ZERO:
			transition_to("search")
		else:
			transition_to("idle")
		return
	
	# Player out of vision range -> lose them
	if parent.get_distance_to_target() > parent.vision_range:
		if parent.awareness_level > 0.5:
			transition_to("search")
		else:
			transition_to("idle")
		return
	
	# Player on same level and in attack range -> attack!
	if parent.is_player_on_same_level() and parent.get_distance_to_target() <= parent.attack_range * 1.5:
		transition_to("attack")
		return
