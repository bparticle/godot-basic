class_name GameColors
extends Node

## Game color palette - accessible in Godot editor library
## These colors will appear as editable swatches in the editor

# Dark colors
@export_group("Dark Colors")
@export var dark_brown: Color = Color("#181010")        # Darkest brown
@export var dark_gray: Color = Color("#3A393C")         # Dark gray
@export var dark_purple: Color = Color("#633566")       # Dark purple
@export var medium_gray: Color = Color("#4B4B4B")       # Medium gray

# Purple tones
@export_group("Purple Tones")
@export var light_purple: Color = Color("#AE8AB8")      # Light purple
@export var purple: Color = Color("#84739C")            # Main purple
@export var deep_purple: Color = Color("#614C7E")       # Deep purple

# Orange/Peach tones
@export_group("Warm Tones")
@export var orange: Color = Color("#F29155")            # Bright orange
@export var peach: Color = Color("#F7B58C")             # Peach
@export var light_peach: Color = Color("#FFD6BD")       # Light peach
@export var cream: Color = Color("#FFF2D7")            # Cream

# Light colors
@export_group("Light Colors")
@export var off_white: Color = Color("#FFEFFF")         # Off white
@export var light_gray: Color = Color("#EFEFEF")        # Light gray
@export var white: Color = Color("#FFFFFF")             # Pure white
@export var gray: Color = Color("#A9A9A9")              # Standard gray

# Legacy const access for backward compatibility
const DARK_BROWN = Color("#181010")
const DARK_GRAY = Color("#3A393C")
const DARK_PURPLE = Color("#633566")
const MEDIUM_GRAY = Color("#4B4B4B")
const LIGHT_PURPLE = Color("#AE8AB8")
const PURPLE = Color("#84739C")
const DEEP_PURPLE = Color("#614C7E")
const ORANGE = Color("#F29155")
const PEACH = Color("#F7B58C")
const LIGHT_PEACH = Color("#FFD6BD")
const CREAM = Color("#FFF2D7")
const OFF_WHITE = Color("#FFEFFF")
const LIGHT_GRAY = Color("#EFEFEF")
const WHITE = Color("#FFFFFF")
const GRAY = Color("#A9A9A9")

## Get all colors as an array
static func get_all_colors() -> Array[Color]:
	return [
		DARK_BROWN, OFF_WHITE, LIGHT_PURPLE, PURPLE, DARK_GRAY,
		DEEP_PURPLE, ORANGE, PEACH, LIGHT_PEACH, CREAM,
		LIGHT_GRAY, WHITE, GRAY, MEDIUM_GRAY, DARK_PURPLE
	]

## Get color by name
static func get_color_by_name(color_name: String) -> Color:
	match color_name.to_lower():
		"dark_brown", "darkbrown":
			return DARK_BROWN
		"off_white", "offwhite":
			return OFF_WHITE
		"light_purple", "lightpurple":
			return LIGHT_PURPLE
		"purple":
			return PURPLE
		"dark_gray", "darkgray":
			return DARK_GRAY
		"deep_purple", "deeppurple":
			return DEEP_PURPLE
		"orange":
			return ORANGE
		"peach":
			return PEACH
		"light_peach", "lightpeach":
			return LIGHT_PEACH
		"cream":
			return CREAM
		"light_gray", "lightgray":
			return LIGHT_GRAY
		"white":
			return WHITE
		"gray":
			return GRAY
		"medium_gray", "mediumgray":
			return MEDIUM_GRAY
		"dark_purple", "darkpurple":
			return DARK_PURPLE
		_:
			push_warning("Color name '%s' not found in GameColors" % color_name)
			return Color.WHITE

## Get colors by category
static func get_dark_colors() -> Array[Color]:
	return [DARK_BROWN, DARK_GRAY, DARK_PURPLE, MEDIUM_GRAY]

static func get_purple_tones() -> Array[Color]:
	return [LIGHT_PURPLE, PURPLE, DEEP_PURPLE, DARK_PURPLE]

static func get_warm_tones() -> Array[Color]:
	return [ORANGE, PEACH, LIGHT_PEACH, CREAM]

static func get_light_colors() -> Array[Color]:
	return [OFF_WHITE, LIGHT_GRAY, WHITE, CREAM]
