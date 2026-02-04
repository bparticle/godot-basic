extends Area2D
class_name Collectible

# Simple collectible item base class
@export var value: int = 1
@export var collectible_type: String = "gem"
@export var hover_height: float = 1.0  # How high the gem hovers
@export var hover_speed: float = 4.0   # Speed of the hover animation

var is_collected: bool = false
var original_y: float
var tween: Tween
@onready var pickup_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var pickup_sprite: Sprite2D = $Sprite2D
@onready var pickup_collision: CollisionShape2D = $CollisionShape2D
@onready var health_manager = get_node("/root/HealthManager")

func _ready():
	add_to_group("collectible")
	# Store original Y position
	original_y = global_position.y
	
	# Connect to body entered signal
	body_entered.connect(_on_body_entered)
	
	# Start the hover animation
	start_hover_animation()

func _on_body_entered(body):
	if body.is_in_group("player") and not is_collected:
		collect()

func start_hover_animation():
	# Create a tween for smooth floating animation
	tween = create_tween()
	tween.set_loops()  # Loop infinitely
	
	# Animate Y position up and down in sequence
	tween.tween_property(self, "global_position:y", original_y - hover_height, 1.0 / hover_speed)
	tween.tween_property(self, "global_position:y", original_y + hover_height, 1.0 / hover_speed)
	tween.tween_property(self, "global_position:y", original_y, 1.0 / hover_speed)

func collect():
	if is_collected:
		return
	
	is_collected = true
	
	if health_manager and health_manager.has_method("register_collectible"):
		health_manager.register_collectible(collectible_type, value)
	
	# Stop the hover animation
	if tween:
		tween.kill()
	
	# Play pickup sound, then remove the collectible
	if pickup_player and pickup_player.stream:
		if pickup_sprite:
			pickup_sprite.visible = false
		if pickup_collision:
			pickup_collision.set_deferred("disabled", true)
		set_deferred("monitoring", false)
		pickup_player.play()
		await pickup_player.finished
	queue_free()
