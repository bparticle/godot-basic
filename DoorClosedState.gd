class_name DoorClosedState
extends State

# Door closed state - door is closed and can be opened

var door: Area2D
var animated_sprite: AnimatedSprite2D

func enter():
	door = get_parent().get_parent()  # StateMachine -> Door
	animated_sprite = door.get_node("AnimatedSprite2D")
	
	# Set closed animation
	if animated_sprite:
		animated_sprite.play("closed")

func update(delta: float):
	# Check for player interaction
	check_player_interaction()

func check_player_interaction():
	"""Check if player is near and wants to open the door"""
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	# Check if player is in range
	var distance = door.global_position.distance_to(player.global_position)
	if distance <= 50.0:  # Within interaction range
		# Check for interaction input (e.g., space key)
		if Input.is_action_just_pressed("ui_accept"):
			# Open the door
			var state_machine = get_parent()
			if state_machine.has_method("open_door"):
				state_machine.open_door()
