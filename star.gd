@tool
class_name Star
extends Area2D

@export var texture: SpriteFrames = _initial_texture:
	set = _set_texture
@export var tint: Color = Color.WHITE:
	set = _set_tint

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _initial_texture: SpriteFrames = $AnimatedSprite2D.sprite_frames

func _set_texture(new_texture: SpriteFrames):
	texture = new_texture
	
	if not is_node_ready():
		return


	if texture != null:
		_sprite.sprite_frames = texture
	else:
		_sprite.sprite_frames = _initial_texture
	notify_property_list_changed()

func _set_tint(new_tint: Color):
	tint = new_tint
	if is_node_ready():
		modulate = tint

func _ready():
	_set_texture(texture)
	_set_tint(tint)


func _on_body_entered(body: Node2D) -> void:
	Global.collect_star()
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	queue_free()
