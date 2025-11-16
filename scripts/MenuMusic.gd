extends Node

const LOGIN_TRACK := preload("res://audio/loginmenu/loginmenu.wav")

var player: AudioStreamPlayer = null
var current_stream: AudioStream = null


func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.bus = "Master"
	player.stream = LOGIN_TRACK.duplicate()
	player.autoplay = false
	player.name = "MenuMusicPlayer"
	_set_loop(player.stream)
	add_child(player)
	print("[MenuMusic] Ready — player attached.")


func play_login_music() -> void:
	if not player:
		push_warning("[MenuMusic] Player not initialized.")
		return

	if player.stream == null:
		player.stream = LOGIN_TRACK.duplicate()
		_set_loop(player.stream)

	if not player.playing:
		player.play()
		print("[MenuMusic] Playing login music.")
	else:
		print("[MenuMusic] Login music already playing.")


func stop_login_music() -> void:
	if player and player.playing:
		player.stop()
		print("[MenuMusic] Login music stopped.")


func _set_loop(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif stream.has_method("set_loop"):
		stream.set_loop(true)
