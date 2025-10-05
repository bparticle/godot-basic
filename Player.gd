extends CharacterBody2D

# Player movement constants
const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const ACCELERATION = 1000.0
const FRICTION = 1000.0

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	# Create the player's visual representation
	create_player_visual()
	create_collision_shape()

func create_player_visual():
	# Create a simple colored rectangle for the player
	var sprite = ColorRect.new()
	sprite.size = Vector2(32, 48)
	sprite.position = Vector2(-16, -48)  # Center the rectangle
	sprite.color = Color.BLUE
	add_child(sprite)

func create_collision_shape():
	# Create collision shape for the player
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 48)
	collision.shape = shape
	collision.position = Vector2(0, -24)  # Center the collision shape
	add_child(collision)

func _physics_process(delta):
	handle_gravity(delta)
	handle_jumping()
	handle_horizontal_movement(delta)
	
	# Move the character
	move_and_slide()

func handle_gravity(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y += gravity * delta

func handle_jumping():
	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

func handle_horizontal_movement(delta):
	# Get input direction
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction != 0:
		# Apply acceleration when moving
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
	else:
		# Apply friction when not moving
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

