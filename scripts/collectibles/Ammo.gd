extends Collectible

# Ammo collectible - adds bullets to the player's gun

@export var bullet_count: int = 5  # How many bullets this pickup gives

func _ready():
	value = 1
	collectible_type = "Ammo"
	super._ready()

func collect():
	if is_collected:
		return
	
	# Only collect if player has a gun
	if health_manager and health_manager.has_method("get_has_gun"):
		if not health_manager.get_has_gun():
			return  # Can't pick up ammo without a gun
	
	# Don't collect if ammo is already full
	if health_manager and health_manager.has_method("is_ammo_full"):
		if health_manager.is_ammo_full():
			return  # Already at max ammo
	
	# Add ammo to the player's gun (returns false if at max)
	if health_manager and health_manager.has_method("add_ammo"):
		if not health_manager.add_ammo(bullet_count):
			return  # Failed to add ammo
	
	super.collect()
