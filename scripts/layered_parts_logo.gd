extends Node2D

@export_range(0.3, 2.0) var drop_duration := 0.9
@export_range(0.0, 2.0) var drop_delay_spread := 0.4
@export var vertical_offset_range := Vector2(160, 320)
@export var horizontal_offset_range := Vector2(-180, 180)
@export var max_start_rotation_deg := 25.0
@export var fade_in_portion := 0.7

@export_range(0.1, 1.0) var settle_duration := 0.35
@export var settle_offset := Vector2(0, 8)
@export var settle_rotation_deg := 3.0

@export var eye_node_paths: Array[NodePath] = []
@export var eye_move_radius := Vector2(8.0, 4.0)
@export var eye_move_interval := Vector2(2.0, 3.8)
@export var eye_idle_pause := Vector2(0.4, 0.8)

var _resolved_eye_nodes: Array[Node2D] = []
var _eye_origins: Dictionary = {}
var _pending_eye_count := 0

func _ready() -> void:
	_resolve_eye_nodes()
	_pending_eye_count = _resolved_eye_nodes.size()

	for piece in get_children():
		if not piece is Node2D:
			continue
		_store_final_pose(piece)
		_offset_start_pose(piece)
		_drop_piece(piece)

func _resolve_eye_nodes() -> void:
	_resolved_eye_nodes.clear()
	for path in eye_node_paths:
		if path.is_empty():
			continue
		var node := get_node_or_null(path)
		if node and node is Node2D and not _resolved_eye_nodes.has(node):
			_resolved_eye_nodes.append(node)

	if _resolved_eye_nodes.is_empty():
		for name in ["Lefteye", "LeftEye", "Righteye", "RightEye"]:
			var candidate := find_child(name, true, false)
			if candidate and candidate is Node2D and not _resolved_eye_nodes.has(candidate):
				_resolved_eye_nodes.append(candidate)

func _store_final_pose(piece: Node2D) -> void:
	piece.set_meta("target_pos", piece.position)
	piece.set_meta("target_rot", piece.rotation)
	if _resolved_eye_nodes.has(piece):
		_eye_origins[piece] = piece.position

func _offset_start_pose(piece: Node2D) -> void:
	var x_offset := randf_range(horizontal_offset_range.x, horizontal_offset_range.y)
	var y_offset := -randf_range(vertical_offset_range.x, vertical_offset_range.y)
	var rot_offset := deg_to_rad(randf_range(-max_start_rotation_deg, max_start_rotation_deg))

	piece.position += Vector2(x_offset, y_offset)
	piece.rotation += rot_offset

	var fade_color := piece.modulate
	fade_color.a = 0.0
	piece.modulate = fade_color

func _drop_piece(piece: Node2D) -> void:
	var tween := create_tween()

	if drop_delay_spread > 0.0:
		tween.tween_interval(randf() * drop_delay_spread)

	tween.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	var target_pos: Vector2 = piece.get_meta("target_pos") as Vector2
	var target_rot: float = piece.get_meta("target_rot") as float

	tween.tween_property(piece, "position", target_pos + settle_offset, drop_duration)
	tween.parallel().tween_property(piece, "rotation", target_rot + deg_to_rad(settle_rotation_deg), drop_duration)
	tween.parallel().tween_property(piece, "modulate:a", 1.0, drop_duration * fade_in_portion)

	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(piece, "position", target_pos, settle_duration)
	tween.parallel().tween_property(piece, "rotation", target_rot, settle_duration)

	if _resolved_eye_nodes.has(piece):
		tween.tween_callback(func(): _on_eye_piece_ready())

func _on_eye_piece_ready() -> void:
	_pending_eye_count -= 1
	if _pending_eye_count <= 0:
		_start_eye_motion()

func _start_eye_motion() -> void:
	if _resolved_eye_nodes.is_empty():
		return

	for eye in _resolved_eye_nodes:
		if is_instance_valid(eye):
			eye.position = _eye_origins.get(eye, eye.position)

	_queue_eye_motion_group()

func _queue_eye_motion_group() -> void:
	if _resolved_eye_nodes.is_empty():
		return

	var offset := Vector2(
		randf_range(-eye_move_radius.x, eye_move_radius.x),
		randf_range(-eye_move_radius.y, eye_move_radius.y)
	)
	var travel_time := randf_range(eye_move_interval.x, eye_move_interval.y)
	var pause := randf_range(eye_idle_pause.x, eye_idle_pause.y)

	var callback_attached := false
	for eye in _resolved_eye_nodes:
		if not is_instance_valid(eye):
			continue

		var origin: Vector2 = _eye_origins.get(eye, eye.position)
		var tween := create_tween()
		tween.tween_property(eye, "position", origin + offset, travel_time)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_interval(pause)

		if not callback_attached:
			callback_attached = true
			tween.tween_callback(func(): _queue_eye_motion_group())
