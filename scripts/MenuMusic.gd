extends Node

const LOGIN_TRACK := preload("res://audio/startupsounds/LoginMenu/LoginMenuAtmosphere.wav")

var player: AudioStreamPlayer


func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.bus = "Master"
	player.stream = LOGIN_TRACK.duplicate()
	_enable_loop(player.stream)
	player.autoplay = false
	add_child(player)
	print("[MenuMusic] Ready — player node added.")


func play_login_music(volume_db: float = 0.0) -> void:
	if not player:
		push_warning("[MenuMusic] Player not initialized.")
		return

	if player.stream == null:
		player.stream = LOGIN_TRACK.duplicate()
		_enable_loop(player.stream)

	player.volume_db = volume_db
	if not player.playing:
		player.play()


func stop_login_music() -> void:
	if player and player.playing:
		player.stop()


func _enable_loop(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif stream.has_method("set_loop"):
		stream.set_loop(true)
