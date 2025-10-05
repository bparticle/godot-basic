extends Node2D

# Debug Level - Simple test to see if tiles are working

func _ready():
	print("=== Debug Level ===")
	
	# Check TileMapLayer
	var tilemap = get_node("TileMapLayer")
	if tilemap:
		print("✅ TileMapLayer found")
		print("TileSet: ", tilemap.tile_set)
		if tilemap.tile_set:
			print("TileSet sources: ", tilemap.tile_set.get_source_count())
			# Try to add a test tile programmatically
			add_test_tile()
		else:
			print("❌ No TileSet assigned!")
	else:
		print("❌ TileMapLayer not found!")
	
	# Check player
	var player = get_node("Player")
	if player:
		print("✅ Player found at position: ", player.position)
		# Add a simple visual for the player
		create_player_visual()
	else:
		print("❌ Player not found!")

func add_test_tile():
	# Try to add a tile programmatically to test
	var tilemap = get_node("TileMapLayer")
	if tilemap and tilemap.tile_set:
		# Set a tile at position (0, 0)
		tilemap.set_cell(Vector2i(0, 0), 0, Vector2i(0, 0))
		print("✅ Test tile added at (0, 0)")

func create_player_visual():
	# Create a simple visual for the player
	var player = get_node("Player")
	var sprite = player.get_node("Sprite2D")
	
	# Create a simple colored rectangle
	var image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	# Fill with blue color
	for x in range(8):
		for y in range(8):
			image.set_pixel(x, y, Color.BLUE)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite.texture = texture
	sprite.scale = Vector2(4, 4)  # 4x scale
	sprite.position = Vector2(0, -4)
	
	print("✅ Player visual created")


