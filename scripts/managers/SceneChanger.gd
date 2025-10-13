extends CanvasLayer

# Simple fade-based scene changer singleton

@export var fade_color: Color = Color.BLACK
@export var fade_duration: float = 0.25

var _rect: ColorRect
var _anim: AnimationPlayer

func _ready():
	layer = 100
	_rect = ColorRect.new()
	_rect.color = Color(fade_color.r, fade_color.g, fade_color.b, 0.0)
	_rect.size = get_viewport().get_visible_rect().size
	add_child(_rect)

	get_viewport().size_changed.connect(func():
		_rect.size = get_viewport().get_visible_rect().size
	)

	_anim = AnimationPlayer.new()
	add_child(_anim)
	_create_fade_animation()

func _create_fade_animation():
	var library := AnimationLibrary.new()
	
	var anim := Animation.new()
	anim.length = fade_duration
	anim.track_set_path(anim.add_track(Animation.TYPE_VALUE), str(_rect.get_path_to(_rect)) + ":color:a")
	anim.track_insert_key(0, 0.0, 0.0)
	anim.track_insert_key(0, fade_duration, 1.0)
	library.add_animation("fade_in", anim)

	var anim_out := Animation.new()
	anim_out.length = fade_duration
	anim_out.track_set_path(anim_out.add_track(Animation.TYPE_VALUE), str(_rect.get_path_to(_rect)) + ":color:a")
	anim_out.track_insert_key(0, 0.0, 1.0)
	anim_out.track_insert_key(0, fade_duration, 0.0)
	library.add_animation("fade_out", anim_out)
	
	_anim.add_animation_library("", library)

func change_scene_to_file(path: String) -> void:
	_anim.play("fade_in")
	await _anim.animation_finished
	get_tree().call_deferred("change_scene_to_file", path)
	await get_tree().process_frame
	_anim.play("fade_out")
	await _anim.animation_finished
