extends Control

# GameOver screen

@onready var health_manager = get_node("/root/HealthManager")

func _ready():
	pass

func _on_restart_pressed():
	"""Restart the game"""
	if health_manager:
		health_manager.reset_health()
	# Use call_deferred to safely change scenes
	get_tree().call_deferred("change_scene_to_file", "res://scenes/Game.tscn")

func _on_quit_pressed():
	"""Quit the game"""
	if health_manager and health_manager.has_method("send_current_collectibles_to_host"):
		health_manager.send_current_collectibles_to_host()
	get_tree().quit()
