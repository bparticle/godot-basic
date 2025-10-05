extends Node2D

func _ready():
	setup_pixel_game()

func setup_pixel_game():
	# Create and add the pixel level
	var level_script = load("res://PixelLevel.gd")
	var level = Node2D.new()
	level.set_script(level_script)
	level.name = "PixelLevel"
	add_child(level)
	
	# Create and add the pixel player
	var player_script = load("res://PixelPlayer.gd")
	var player = CharacterBody2D.new()
	player.set_script(player_script)
	player.position = Vector2(100, -100)  # Start position
	player.name = "PixelPlayer"
	add_child(player)
	
	# Set up camera
	setup_pixel_camera(player)

func setup_pixel_camera(player: Node2D):
	var camera = Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	
	# Set camera limits
	camera.limit_left = -100
	camera.limit_right = 900
	camera.limit_top = -300
	camera.limit_bottom = 200
	
	# Make camera zoom appropriate for pixel art
	camera.zoom = Vector2(2, 2)  # 2x zoom for pixel art
	
	player.add_child(camera)


