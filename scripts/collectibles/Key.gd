extends Collectible

# Key collectible

func _ready():
	value = 1
	collectible_type = "Key"
	super._ready()

func collect():
	if health_manager and health_manager.has_method("set_has_key"):
		health_manager.set_has_key(true)
	super.collect()
