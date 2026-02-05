class_name EnemySearchState
extends State

# Enemy search state - lost player, investigating last known position
# Transitions to: Chase (player found), Patrol (search timeout)

var parent: Enemy
var animated_sprite: AnimatedSprite2D

var search_timer: float = 0.0
var reached_last_position: bool = false
var look_around_timer: float = 0.0
var look_around_duration: float = 1.5  # Time to look around at last known position

func enter():
	parent = get_parent().get_parent()  # StateMachine -> Enemy
	animated_sprite = parent.get_node("AnimatedSprite2D")
	
	# Play walk animation while searching
	if animated_sprite:
		animated_sprite.play("walk")
	
	# Reset timers
	search_timer = 0.0
	look_around_timer = 0.0
	reached_last_position = false
	
	# Face toward last known position
	if parent.last_known_player_position != Vector2.ZERO:
		var to_last_pos = parent.last_known_player_position.x - parent.global_position.x
		if abs(to_last_pos) > 4.0:
			parent.walk_direction = sign(to_last_pos)

func exit():
	pass

func update(delta: float):
	search_timer += delta
	
	# Face movement direction
	if animated_sprite:
		animated_sprite.flip_h = parent.walk_direction < 0
	
	# If we've reached the last position, look around
	if reached_last_position:
		look_around_timer += delta
		# Alternate facing direction while looking around
		if int(look_around_timer * 2) % 2 == 0:
			animated_sprite.flip_h = not animated_sprite.flip_h

func physics_update(_delta: float):
	if parent.is_dead:
		return
	
	# Don't block ladders - keep moving toward last known position if on one
	if parent.is_near_ladder():
		# Move toward last known position or player
		var target_x = parent.last_known_player_position.x
		if parent.target and parent.can_see_player():
			target_x = parent.target.global_position.x
		var to_target = target_x - parent.global_position.x
		var move_dir = sign(to_target) if abs(to_target) > 4.0 else parent.walk_direction
		parent.velocity.x = move_dir * parent.speed * 0.5
		return
	
	# Check if we should stop and look around at last known position
	if not reached_last_position:
		var distance_to_last = abs(parent.global_position.x - parent.last_known_player_position.x)
		if distance_to_last < 8.0 or parent.should_turn_around():
			# Reached the position or hit an obstacle
			reached_last_position = true
			parent.velocity.x = 0
			if animated_sprite:
				animated_sprite.play("idle")
		else:
			# Move toward last known position
			var to_last_pos = parent.last_known_player_position.x - parent.global_position.x
			parent.walk_direction = sign(to_last_pos)
			parent.velocity.x = parent.walk_direction * parent.speed * 0.7  # Slower, cautious movement
	else:
		# Standing still, looking around
		parent.velocity.x = 0
	
	check_transitions()

func check_transitions():
	# Found player -> chase immediately
	if parent.can_see_player():
		parent.awareness_level = parent.alert_threshold
		transition_to("chase")
		return
	
	# Peripheral sight -> turn and investigate
	if parent.can_see_player_peripheral():
		var to_player = parent.target.global_position.x - parent.global_position.x
		parent.walk_direction = sign(to_player)
		# Reset to approach this new direction
		reached_last_position = false
		parent.last_known_player_position = parent.target.global_position
		return
	
	# Apply personality: persistent enemies search longer
	var effective_search_duration = parent.search_duration * (1.0 + parent.persistence * 0.5)
	
	# Search timeout -> return to patrol
	if search_timer >= effective_search_duration:
		parent.awareness_level = 0.0
		transition_to("idle")
		return
	
	# If we've looked around long enough at last position, return to patrol
	if reached_last_position and look_around_timer >= look_around_duration:
		parent.awareness_level = max(0.0, parent.awareness_level - 0.5)
		transition_to("idle")
		return
