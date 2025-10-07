extends Control

# GameOver screen

@onready var health_manager = get_node("/root/HealthManager")

func _ready():
	print("GameOver screen loaded")

func _on_restart_pressed():
	"""Restart the game"""
	print("Restart button pressed!")
	if health_manager:
		health_manager.reset_health()
		print("Health reset to: ", health_manager.get_current_lives())
	# Use call_deferred to safely change scenes
	get_tree().call_deferred("change_scene_to_file", "res://Game.tscn")

func _on_quit_pressed():
	"""Quit the game"""
	print("Quit button pressed!")
	get_tree().quit()
