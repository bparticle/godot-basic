extends Node2D

# Level Design Scene
# This scene is for designing levels in the Godot editor
# You can paint tiles directly in the editor using the TileMap

func _ready():
	print("Level Design Scene loaded!")
	print("You can now paint tiles in the Godot editor")
	print("Use the TileMap tool to paint your level")
	
	# Set up the camera for level design
	setup_design_camera()

func setup_design_camera():
	# Add a camera for level design
	var camera = Camera2D.new()
	camera.enabled = true
	camera.zoom = Vector2(4, 4)  # 4x zoom for 8x8 tiles
	camera.position = Vector2(0, 0)
	add_child(camera)
	
	# Make camera follow mouse for easier navigation
	# (You can implement this if needed)


