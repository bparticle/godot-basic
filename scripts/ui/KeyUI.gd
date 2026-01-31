extends Control

# KeyUI - Visual display of key possession

@onready var key_icon: TextureRect = $KeyIcon
@onready var health_manager = get_node("/root/HealthManager")

var key_texture: Texture2D

func _ready():
	key_texture = preload("res://assets/tiles/pixelassets.png")
	var atlas = AtlasTexture.new()
	atlas.atlas = key_texture
	atlas.region = Rect2(24, 0, 8, 8)
	key_icon.texture = atlas
	key_icon.visible = false

	if health_manager:
		health_manager.key_changed.connect(_on_key_changed)
		_on_key_changed(health_manager.get_has_key())

func _on_key_changed(has_key: bool) -> void:
	key_icon.visible = has_key
