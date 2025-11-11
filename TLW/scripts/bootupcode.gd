extends Node2D

@onready var anim = $main/AnimationPlayer

func _ready():
	anim.play("bootupcode")
	anim.connect("animation_finished", Callable(self, "_on_animation_finished"))

func _on_animation_finished(anim_name):
	if anim_name == "bootupcode":
		get_tree().change_scene_to_file("res://scenes/bootuplogo.tscn")
