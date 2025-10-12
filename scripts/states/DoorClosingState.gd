class_name DoorClosingState
extends State

# Door closing state - door is closing

var door: Area2D
var animated_sprite: AnimatedSprite2D
var closing_timer: float = 0.0

func enter():
	door = get_parent().get_parent()  # StateMachine -> Door
	animated_sprite = door.get_node("AnimatedSprite2D")
	
	# Start closing animation
	if animated_sprite:
		animated_sprite.play("closing")
	
	closing_timer = 0.0

func update(delta: float):
	closing_timer += delta
	
	# Check if closing is complete
	var state_machine = get_parent()
	if state_machine.has_method("close_duration"):
		if closing_timer >= state_machine.close_duration:
			transition_to("closed")
