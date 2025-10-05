extends Node2D

func _ready():
	create_level_geometry()

func create_level_geometry():
	# Create ground
	create_platform(Vector2(0, 100), Vector2(800, 50), Color.GREEN)
	
	# Create some platforms
	create_platform(Vector2(200, 0), Vector2(150, 20), Color.BROWN)
	create_platform(Vector2(450, -80), Vector2(120, 20), Color.BROWN)
	create_platform(Vector2(100, -160), Vector2(100, 20), Color.BROWN)
	create_platform(Vector2(600, -40), Vector2(100, 20), Color.BROWN)
	
	# Create walls on the sides
	create_platform(Vector2(-50, 0), Vector2(50, 200), Color.GRAY)
	create_platform(Vector2(800, 0), Vector2(50, 200), Color.GRAY)

func create_platform(pos: Vector2, size: Vector2, color: Color):
	# Create a StaticBody2D for the platform
	var platform = StaticBody2D.new()
	platform.position = pos
	
	# Create visual representation
	var visual = ColorRect.new()
	visual.size = size
	visual.position = Vector2(-size.x/2, -size.y/2)  # Center the rectangle
	visual.color = color
	platform.add_child(visual)
	
	# Create collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	platform.add_child(collision)
	
	add_child(platform)


