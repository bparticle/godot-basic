extends Node2D

@export_group("Game Settings")
@export var initial_room: String = "room_0"  # Single source of truth for starting room
@export var respawn_delay: float = 1.0
@export var game_over_delay: float = 1.0
@export var web_game_over_screen_duration: float = 2.5
@export var game_over_texture_path: String = "res://assets/sprites/game-over.png"

@export_group("Visual Settings")
@export var debug_show_room_info: bool = false
@export var debug_show_player_info: bool = false

@onready var room_manager = get_node("/root/RoomManager")
@onready var health_manager = get_node("/root/HealthManager")
var game_over_texture: Texture2D

func _ready():
	# Connect to health manager signals
	if health_manager:
		health_manager.player_died.connect(_on_player_died)
		health_manager.game_over.connect(_on_game_over)
		health_manager.health_changed.connect(_on_health_changed)
	if game_over_texture_path != "":
		game_over_texture = load(game_over_texture_path)
	
	# Register this node as the game container
	if room_manager:
		room_manager.set_game_container(self)
		# Load the initial room
		room_manager.load_initial_room(initial_room)

func _on_player_died():
	"""Handle player death - respawn after a brief delay"""
	# Wait a moment before respawning
	await get_tree().create_timer(respawn_delay).timeout
	
	if room_manager:
		room_manager.respawn_player()

func _on_game_over():
	"""Handle game over"""
	_show_game_over_overlay()
	if OS.has_feature("web"):
		await get_tree().create_timer(web_game_over_screen_duration).timeout
		if health_manager and health_manager.has_method("send_game_over_to_host"):
			health_manager.send_game_over_to_host()
		get_tree().quit()
		return
	# Allow a short delay so the final knockback/life change is visible
	await get_tree().create_timer(game_over_delay).timeout
	# Clean up room manager so the scene is static behind the overlay
	if room_manager:
		room_manager.cleanup()

func _on_health_changed(_current_lives: int, _max_lives: int):
	"""Handle health changes - just track health, don't trigger game over here"""
	# Don't trigger game over here - let the direct game_over signal handle it
	# This prevents double-triggering of game over

func _show_game_over_overlay() -> void:
	if not game_over_texture:
		return
	var overlay = CanvasLayer.new()
	overlay.name = "GameOverOverlay"
	overlay.layer = 100
	var rect = TextureRect.new()
	rect.texture = game_over_texture
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(rect)
	add_child(overlay)

func _draw():
	"""Debug drawing for game information"""
	if not debug_show_room_info and not debug_show_player_info:
		return
	
	var y_offset = 20
	var font_size = 16
	
	if debug_show_room_info and room_manager:
		# Draw room information
		var room_info = "Room: " + str(room_manager.current_room.id if room_manager.current_room else "None")
		draw_string(ThemeDB.fallback_font, Vector2(10, y_offset), room_info, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.176471, 0.996078, 0.223529, 1))
		y_offset += 25
	
	if debug_show_player_info and health_manager:
		# Draw player health information
		var health_info = "Lives: " + str(health_manager.current_lives) + "/" + str(health_manager.max_lives)
		draw_string(ThemeDB.fallback_font, Vector2(10, y_offset), health_info, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.176471, 0.996078, 0.223529, 1))
