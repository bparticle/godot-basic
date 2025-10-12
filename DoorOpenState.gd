class_name DoorOpenState
extends State

# Door open state - door is open and can be closed

var door: Area2D
var animated_sprite: AnimatedSprite2D

func enter():
	door = get_parent().get_parent()  # StateMachine -> Door
	animated_sprite = door.get_node("AnimatedSprite2D")
	
	# Set open animation
	if animated_sprite:
		animated_sprite.play("open")

func update(delta: float):
	# Check for player interaction
	check_player_interaction()

func check_player_interaction():
	"""Check if player is near and wants to close the door"""
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	# Check if player is in range
	var distance = door.global_position.distance_to(player.global_position)
	if distance <= 50.0:  # Within interaction range
		# Check for interaction input (e.g., space key)
		if Input.is_action_just_pressed("ui_accept"):
			# Close the door
			var state_machine = get_parent()
			if state_machine.has_method("close_door"):
				state_machine.close_door()
