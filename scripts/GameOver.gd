extends Control

# GameOver screen

@onready var health_manager = get_node("/root/HealthManager")

func _ready():
	print("GameOver scene loaded successfully")
	print("HealthManager found: ", health_manager != null)

func _on_restart_pressed():
	"""Restart the game"""
	print("Restart button pressed!")
	if health_manager:
		health_manager.reset_health()
		print("Health reset successfully")
	# Use call_deferred to safely change scenes
	get_tree().call_deferred("change_scene_to_file", "res://scenes/Game.tscn")
	print("Scene change requested")

func _on_quit_pressed():
	"""Quit the game"""
	print("Quit button pressed!")
	get_tree().quit()
