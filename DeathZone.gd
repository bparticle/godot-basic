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
	
	# Check if the body is the player
	if body.is_in_group("player"):
		# Player takes damage
		if health_manager:
			health_manager.take_damage(1)

