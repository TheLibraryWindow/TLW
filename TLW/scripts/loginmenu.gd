extends Node2D

@onready var anim = $AnimationPlayer
@onready var login_window = $LoginWindow
@onready var logo = $LoginscreenIcon   # was $Sprite2D, now corrected

func _ready():
	login_window.visible = true
	login_window.modulate.a = 0.0   # start invisible
	anim.play("LogoShrink")
	anim.animation_finished.connect(_on_anim_finished)

func _on_anim_finished(anim_name: String) -> void:
	if anim_name == "LogoShrink":
		anim.play("FadeLogin")
