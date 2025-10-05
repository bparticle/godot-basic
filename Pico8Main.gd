extends Node2D

# Pico-8 style constants
const SCREEN_WIDTH = 128  # Pico-8 screen width in pixels
const SCREEN_HEIGHT = 128  # Pico-8 screen height in pixels
const TILE_SIZE = 8  # 8x8 tiles
const SCALE_FACTOR = 4  # Scale 8x8 to 32x32 screen pixels

func _ready():
	setup_pico8_game()

func setup_pico8_game():
	# Create and add the Pico-8 level
	var level_script = load("res://Pico8Level.gd")
	var level = Node2D.new()
	level.set_script(level_script)
	level.name = "Pico8Level"
	add_child(level)
	
	# Create and add the Pico-8 player
	var player_script = load("res://Pico8Player.gd")
	var player = CharacterBody2D.new()
	player.set_script(player_script)
	player.position = Vector2(16, 16)  # Start position in 8x8 grid
	player.name = "Pico8Player"
	add_child(player)
	
	# Set up Pico-8 style camera
	setup_pico8_camera(player)

func setup_pico8_camera(player: Node2D):
	var camera = Camera2D.new()
	camera.enabled = true
	
	# Pico-8 style camera settings
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0  # Faster smoothing for retro feel
	
	# Set camera limits to match 8x8 grid
	camera.limit_left = -16
	camera.limit_right = 176  # 22 tiles * 8 pixels
	camera.limit_top = -32
	camera.limit_bottom = 80   # 10 tiles * 8 pixels
	
	# Pico-8 style zoom (4x scale for 8x8 -> 32x32)
	camera.zoom = Vector2(SCALE_FACTOR, SCALE_FACTOR)
	
	# Center camera on player
	camera.position = player.position
	
	player.add_child(camera)
	
	# Set up viewport for Pico-8 style rendering
	setup_pico8_viewport()

func setup_pico8_viewport():
	# Get the main viewport
	var viewport = get_viewport()
	
	# Set up Pico-8 style viewport
	viewport.size = Vector2i(SCREEN_WIDTH * SCALE_FACTOR, SCREEN_HEIGHT * SCALE_FACTOR)
	
	# Enable pixel perfect rendering
	viewport.snap_2d_transforms_to_pixel = true
	viewport.snap_2d_vertices_to_pixel = true
	
	# Set up stretch mode for pixel perfect scaling (Godot 4 syntax)
	# Note: These settings are handled by project settings in Godot 4
	# viewport.stretch_mode = Viewport.STRETCH_MODE_VIEWPORT
	# viewport.stretch_aspect = Viewport.STRETCH_ASPECT_KEEP
