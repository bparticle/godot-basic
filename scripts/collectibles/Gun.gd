extends Collectible

# Gun collectible - gives player the gun with 20 bullets

func _ready():
	value = 1
	collectible_type = "Gun"
	super._ready()

func collect():
	if is_collected:
		return
	
	# Give the player the gun with 20 bullets
	if health_manager and health_manager.has_method("set_has_gun"):
		health_manager.set_has_gun(true, 10)
	
	super.collect()
