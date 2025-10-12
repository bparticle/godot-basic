class_name DoorOpeningState
extends State

# Door opening state - door is opening

var door: Area2D
var animated_sprite: AnimatedSprite2D
var opening_timer: float = 0.0

func enter():
	door = get_parent().get_parent()  # StateMachine -> Door
	animated_sprite = door.get_node("AnimatedSprite2D")
	
	# Start opening animation
	if animated_sprite:
		animated_sprite.play("opening")
	
	opening_timer = 0.0

func update(delta: float):
	opening_timer += delta
	
	# Check if opening is complete
	var state_machine = get_parent()
	if state_machine.has_method("open_duration"):
		if opening_timer >= state_machine.open_duration:
			transition_to("open")
