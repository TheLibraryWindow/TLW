extends Node2D

@onready var animation_player: AnimationPlayer = $Sprite2D/AnimationPlayer

const LOGIN_MENU_STREAM := preload("res://audio/startupsounds/LoginMenu/LoginMenuAtmosphere.wav")
const LOGIN_MENU_PLAYER_NAME := "LoginMenuMusicPlayer"

signal logo_finished

func _ready() -> void:
	print("[BOOTLOGO] Bootup logo started.")
	
	_play_menu_music()

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


func _play_menu_music() -> void:
	var player := _ensure_global_music_player()
	if player == null:
		push_warning("[BOOTLOGO] Could not create login music player.")
		return

	player.stream = LOGIN_MENU_STREAM
	player.volume_db = 0.0
	_enable_loop(player.stream)
	player.play()


func _ensure_global_music_player() -> AudioStreamPlayer:
	var root := get_tree().root
	var existing := root.get_node_or_null(LOGIN_MENU_PLAYER_NAME)
	if existing and existing is AudioStreamPlayer:
		return existing

	var player := AudioStreamPlayer.new()
	player.name = LOGIN_MENU_PLAYER_NAME
	player.bus = "Master"
	player.stream = LOGIN_MENU_STREAM
	_enable_loop(player.stream)
	root.add_child(player)
	return player


func _enable_loop(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif stream.has_method("set_loop"):
		stream.set_loop(true)
