extends Node2D

const BOOT_ANIMATION := "bootuplogo"
const FADE_START_TIME := 5.5
const ANIMATION_END_TIME := 6.0
const TARGET_VOLUME_DB := -12.0
const LOGIN_MUSIC_PATH := "res://audio/loginmenu/loginmenu.wav"
const AUDIO_MANAGER_SCENE_PATH := "res://scenes/AudioManager.tscn"

@onready var animation_player: AnimationPlayer = $Sprite2D/AnimationPlayer
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

signal logo_finished

var fade_started := false
var transition_triggered := false
var audio_manager: Node = null


func _ready() -> void:
	print("[BOOTLOGO] Startup sequence beginning.")

	audio_manager = _ensure_audio_manager()
	_start_music()

	if animation_player and animation_player.has_animation(BOOT_ANIMATION):
		animation_player.play(BOOT_ANIMATION)
		if not animation_player.animation_finished.is_connected(_on_animation_finished):
			animation_player.animation_finished.connect(_on_animation_finished)
		set_process(true)
	else:
		print("[BOOTLOGO] No animation found, skipping directly to login menu.")
		emit_signal("logo_finished")
		_handoff_audio_and_continue()


func _process(_delta: float) -> void:
	if fade_started or transition_triggered:
		return

	if not animation_player or animation_player.current_animation != BOOT_ANIMATION:
		return

	var t := animation_player.current_animation_position
	if t >= FADE_START_TIME:
		fade_started = true
		_start_fade()


func _start_fade() -> void:
	var fade_time: float = max(ANIMATION_END_TIME - FADE_START_TIME, 0.05)
	print("[BOOTLOGO] Starting subtle fade at %.2fs." % FADE_START_TIME)

	if audio_manager and audio_manager.has_method("fade_volume_to"):
		audio_manager.fade_volume_to(TARGET_VOLUME_DB, fade_time)
	elif audio_player:
		var tween: Tween = create_tween()
		tween.tween_property(
			audio_player,
			"volume_db",
			TARGET_VOLUME_DB,
			fade_time
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_animation_finished(anim_name: String) -> void:
	if anim_name != BOOT_ANIMATION or transition_triggered:
		return

	print("[BOOTLOGO] Animation finished — moving to next scene.")
	emit_signal("logo_finished")
	_handoff_audio_and_continue()


func _handoff_audio_and_continue() -> void:
	if transition_triggered:
		return

	transition_triggered = true
	_handoff_audio_to_manager()
	_goto_login_menu()


func _handoff_audio_to_manager() -> void:
	if audio_manager and audio_manager.has_method("play_track_from_path"):
		return

	if not audio_player or audio_player.stream == null:
		return

	var manager := _ensure_audio_manager()
	if manager and manager.has_method("play_track"):
		var stream := audio_player.stream
		var pos := audio_player.get_playback_position()
		manager.play_track(stream, pos, audio_player.volume_db, true)
	else:
		push_warning("[BOOTLOGO] AudioManager not found — music will restart in next scene.")

	audio_player.stop()


func _goto_login_menu() -> void:
	var err := get_tree().change_scene_to_file("res://scenes/loginmenu.tscn")
	if err != OK:
		push_error("[BOOTLOGO] Failed to change scene: %s" % err)


func _get_audio_manager() -> Node:
	if audio_manager and is_instance_valid(audio_manager):
		return audio_manager
	return get_tree().root.get_node_or_null("AudioManager")


func _ensure_audio_manager() -> Node:
	if audio_manager and is_instance_valid(audio_manager):
		return audio_manager

	var root := get_tree().root
	var existing := root.get_node_or_null("AudioManager")
	if existing:
		audio_manager = existing
		return audio_manager

	var packed_scene := ResourceLoader.load(AUDIO_MANAGER_SCENE_PATH)
	if packed_scene is PackedScene:
		var instance := (packed_scene as PackedScene).instantiate()
		instance.name = "AudioManager"
		root.add_child(instance)
		audio_manager = instance
	else:
		push_warning("[BOOTLOGO] AudioManager scene missing at %s" % AUDIO_MANAGER_SCENE_PATH)

	return audio_manager


func _start_music() -> void:
	if audio_manager and audio_manager.has_method("play_track_from_path"):
		if not audio_manager.is_playing_path(LOGIN_MUSIC_PATH):
			audio_manager.play_track_from_path(LOGIN_MUSIC_PATH, 0.0, 0.0, true)
	else:
		_play_local_boot_track()


func _play_local_boot_track() -> void:
	if not audio_player:
		push_warning("[BOOTLOGO] No audio player available for fallback.")
		return

	var stream := audio_player.stream
	if stream == null:
		var loaded := ResourceLoader.load(LOGIN_MUSIC_PATH)
		if loaded is AudioStream:
			audio_player.stream = loaded
			stream = loaded
	if stream == null:
		push_warning("[BOOTLOGO] Could not load login menu music.")
		return

	audio_player.volume_db = 0.0
	audio_player.play()
