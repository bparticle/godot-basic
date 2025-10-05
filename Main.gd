extends Node2D

func _ready():
	setup_game()

func setup_game():
	# Create and add the level
	var level_script = load("res://Level.gd")
	var level = Node2D.new()
	level.set_script(level_script)
	level.name = "Level"
	add_child(level)
	
	# Create and add the player
	var player_script = load("res://Player.gd")
	var player = CharacterBody2D.new()
	player.set_script(player_script)
	player.position = Vector2(100, -100)  # Start position above the ground
	player.name = "Player"
	add_child(player)
	
	# Set up camera to follow player
	setup_camera(player)

func setup_camera(player: Node2D):
	var camera = Camera2D.new()
	camera.enabled = true
	# Make camera follow smoothly
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	# Add some limits so camera doesn't go too far
	camera.limit_left = -100
	camera.limit_right = 900
	camera.limit_top = -300
	camera.limit_bottom = 200
	
	# Attach camera to player
	player.add_child(camera)


