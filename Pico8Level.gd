extends Node2D

# VIC-20 color palette (exact Aseprite colors)
const VIC20_COLORS = {
	"black": Color(0, 0, 0),           # 000000
	"white": Color(255, 255, 255),     # ffffff
	"brown": Color(168, 115, 74),      # a8734a
	"light_brown": Color(233, 178, 135), # e9b287
	"dark_red": Color(119, 45, 38),     # 772d26
	"light_red": Color(182, 104, 98),   # b66862
	"cyan": Color(133, 212, 220),       # 85d4dc
	"light_cyan": Color(197, 255, 255), # c5ffff
	"purple": Color(168, 95, 180),      # a85fb4
	"light_purple": Color(233, 157, 245), # e99df5
	"green": Color(85, 158, 74),        # 559e4a
	"light_green": Color(146, 223, 135), # 92df87
	"blue": Color(66, 52, 139),        # 42348b
	"light_blue": Color(126, 112, 202), # 7e70ca
	"yellow": Color(189, 204, 113),    # bdcc71
	"light_yellow": Color(255, 255, 176) # ffffb0
}

func _ready():
	create_pico8_level()

func create_pico8_level():
	# Create level using 8x8 tile grid
	# Ground level (y = 8 in 8x8 grid)
	create_8x8_tile_row(Vector2(0, 64), 20, "grass")  # 20 tiles wide
	
	# Platforms using 8x8 grid alignment
	create_8x8_tile_row(Vector2(32, 32), 4, "dirt")   # Platform at y=4
	create_8x8_tile_row(Vector2(80, 16), 3, "stone")  # Platform at y=2
	create_8x8_tile_row(Vector2(128, 0), 2, "dirt")   # Platform at y=0
	create_8x8_tile_row(Vector2(176, 24), 3, "stone") # Platform at y=3
	
	# Walls
	create_8x8_tile_column(Vector2(-8, 0), 10, "wall")  # Left wall
	create_8x8_tile_column(Vector2(160, 0), 10, "wall")  # Right wall

func create_8x8_tile_row(pos: Vector2, count: int, tile_type: String):
	# Create a row of 8x8 tiles
	for i in range(count):
		var tile_pos = Vector2(pos.x + (i * 8), pos.y)
		create_8x8_tile(tile_pos, tile_type)

func create_8x8_tile_column(pos: Vector2, count: int, tile_type: String):
	# Create a column of 8x8 tiles
	for i in range(count):
		var tile_pos = Vector2(pos.x, pos.y + (i * 8))
		create_8x8_tile(tile_pos, tile_type)

func create_8x8_tile(pos: Vector2, tile_type: String):
	var tile = StaticBody2D.new()
	tile.position = pos
	
	# Try to load 8x8 tile texture
	var tile_texture = load("res://assets/tiles/tile_" + tile_type + "_8x8.png")
	
	if tile_texture:
		create_8x8_tile_sprite(tile, tile_texture)
	else:
		# Create 8x8 fallback tile
		create_8x8_fallback_tile(tile, tile_type)
	
	# Create 8x8 collision
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(8, 8)
	collision.shape = shape
	collision.position = Vector2(0, -4)
	tile.add_child(collision)
	
	add_child(tile)

func create_8x8_tile_sprite(parent: Node2D, texture: Texture2D):
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2(4, 4)  # 4x scale: 8x8 -> 32x32
	sprite.position = Vector2(0, -4)
	parent.add_child(sprite)

func create_8x8_fallback_tile(parent: Node2D, tile_type: String):
	var image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	var color = get_tile_color(tile_type)
	
	# Fill the 8x8 tile with solid color
	for x in range(8):
		for y in range(8):
			image.set_pixel(x, y, color)
	
	# Add some simple pattern based on tile type
	match tile_type:
		"grass":
			# Add some grass texture
			for x in range(8):
				if x % 2 == 0:
					image.set_pixel(x, 0, VIC20_COLORS["light_green"])
		"dirt":
			# Add some dirt texture
			for x in range(8):
				for y in range(8):
					if (x + y) % 3 == 0:
						image.set_pixel(x, y, VIC20_COLORS["brown"])
		"stone":
			# Add some stone texture
			for x in range(8):
				for y in range(8):
					if (x + y) % 2 == 0:
						image.set_pixel(x, y, VIC20_COLORS["light_cyan"])
		"wall":
			# Add some wall texture
			for x in range(8):
				if x % 2 == 0:
					image.set_pixel(x, 0, VIC20_COLORS["light_cyan"])
					image.set_pixel(x, 7, VIC20_COLORS["light_cyan"])
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2(4, 4)
	sprite.position = Vector2(0, -4)
	parent.add_child(sprite)

func get_tile_color(tile_type: String) -> Color:
	match tile_type:
		"grass":
			return VIC20_COLORS["green"]
		"dirt":
			return VIC20_COLORS["brown"]
		"stone":
			return VIC20_COLORS["cyan"]
		"wall":
			return VIC20_COLORS["cyan"]
		_:
			return VIC20_COLORS["white"]
