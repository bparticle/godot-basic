extends Node2D

# Playable Level - Combines painted tiles with player character
# This scene lets you test your level design with the player

func _ready():
	print("=== Playable Level Loaded ===")
	print("You can now test your level with the player!")
	
	# Set up camera to follow player
	setup_game_camera()

func setup_game_camera():
	# Get the player node
	var player = get_node("Player")
	if player:
		# Create camera
		var camera = Camera2D.new()
		camera.enabled = true
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 5.0
		camera.zoom = Vector2(4, 4)  # 4x zoom for 8x8 tiles
		
		# Set camera limits (adjust based on your level size)
		camera.limit_left = -200
		camera.limit_right = 1000
		camera.limit_top = -400
		camera.limit_bottom = 400
		
		# Attach camera to player
		player.add_child(camera)
		print("✅ Camera set up to follow player")
		
		# Make camera current
		camera.make_current()
		print("✅ Camera made current")
	else:
		print("❌ Player node not found!")
		
	# Also check the TileMapLayer
	var tilemap = get_node("TileMapLayer")
	if tilemap:
		print("✅ TileMapLayer found")
		print("TileSet assigned: ", tilemap.tile_set != null)
		if tilemap.tile_set:
			print("TileSet sources: ", tilemap.tile_set.get_source_count())
	else:
		print("❌ TileMapLayer not found!")

func _input(event):
	# Quick level design shortcuts
	if event.is_action_pressed("ui_cancel"):  # ESC key
		print("ESC pressed - returning to level design")
		# You can add code here to switch back to level design mode
