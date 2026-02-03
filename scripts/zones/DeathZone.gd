extends Area2D

# DeathZone - Area that causes player to lose a life on contact
# Typically used for pits, hazards, or out-of-bounds areas

@onready var health_manager = get_node("/root/HealthManager")
@export var activation_delay: float = 0.3
var is_active = false

func _ready():
	# Connect to body entered signal
	body_entered.connect(_on_body_entered)
	
	# Delay activation to prevent triggering on spawn
	await get_tree().create_timer(activation_delay).timeout
	is_active = true

func _on_body_entered(body):
	# Only trigger if active
	if not is_active:
		return
	
	# Check if the body is the player - fell out of level (pit, etc.): respawn at checkpoint
	if body.is_in_group("player"):
		if health_manager and health_manager.has_method("request_respawn_from_fall"):
			health_manager.request_respawn_from_fall()
