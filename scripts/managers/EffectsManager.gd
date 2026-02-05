extends Node

## Global effects manager for screen-wide effects like hit stop.
## Add as autoload: EffectsManager

# Hit stop state
var _hit_stop_active: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # Process even when paused

## Freeze the game briefly for impact feel
## duration: how long to freeze in seconds (0.03-0.1 typical)
func hit_stop(duration: float = 0.05) -> void:
	if _hit_stop_active:
		return  # Don't stack hit stops
	
	_hit_stop_active = true
	Engine.time_scale = 0.0
	
	# Use a timer that ignores time scale
	await get_tree().create_timer(duration, true, false, true).timeout
	
	Engine.time_scale = 1.0
	_hit_stop_active = false

## Screen shake disabled - was too distracting for this game style
func shake(_intensity: float = 4.0) -> void:
	pass  # Disabled

## Combined effect for impactful moments (hit stop only, no shake)
func impact(hit_stop_duration: float = 0.04, _shake_intensity: float = 3.0) -> void:
	hit_stop(hit_stop_duration)

## Register camera (kept for compatibility)
func register_camera(_cam: Camera2D) -> void:
	pass
