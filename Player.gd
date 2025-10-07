extends CharacterBody2D

# Movement constants
const SPEED = 60.0
const JUMP_VELOCITY = -220.0
const ACCELERATION = 400.0
const FRICTION = 400.0

# Collision shape sizes for different states
const COLLISION_IDLE = Vector2(7, 14)
const COLLISION_WALK = Vector2(7, 14)
const COLLISION_JUMP = Vector2(7, 12)  # Slightly smaller when jumping

# References
@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var room_manager = get_node("/root/RoomManager")

func _ready():
	# Add player to a group for easy access
	add_to_group("player")
	# Listen for room changes to briefly lock input and reset motion
	if room_manager:
		room_manager.room_changed.connect(_on_room_changed)

# State
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var current_animation = ""
var input_locked_until_ms: int = 0
@export var input_lock_duration_ms: int = 150

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_jump()
	handle_movement(delta)
	update_animation()
	update_collision_shape()  # Update collision based on animation
	move_and_slide()
	# Boundary constraints removed - using physics collisions instead

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

func handle_jump() -> void:
	if _is_input_locked():
		return
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

func handle_movement(delta: float) -> void:
	var direction = 0.0 if _is_input_locked() else Input.get_axis("ui_left", "ui_right")
	
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

func update_animation() -> void:
	# Handle sprite flipping
	if velocity.x < 0:
		animated_sprite.flip_h = true
	elif velocity.x > 0:
		animated_sprite.flip_h = false
	
	# Handle animation states
	var new_animation = ""
	if not is_on_floor():
		new_animation = "jump"
	elif abs(velocity.x) > 5:
		new_animation = "walk"
	else:
		new_animation = "idle"
	
	# Only change if different
	if new_animation != current_animation:
		current_animation = new_animation
		animated_sprite.play(current_animation)

func update_collision_shape() -> void:
	# Get the shape resource
	var shape = collision_shape.shape as RectangleShape2D
	if not shape:
		return
	
	# Adjust collision size based on current animation
	match current_animation:
		"idle":
			shape.size = COLLISION_IDLE
		"walk":
			shape.size = COLLISION_WALK
		"jump":
			shape.size = COLLISION_JUMP

func _on_room_changed(_room_data, _spawn_pos):
	# Lock input briefly and reset velocity when entering a new room
	input_locked_until_ms = Time.get_ticks_msec() + input_lock_duration_ms
	velocity = Vector2.ZERO

func _is_input_locked() -> bool:
	return Time.get_ticks_msec() < input_locked_until_ms
