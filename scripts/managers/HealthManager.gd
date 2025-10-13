extends Node

# HealthManager - Singleton for player health/life system
# Manages lives, damage, death, and respawn

signal health_changed(current_lives: int, max_lives: int)
signal player_died()
signal game_over()

const MAX_LIVES = 3
var current_lives = MAX_LIVES
var last_spawn_position: Vector2
var last_room_id: String

func _ready():
	# Initialize with full health
	reset_health()

func reset_health():
	"""Reset to full health (e.g., at game start)"""
	current_lives = MAX_LIVES
	health_changed.emit(current_lives, MAX_LIVES)

func take_damage(amount: int = 1):
	"""Player takes damage and loses lives"""
	if current_lives <= 0:
		return  # Already dead
	
	current_lives = max(0, current_lives - amount)
	print("HealthManager: Player took damage, lives now: ", current_lives)
	health_changed.emit(current_lives, MAX_LIVES)
	
	if current_lives <= 0:
		print("HealthManager: Lives reached 0, triggering game over")
		trigger_game_over()
	else:
		print("HealthManager: Player died, respawning")
		player_died.emit()

func take_damage_no_respawn(amount: int = 1):
	"""Player takes damage without triggering a respawn (e.g., spikes)."""
	if current_lives <= 0:
		return
	
	current_lives = max(0, current_lives - amount)
	print("HealthManager: Player took damage (no respawn), lives now: ", current_lives)
	health_changed.emit(current_lives, MAX_LIVES)
	
	# Check if game over should be triggered
	if current_lives <= 0:
		print("HealthManager: Lives reached 0 (no respawn), triggering game over")
		trigger_game_over()

func heal(amount: int = 1):
	"""Restore lives (for pickups, etc.)"""
	current_lives = min(MAX_LIVES, current_lives + amount)
	health_changed.emit(current_lives, MAX_LIVES)

func update_spawn_point(position: Vector2, room_id: String):
	"""Update the last known spawn point"""
	last_spawn_position = position
	last_room_id = room_id

func get_last_spawn_position() -> Vector2:
	return last_spawn_position

func get_last_room_id() -> String:
	return last_room_id

func trigger_game_over():
	"""Trigger game over state"""
	print("HealthManager: trigger_game_over() called, emitting game_over signal")
	game_over.emit()

func get_current_lives() -> int:
	return current_lives

func get_max_lives() -> int:
	return MAX_LIVES

