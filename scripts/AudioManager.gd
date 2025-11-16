extends Node

@onready var player: AudioStreamPlayer2D = $Player


func play_track(
		stream: AudioStream,
		from_position: float = 0.0,
		volume_db: float = 0.0,
		loop_enabled: bool = true
) -> void:
	if not player:
		push_warning("[AudioManager] Player node missing.")
		return

	if stream == null:
		push_warning("[AudioManager] Cannot play null stream.")
		return

	player.stop()
	player.stream = stream
	_apply_loop_setting(stream, loop_enabled)
	player.volume_db = volume_db
	player.play(from_position)


func stop_track() -> void:
	if player:
		player.stop()


func _apply_loop_setting(stream: AudioStream, loop_enabled: bool) -> void:
	if stream is AudioStreamWAV:
		var wav_stream := stream as AudioStreamWAV
		wav_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop_enabled else AudioStreamWAV.LOOP_DISABLED
	elif stream.has_method("set_loop"):
		stream.set_loop(loop_enabled)
	elif stream.has_method("set_looping"):
		stream.set_looping(loop_enabled)
	elif stream.has_method("set_loop_mode"):
		stream.set_loop_mode(
			AudioStreamSample.LOOP_FORWARD if loop_enabled else AudioStreamSample.LOOP_DISABLED
		)
	else:
		push_warning("[AudioManager] Stream type does not expose loop controls.")
