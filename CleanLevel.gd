extends Node2D

# Clean Level Scene - No programmatic level creation
# This scene is purely for visual level design with TileMapLayer

func _ready():
	print("Clean Level Scene loaded!")
	print("You can now paint tiles without conflicts")
	
	# Set up camera for level design
	setup_design_camera()

func setup_design_camera():
	# Add a camera for level design
	var camera = Camera2D.new()
	camera.enabled = true
	camera.zoom = Vector2(4, 4)  # 4x zoom for 8x8 tiles
	camera.position = Vector2(0, 0)
	add_child(camera)
	
	print("Camera set up for level design")


