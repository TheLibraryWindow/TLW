extends Node

const LOGIN_TRACK := preload("res://audio/startupsounds/LoginMenu/loginmenu.wav")

var player: AudioStreamPlayer


func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.bus = "Master"
	player.stream = LOGIN_TRACK.duplicate()
	_enable_loop(player.stream)
	player.autoplay = false
	add_child(player)
	print("[MenuMusic] Ready — player node added. Stream path:", LOGIN_TRACK.resource_path)


func play_login_music(volume_db: float = 0.0) -> void:
	if not player:
		push_warning("[MenuMusic] Player not initialized.")
		return

	if player.stream == null:
		player.stream = LOGIN_TRACK.duplicate()
		_enable_loop(player.stream)

	player.volume_db = volume_db
	var playback := player.get_stream_playback()
	print("[MenuMusic] play_login_music → in_tree:", player.is_inside_tree(), "playing:", player.playing, "playback:", playback)
	if not player.playing:
		player.play()
		print("[MenuMusic] Playback started.")
	else:
		print("[MenuMusic] Already playing.")


func stop_login_music() -> void:
	if player and player.playing:
		player.stop()
		print("[MenuMusic] Playback stopped.")
	else:
		print("[MenuMusic] stop_login_music called but player missing or idle.")


func _enable_loop(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif stream.has_method("set_loop"):
		stream.set_loop(true)
