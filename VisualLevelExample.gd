extends Node2D

# This script shows how to mix code and visual editor
# You can place TileMap nodes in the editor and control them with code

func _ready():
	# Find any TileMap nodes that were placed in the editor
	var tilemaps = find_children("*", "TileMap2D", true, false)
	
	for tilemap in tilemaps:
		print("Found TileMap: ", tilemap.name)
		# You can modify tilemaps programmatically here
		# tilemap.set_cell(0, Vector2i(5, 5), 0, Vector2i(0, 0))

func add_platform_at_position(pos: Vector2, size: Vector2):
	# This function can be called to add platforms programmatically
	# even when using visual editor
	var platform = StaticBody2D.new()
	platform.position = pos
	
	# Create visual
	var sprite = Sprite2D.new()
	# Try to load tile texture
	var texture = load("res://assets/tiles/tile_grass.png")
	if texture:
		sprite.texture = texture
		sprite.scale = Vector2(2, 2)
	else:
		# Fallback
		var rect = ColorRect.new()
		rect.size = size
		rect.color = Color.GREEN
		sprite.add_child(rect)
	
	platform.add_child(sprite)
	
	# Create collision
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	platform.add_child(collision)
	
	add_child(platform)


