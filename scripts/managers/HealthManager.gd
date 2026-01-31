extends Node

# HealthManager - Singleton for player health/life system
# Manages lives, damage, death, and respawn

signal health_changed(current_lives: int, max_lives: int)
signal player_died()
signal game_over()
signal key_changed(has_key: bool)
signal collectibles_changed(small_count: int, large_count: int, total_score: int)

const MAX_LIVES = 3
var current_lives = MAX_LIVES
var last_spawn_position: Vector2
var last_room_id: String
var has_key: bool = false
var small_gems: int = 0
var large_gems: int = 0
var total_score: int = 0
@export var damage_cooldown_ms: int = 200
var last_damage_ms: int = -100000
@export var life_lost_stream: AudioStream
@export var life_lost_stream_path: String = "res://assets/audio/sfx/SFX 16.wav"
@export var life_lost_volume_db: float = -6.0
var life_lost_player: AudioStreamPlayer
@export var game_over_stream: AudioStream
@export var game_over_stream_path: String = "res://assets/audio/sfx/SFX 15.wav"
@export var game_over_volume_db: float = -6.0
var game_over_player: AudioStreamPlayer

func _ready():
	# Initialize with full health
	reset_health()
	life_lost_player = AudioStreamPlayer.new()
	life_lost_player.name = "LifeLostPlayer"
	life_lost_player.volume_db = life_lost_volume_db
	if life_lost_stream == null and life_lost_stream_path != "":
		life_lost_stream = load(life_lost_stream_path)
	if life_lost_stream:
		life_lost_player.stream = life_lost_stream
	add_child(life_lost_player)
	game_over_player = AudioStreamPlayer.new()
	game_over_player.name = "GameOverPlayer"
	game_over_player.volume_db = game_over_volume_db
	if game_over_stream == null and game_over_stream_path != "":
		game_over_stream = load(game_over_stream_path)
	if game_over_stream:
		game_over_player.stream = game_over_stream
	add_child(game_over_player)

func reset_health():
	"""Reset to full health (e.g., at game start)"""
	current_lives = MAX_LIVES
	health_changed.emit(current_lives, MAX_LIVES)
	reset_collectibles()
	set_has_key(false)

func take_damage(amount: int = 1):
	"""Player takes damage and loses lives"""
	if Time.get_ticks_msec() < last_damage_ms + damage_cooldown_ms:
		return
	if current_lives <= 0:
		return  # Already dead
	
	var previous_lives = current_lives
	current_lives = max(0, current_lives - amount)
	last_damage_ms = Time.get_ticks_msec()
	health_changed.emit(current_lives, MAX_LIVES)
	if current_lives < previous_lives and current_lives > 0:
		_play_life_lost_sfx()
	
	if current_lives <= 0:
		trigger_game_over()
	else:
		player_died.emit()

func take_damage_no_respawn(amount: int = 1):
	"""Player takes damage without triggering a respawn (e.g., spikes)."""
	if current_lives <= 0:
		return
	
	var previous_lives = current_lives
	current_lives = max(0, current_lives - amount)
	health_changed.emit(current_lives, MAX_LIVES)
	if current_lives < previous_lives and current_lives > 0:
		_play_life_lost_sfx()
	
	# Check if game over should be triggered
	if current_lives <= 0:
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
	_play_game_over_sfx()
	game_over.emit()

func get_current_lives() -> int:
	return current_lives

func get_max_lives() -> int:
	return MAX_LIVES

func set_has_key(value: bool) -> void:
	if has_key == value:
		return
	has_key = value
	key_changed.emit(has_key)

func get_has_key() -> bool:
	return has_key

func reset_collectibles() -> void:
	small_gems = 0
	large_gems = 0
	total_score = 0
	collectibles_changed.emit(small_gems, large_gems, total_score)

func register_collectible(collectible_type: String, value: int) -> void:
	match collectible_type:
		"Small Gem":
			small_gems += 1
		"Large Gem":
			large_gems += 1
		_:
			return
	total_score += value
	collectibles_changed.emit(small_gems, large_gems, total_score)

func get_small_gems() -> int:
	return small_gems

func get_large_gems() -> int:
	return large_gems

func get_total_score() -> int:
	return total_score

func _play_life_lost_sfx() -> void:
	if life_lost_player and life_lost_player.stream:
		life_lost_player.play()

func _play_game_over_sfx() -> void:
	if game_over_player and game_over_player.stream:
		game_over_player.play()

