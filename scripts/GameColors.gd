class_name GameColors
extends RefCounted

## Game color palette - accessible in Godot editor library
## These colors will appear in the editor's resource library

# Dark Brown - #181010
const DARK_BROWN = Color("#181010")

# Peach - #f7b58c  
const PEACH = Color("#f7b58c")

# Purple - #84739c
const PURPLE = Color("#84739c")

# Off White - #ffefff
const OFF_WHITE = Color("#ffefff")

## Get all colors as an array
static func get_all_colors() -> Array[Color]:
	return [DARK_BROWN, PEACH, PURPLE, OFF_WHITE]

## Get color by name
static func get_color_by_name(color_name: String) -> Color:
	match color_name.to_lower():
		"dark_brown", "darkbrown":
			return DARK_BROWN
		"peach":
			return PEACH
		"purple":
			return PURPLE
		"off_white", "offwhite":
			return OFF_WHITE
		_:
			push_warning("Color name '%s' not found in GameColors" % color_name)
			return Color.WHITE
