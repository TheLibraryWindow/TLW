extends Node

@onready var player: AudioStreamPlayer2D = $Player

var current_track: AudioStream = null
var current_track_path: String = ""
var volume_tween: Tween = null


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
	current_track = stream
	current_track_path = stream.resource_path
	_apply_loop_setting(stream, loop_enabled)
	player.volume_db = volume_db
	player.play(from_position)


func play_track_from_path(
		path: String,
		from_position: float = 0.0,
		volume_db: float = 0.0,
		loop_enabled: bool = true
) -> void:
	var stream := ResourceLoader.load(path)
	if stream is AudioStream:
		current_track_path = path
		play_track(stream, from_position, volume_db, loop_enabled)
	else:
		push_warning("[AudioManager] Failed to load stream at path: %s" % path)


func is_playing_path(path: String) -> bool:
	return player and player.playing and current_track_path == path


func fade_volume_to(
		target_db: float,
		duration: float,
		trans: int = Tween.TRANS_SINE,
		ease: int = Tween.EASE_IN_OUT
) -> void:
	if not player:
		return
	if volume_tween:
		volume_tween.kill()
	volume_tween = create_tween()
	volume_tween.tween_property(player, "volume_db", target_db, duration).set_trans(trans).set_ease(ease)


func stop_track() -> void:
	if player:
		player.stop()
		current_track = null
		current_track_path = ""


func _apply_loop_setting(stream: AudioStream, loop_enabled: bool) -> void:
	if stream is AudioStreamWAV:
		var wav_stream := stream as AudioStreamWAV
		wav_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop_enabled else AudioStreamWAV.LOOP_DISABLED
	elif stream.has_method("set_loop"):
		stream.set_loop(loop_enabled)
	elif stream.has_method("set_looping"):
		stream.set_looping(loop_enabled)
	else:
		push_warning("[AudioManager] Stream type does not expose loop controls.")
