extends Node

# VIC-20 Color Palette (exact Aseprite colors)
const VIC20_PALETTE = {
	0: Color(0, 0, 0),           # 000000 - black
	1: Color(255, 255, 255),     # ffffff - white
	2: Color(168, 115, 74),      # a8734a - brown
	3: Color(233, 178, 135),     # e9b287 - light brown
	4: Color(119, 45, 38),       # 772d26 - dark red
	5: Color(182, 104, 98),      # b66862 - light red
	6: Color(133, 212, 220),     # 85d4dc - cyan
	7: Color(197, 255, 255),     # c5ffff - light cyan
	8: Color(168, 95, 180),      # a85fb4 - purple
	9: Color(233, 157, 245),     # e99df5 - light purple
	10: Color(85, 158, 74),      # 559e4a - green
	11: Color(146, 223, 135),    # 92df87 - light green
	12: Color(66, 52, 139),      # 42348b - blue
	13: Color(126, 112, 202),    # 7e70ca - light blue
	14: Color(189, 204, 113),   # bdcc71 - yellow
	15: Color(255, 255, 176)     # ffffb0 - light yellow
}

# Named color constants for easier use
const BLACK = 0
const WHITE = 1
const BROWN = 2
const LIGHT_BROWN = 3
const DARK_RED = 4
const LIGHT_RED = 5
const CYAN = 6
const LIGHT_CYAN = 7
const PURPLE = 8
const LIGHT_PURPLE = 9
const GREEN = 10
const LIGHT_GREEN = 11
const BLUE = 12
const LIGHT_BLUE = 13
const YELLOW = 14
const LIGHT_YELLOW = 15

static func get_color(index: int) -> Color:
	return VIC20_PALETTE.get(index, VIC20_PALETTE[0])

static func create_8x8_sprite(color_index: int) -> ImageTexture:
	var image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	var color = get_color(color_index)
	
	# Fill the 8x8 image with the color
	for x in range(8):
		for y in range(8):
			image.set_pixel(x, y, color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

static func create_8x8_pattern(pattern_data: Array, colors: Array) -> ImageTexture:
	# Create 8x8 sprite from pattern data
	# pattern_data: Array of 8 strings, each with 8 characters
	# colors: Array of color indices for each character
	var image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	
	for y in range(8):
		var row = pattern_data[y]
		for x in range(8):
			var char = row[x]
			var color_index = colors.find(char)
			if color_index != -1:
				image.set_pixel(x, y, get_color(color_index))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture
