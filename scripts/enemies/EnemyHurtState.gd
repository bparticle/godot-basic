class_name EnemyHurtState
extends State

# Enemy hurt state - brief stagger when taking damage
# Transitions to: Chase (recovery complete)

var parent: Enemy
var animated_sprite: AnimatedSprite2D

var stagger_timer: float = 0.0
var stagger_duration: float = 0.3  # Brief stagger time
var knockback_applied: bool = false

func enter():
	parent = get_parent().get_parent()  # StateMachine -> Enemy
	animated_sprite = parent.get_node("AnimatedSprite2D")
	
	# Reset state
	stagger_timer = 0.0
	knockback_applied = false
	
	# Stop horizontal movement
	parent.velocity.x = 0
	
	# Play hurt animation if available
	if animated_sprite:
		if animated_sprite.sprite_frames.has_animation("hurt"):
			animated_sprite.play("hurt")
		else:
			animated_sprite.play("idle")
		animated_sprite.modulate = Color.WHITE
	
	# Apply slight knockback away from player
	if parent.target and not knockback_applied:
		var knockback_direction = sign(parent.global_position.x - parent.target.global_position.x)
		if knockback_direction == 0:
			knockback_direction = parent.walk_direction
		parent.velocity.x = knockback_direction * 30.0  # Small knockback
		knockback_applied = true

func exit():
	# Restore normal sprite
	if animated_sprite:
		animated_sprite.modulate = Color.WHITE

func update(delta: float):
	stagger_timer += delta

func physics_update(delta: float):
	if parent.is_dead:
		return
	
	# Decelerate knockback
	parent.velocity.x = move_toward(parent.velocity.x, 0, 200.0 * delta)
	
	check_transitions()

func check_transitions():
	# Recovery complete -> return to chase (enemy is now angry)
	if stagger_timer >= stagger_duration:
		# After being hurt, enemy is fully alert and aggressive
		parent.awareness_level = 2.0
		if parent.target:
			parent.last_known_player_position = parent.target.global_position
		transition_to("chase")
		return
