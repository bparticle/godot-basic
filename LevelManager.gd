extends Node2D

# Level Manager - Choose between programmatic and visual level design
# This script lets you switch between different level creation methods

var use_programmatic_level = false  # Set to true for programmatic, false for visual

func _ready():
	if use_programmatic_level:
		create_programmatic_level()
	else:
		print("Using visual level design - paint tiles in the editor")
		setup_visual_camera()

func create_programmatic_level():
	# Create level using code (like before)
	var level_script = load("res://Pico8Level.gd")
	var level = Node2D.new()
	level.set_script(level_script)
	level.name = "ProgrammaticLevel"
	add_child(level)
	
	# Create player
	var player_script = load("res://Pico8Player.gd")
	var player = CharacterBody2D.new()
	player.set_script(player_script)
	player.position = Vector2(16, 16)
	player.name = "Player"
	add_child(player)
	
	# Set up camera
	setup_game_camera(player)

func setup_visual_camera():
	# Camera for visual level design
	var camera = Camera2D.new()
	camera.enabled = true
	camera.zoom = Vector2(4, 4)  # 4x zoom for 8x8 tiles
	camera.position = Vector2(0, 0)
	add_child(camera)

func setup_game_camera(player: Node2D):
	# Camera for gameplay
	var camera = Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.zoom = Vector2(4, 4)
	camera.position = player.position
	player.add_child(camera)


