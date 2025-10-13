extends Node

# RNG singleton to centralize randomness and allow deterministic seeding

var _rng := RandomNumberGenerator.new()

func _ready():
	# Use time-based seed by default for variability
	randomize()

func randomize():
	_rng.randomize()

func set_seed(seed_value: int) -> void:
	_rng.seed = seed_value

func get_seed() -> int:
	return _rng.seed

func randf() -> float:
	return _rng.randf()

func randi() -> int:
	return _rng.randi()

func randf_range(from: float, to: float) -> float:
	return _rng.randf_range(from, to)

func randi_range(from: int, to: int) -> int:
	return _rng.randi_range(from, to)


