extends Node2D

func _ready():
	create_pixel_level()

func create_pixel_level():
	# Create ground with pixel art tiles
	create_tile_platform(Vector2(0, 100), Vector2(800, 32), "grass")
	
	# Create platforms with different tile types
	create_tile_platform(Vector2(200, 0), Vector2(160, 16), "dirt")
	create_tile_platform(Vector2(450, -80), Vector2(128, 16), "stone")
	create_tile_platform(Vector2(100, -160), Vector2(96, 16), "dirt")
	create_tile_platform(Vector2(600, -40), Vector2(96, 16), "stone")
	
	# Create walls
	create_tile_platform(Vector2(-50, 0), Vector2(32, 200), "wall")
	create_tile_platform(Vector2(800, 0), Vector2(32, 200), "wall")

func create_tile_platform(pos: Vector2, size: Vector2, tile_type: String):
	var platform = StaticBody2D.new()
	platform.position = pos
	
	# Try to load tile texture, fallback to colored rectangle
	var tile_texture = load("res://assets/tiles/tile_" + tile_type + ".png")
	
	if tile_texture:
		# Create tiled sprite for the platform
		create_tiled_sprite(platform, size, tile_texture)
	else:
		# Fallback: create colored rectangle based on tile type
		var color = get_tile_color(tile_type)
		create_fallback_visual(platform, size, color)
	
	# Create collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	platform.add_child(collision)
	
	add_child(platform)

func create_tiled_sprite(parent: Node2D, size: Vector2, texture: Texture2D):
	# For now, create a simple sprite
	# In a full implementation, you'd use a TileMap or create multiple sprites
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2(2, 2)  # Scale up pixel art
	sprite.position = Vector2(-size.x/2, -size.y/2)
	parent.add_child(sprite)

func create_fallback_visual(parent: Node2D, size: Vector2, color: Color):
	var visual = ColorRect.new()
	visual.size = size
	visual.position = Vector2(-size.x/2, -size.y/2)
	visual.color = color
	parent.add_child(visual)

func get_tile_color(tile_type: String) -> Color:
	match tile_type:
		"grass":
			return Color.GREEN
		"dirt":
			return Color(0.6, 0.4, 0.2)  # Brown
		"stone":
			return Color.GRAY
		"wall":
			return Color.DARK_GRAY
		_:
			return Color.WHITE


