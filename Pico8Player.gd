extends CharacterBody2D

# Pico-8 style constants
const SPEED = 60.0  # Slower, more deliberate movement
const JUMP_VELOCITY = -120.0  # Pico-8 style jump
const ACCELERATION = 200.0
const FRICTION = 200.0

# VIC-20 color palette (exact Aseprite colors)
const VIC20_COLORS = {
	"black": Color(0, 0, 0),           # 000000
	"white": Color(255, 255, 255),     # ffffff
	"brown": Color(168, 115, 74),      # a8734a
	"light_brown": Color(233, 178, 135), # e9b287
	"dark_red": Color(119, 45, 38),     # 772d26
	"light_red": Color(182, 104, 98),   # b66862
	"cyan": Color(133, 212, 220),       # 85d4dc
	"light_cyan": Color(197, 255, 255), # c5ffff
	"purple": Color(168, 95, 180),      # a85fb4
	"light_purple": Color(233, 157, 245), # e99df5
	"green": Color(85, 158, 74),        # 559e4a
	"light_green": Color(146, 223, 135), # 92df87
	"blue": Color(66, 52, 139),        # 42348b
	"light_blue": Color(126, 112, 202), # 7e70ca
	"yellow": Color(189, 204, 113),    # bdcc71
	"light_yellow": Color(255, 255, 176) # ffffb0
}

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var facing_right = true
var is_moving = false

func _ready():
	create_pico8_player()

func create_pico8_player():
	# Create 8x8 pixel player
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	
	# Try to load 8x8 player sprite
	var player_texture = load("res://assets/characters/player_8x8.png")
	if player_texture:
		sprite.texture = player_texture
		sprite.scale = Vector2(4, 4)  # 4x scale: 8x8 -> 32x32 screen pixels
	else:
		# Create 8x8 fallback sprite
		create_8x8_fallback_sprite(sprite)
	
	add_child(sprite)
	
	# Create 8x8 collision
	create_8x8_collision()

func create_8x8_fallback_sprite(sprite: Sprite2D):
	# Create a simple 8x8 pixel art player
	var image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	
	# Draw a simple 8x8 character
	# Head (2x2 pixels) - using light brown for skin
	image.set_pixel(3, 1, VIC20_COLORS["light_brown"])
	image.set_pixel(4, 1, VIC20_COLORS["light_brown"])
	image.set_pixel(3, 2, VIC20_COLORS["light_brown"])
	image.set_pixel(4, 2, VIC20_COLORS["light_brown"])
	
	# Body (2x3 pixels) - using blue for shirt
	image.set_pixel(3, 3, VIC20_COLORS["blue"])
	image.set_pixel(4, 3, VIC20_COLORS["blue"])
	image.set_pixel(3, 4, VIC20_COLORS["blue"])
	image.set_pixel(4, 4, VIC20_COLORS["blue"])
	image.set_pixel(3, 5, VIC20_COLORS["blue"])
	image.set_pixel(4, 5, VIC20_COLORS["blue"])
	
	# Legs (2x2 pixels) - using brown for pants
	image.set_pixel(3, 6, VIC20_COLORS["brown"])
	image.set_pixel(4, 6, VIC20_COLORS["brown"])
	image.set_pixel(3, 7, VIC20_COLORS["brown"])
	image.set_pixel(4, 7, VIC20_COLORS["brown"])
	
	# Create texture from image
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite.texture = texture
	sprite.scale = Vector2(4, 4)  # 4x scale for 8x8 -> 32x32

func create_8x8_collision():
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(8, 8)  # 8x8 collision
	collision.shape = shape
	collision.position = Vector2(0, -4)  # Center the collision
	add_child(collision)
	
	# Make sure the collision shape is properly configured
	print("✅ Player collision shape created: ", shape.size)

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
