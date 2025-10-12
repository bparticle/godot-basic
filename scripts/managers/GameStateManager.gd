extends Node

# Game state manager - manages overall game states
# Singleton for managing game-wide states

signal game_state_changed(new_state: String)

enum GameState {
	PLAYING,
	PAUSED,
	GAME_OVER,
	MENU
}

var current_state: GameState = GameState.PLAYING

func _ready():
	# Set as singleton
	set_process_input(true)

func _input(event):
	# Handle pause input
	if event.is_action_pressed("ui_cancel"):  # Escape key
		if current_state == GameState.PLAYING:
			pause_game()
		elif current_state == GameState.PAUSED:
			resume_game()

func pause_game():
	"""Pause the game"""
	current_state = GameState.PAUSED
	get_tree().paused = true
	game_state_changed.emit("paused")

func resume_game():
	"""Resume the game"""
	current_state = GameState.PLAYING
	get_tree().paused = false
	game_state_changed.emit("playing")

func game_over():
	"""Trigger game over state"""
	current_state = GameState.GAME_OVER
	game_state_changed.emit("game_over")

func is_playing() -> bool:
	return current_state == GameState.PLAYING

func is_paused() -> bool:
	return current_state == GameState.PAUSED

func is_game_over() -> bool:
	return current_state == GameState.GAME_OVER
