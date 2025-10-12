class_name EnemyIdleState
extends State

# Enemy idle state - patrols or waits

var parent: Enemy
var animated_sprite: AnimatedSprite2D
var movement_component: MovementComponent

# Patrol variables
var patrol_timer: float = 0.0
var patrol_duration: float = 2.0
var patrol_direction: float = 1.0

func enter():
	parent = get_parent().get_parent()  # StateMachine -> Enemy
	animated_sprite = parent.get_node("AnimatedSprite2D")
	movement_component = parent.get_node("MovementComponent")
	
	# Start patrol timer
	patrol_timer = 0.0
	patrol_direction = 1.0 if randf() > 0.5 else -1.0

func update(delta: float):
	patrol_timer += delta
	
	# Change direction periodically
	if patrol_timer >= patrol_duration:
		patrol_timer = 0.0
		patrol_direction *= -1.0

func physics_update(delta: float):
	# Simple patrol movement
	parent.velocity.x = patrol_direction * parent.speed * 0.5  # Slower patrol speed
	
	# Check for transitions
	check_transitions()

func check_transitions():
	# Check if player is in detection range
	if parent.get_distance_to_target() <= parent.detection_range:
		transition_to("chase")
		return
