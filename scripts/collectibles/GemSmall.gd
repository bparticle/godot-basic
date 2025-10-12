extends Area2D

# Small gem collectible
@export var value: int = 5
@export var collectible_type: String = "small_gem"

var is_collected: bool = false

func _ready():
	# Connect to body entered signal
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player") and not is_collected:
		collect()

func collect():
	if is_collected:
		return
	
	is_collected = true
	print("Collected small gem worth ", value, " points")
	
	# Play collection animation or effect here
	# For now, just remove the collectible
	queue_free()
