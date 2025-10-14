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

func _ready():
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
	
	# Stop the hover animation
	if tween:
		tween.kill()
	
	# Play collection animation or effect here
	# For now, just remove the collectible
	queue_free()
