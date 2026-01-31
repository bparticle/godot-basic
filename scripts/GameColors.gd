class_name GameColors
extends Node

## Game color palette - accessible in Godot editor library
## These colors will appear as editable swatches in the editor

# Dark colors
@export_group("Dark Colors")
@export var dark_brown: Color = Color("#1A1A1A")        # Darkest background
@export var dark_gray: Color = Color("#1A1A1A")         # Dark background
@export var dark_purple: Color = Color("#1A1A1A")       # Dark background
@export var medium_gray: Color = Color("#1A1A1A")       # Medium background

# Purple tones
@export_group("Purple Tones")
@export var light_purple: Color = Color("#2DFE39")      # Accent green
@export var purple: Color = Color("#2DFE39")            # Main green
@export var deep_purple: Color = Color("#2DFE39")       # Deep green

# Orange/Peach tones
@export_group("Warm Tones")
@export var orange: Color = Color("#2DFE39")            # Accent green
@export var peach: Color = Color("#2DFE39")             # Accent green
@export var light_peach: Color = Color("#2DFE39")       # Accent green
@export var cream: Color = Color("#2DFE39")            # Accent green

# Light colors
@export_group("Light Colors")
@export var off_white: Color = Color("#2DFE39")         # Bright green
@export var light_gray: Color = Color("#2DFE39")        # Bright green
@export var white: Color = Color("#2DFE39")             # Bright green
@export var gray: Color = Color("#2DFE39")              # Bright green

# Legacy const access for backward compatibility
const DARK_BROWN = Color("#1A1A1A")
const DARK_GRAY = Color("#1A1A1A")
const DARK_PURPLE = Color("#1A1A1A")
const MEDIUM_GRAY = Color("#1A1A1A")
const LIGHT_PURPLE = Color("#2DFE39")
const PURPLE = Color("#2DFE39")
const DEEP_PURPLE = Color("#2DFE39")
const ORANGE = Color("#2DFE39")
const PEACH = Color("#2DFE39")
const LIGHT_PEACH = Color("#2DFE39")
const CREAM = Color("#2DFE39")
const OFF_WHITE = Color("#2DFE39")
const LIGHT_GRAY = Color("#2DFE39")
const WHITE = Color("#2DFE39")
const GRAY = Color("#2DFE39")

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
