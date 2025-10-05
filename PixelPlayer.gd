extends CharacterBody2D

# Player movement constants
const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const ACCELERATION = 1000.0
const FRICTION = 1000.0

# Get the gravity from the project settings
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Animation state
var facing_right = true
var is_moving = false

func _ready():
	create_pixel_player()

func create_pixel_player():
	# Create sprite node for the player
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	
	# Try to load a player sprite, fallback to colored rectangle if not found
	var player_texture = load("res://assets/characters/player_idle.png")
	if player_texture:
		sprite.texture = player_texture
		sprite.scale = Vector2(2, 2)  # Scale up pixel art (2x for 16x16 -> 32x32)
	else:
		# Fallback: create a simple colored rectangle
		var fallback = ColorRect.new()
		fallback.size = Vector2(16, 16)
		fallback.position = Vector2(-8, -8)
		fallback.color = Color.BLUE
		sprite.add_child(fallback)
	
	add_child(sprite)
	
	# Create collision shape
	create_collision_shape()

func create_collision_shape():
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(16, 16)  # Match sprite size
	collision.shape = shape
	collision.position = Vector2(0, -8)  # Center the collision
	add_child(collision)

func _physics_process(delta):
	handle_gravity(delta)
	handle_jumping()
	handle_horizontal_movement(delta)
	handle_animation()
	
	move_and_slide()

func handle_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

func handle_jumping():
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

func handle_horizontal_movement(delta):
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
		facing_right = direction > 0
		is_moving = true
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		is_moving = false

func handle_animation():
	# Flip sprite based on facing direction
	var sprite = get_node("Sprite2D")
	if facing_right:
		sprite.scale.x = abs(sprite.scale.x)
	else:
		sprite.scale.x = -abs(sprite.scale.x)
	
	# TODO: Add walking animation frames here
	# This is where you'd switch between idle and walk sprites


