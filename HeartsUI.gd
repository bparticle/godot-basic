extends Control

# HeartsUI - Visual display of player lives
# Shows red hearts for remaining lives, gray hearts for lost lives

@onready var heart_container: HBoxContainer = $HBoxContainer
@onready var health_manager = get_node("/root/HealthManager")

# Heart texture (from pixelassets.png)
var heart_texture: Texture2D

func _ready():
	# Load the hearts texture
	heart_texture = preload("res://assets/tiles/pixelassets.png")
	
	# Connect to health changes
	if health_manager:
		health_manager.health_changed.connect(_on_health_changed)
		# Initialize hearts display
		_on_health_changed(health_manager.get_current_lives(), health_manager.get_max_lives())

func _on_health_changed(current_lives: int, max_lives: int):
	"""Update the hearts display"""
	# Clear existing hearts
	for child in heart_container.get_children():
		child.queue_free()
	
	# Create heart texture rects
	for i in range(max_lives):
		var heart_rect = TextureRect.new()
		heart_rect.texture = heart_texture
		heart_rect.stretch_mode = TextureRect.STRETCH_KEEP
		heart_rect.custom_minimum_size = Vector2(8, 8)
		
		# Create AtlasTexture for the specific region
		var atlas = AtlasTexture.new()
		atlas.atlas = heart_texture
		
		# Red heart (0, 0, 8, 8) or Gray heart (8, 0, 8, 8)
		if i < current_lives:
			# Red heart - first tile
			atlas.region = Rect2(0, 0, 8, 8)
		else:
			# Gray heart - second tile
			atlas.region = Rect2(8, 0, 8, 8)
		
		heart_rect.texture = atlas
		heart_container.add_child(heart_rect)

