extends Node2D

@onready var animation_player: AnimationPlayer = $Sprite2D/AnimationPlayer

signal logo_finished

func _ready() -> void:
	print("[BOOTLOGO] Bootup logo started.")
	_start_login_music()
	
	if animation_player and animation_player.has_animation("bootuplogo"):
		animation_player.play("bootuplogo")
		# Connect only once
		if not animation_player.animation_finished.is_connected(_on_animation_finished):
			animation_player.animation_finished.connect(_on_animation_finished)
	else:
		print("[BOOTLOGO] No animation found, skipping.")
		emit_signal("logo_finished")


func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "bootuplogo":
		print("[BOOTLOGO] Animation complete — loading next scene.")
		emit_signal("logo_finished")
		get_tree().change_scene_to_file("res://scenes/loginmenu.tscn")


func _start_login_music() -> void:
	var music := _get_menu_music()
	if music and music.has_method("play_login_music"):
		music.play_login_music()
	else:
		push_warning("[BOOTLOGO] MenuMusic singleton not available; login music will not start.")


func _get_menu_music() -> Node:
	return get_tree().root.get_node_or_null("MenuMusic")
