extends Control

@onready var health_manager = get_node("/root/HealthManager")
@onready var key_icon: TextureRect = $HBoxContainer/KeySlot/KeyMargin/KeyIcon
@onready var small_gem_icon: TextureRect = $HBoxContainer/SmallGemIcon
@onready var large_gem_icon: TextureRect = $HBoxContainer/LargeGemIcon
@onready var small_gem_count: Label = $HBoxContainer/SmallGemCount
@onready var large_gem_count: Label = $HBoxContainer/LargeGemCount
@onready var gun_icon: TextureRect = $HBoxContainer/GunSlot/GunMargin/GunIcon
@onready var ammo_count: Label = $HBoxContainer/AmmoCount
var icons_texture: Texture2D

func _ready():
	icons_texture = preload("res://assets/tiles/pixelassets.png")
	_setup_icons()
	
	if health_manager:
		health_manager.key_changed.connect(_on_key_changed)
		health_manager.collectibles_changed.connect(_on_collectibles_changed)
		health_manager.gun_changed.connect(_on_gun_changed)
		_on_key_changed(health_manager.get_has_key())
		_on_collectibles_changed(
			health_manager.get_small_gems(),
			health_manager.get_large_gems(),
			health_manager.get_total_score()
		)
		_on_gun_changed(health_manager.get_has_gun(), health_manager.get_ammo())

func _setup_icons() -> void:
	key_icon.texture = _make_atlas(Rect2(24, 0, 8, 8))
	small_gem_icon.texture = _make_atlas(Rect2(32, 8, 8, 8))
	large_gem_icon.texture = _make_atlas(Rect2(32, 0, 8, 8))
	gun_icon.texture = _make_atlas(Rect2(0, 8, 8, 8))
	key_icon.visible = false
	gun_icon.visible = false
	ammo_count.visible = false

func _make_atlas(region: Rect2) -> AtlasTexture:
	var atlas = AtlasTexture.new()
	atlas.atlas = icons_texture
	atlas.region = region
	return atlas

func _on_key_changed(has_key: bool) -> void:
	key_icon.visible = has_key

func _on_collectibles_changed(small_count: int, large_count: int, _total_score: int) -> void:
	small_gem_count.text = "x" + str(small_count)
	large_gem_count.text = "x" + str(large_count)

func _on_gun_changed(has_gun: bool, ammo: int) -> void:
	gun_icon.visible = has_gun
	ammo_count.visible = has_gun
	ammo_count.text = "x" + str(ammo)
