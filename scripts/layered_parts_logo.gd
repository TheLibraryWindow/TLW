extends Node2D

const DEFAULT_PIXELATE_SHADER_PATH := "res://shaders/pixelate_intro.gdshader"

@export_range(0.3, 2.0) var drop_duration := 0.9
@export_range(0.0, 2.0) var drop_delay_spread := 0.4
@export var vertical_offset_range := Vector2(160, 320)
@export var horizontal_offset_range := Vector2(-180, 180)
@export var max_start_rotation_deg := 25.0
@export var fade_in_portion := 0.7

@export_range(0.1, 1.0) var settle_duration := 0.35
@export var settle_offset := Vector2(0, 8)
@export var settle_rotation_deg := 3.0

enum IntroStyle { DROP, SLIDE, CRASH, SWIRL, PIXELATE, FLASH }
const INTRO_STYLE_POOL := [
	IntroStyle.DROP,
	IntroStyle.SLIDE,
	IntroStyle.CRASH,
	IntroStyle.SWIRL,
	IntroStyle.PIXELATE,
	IntroStyle.FLASH
]

@export var randomize_intro := true
@export_enum("Drop", "Slide", "Crash", "Swirl", "Pixelate", "Flash") var manual_intro_style: int = IntroStyle.DROP

const FALLBACK_EYE_NAMES := [
	"Lefteye", "LeftEye",
	"Righteye", "RightEye",
	"LeftEyebag", "LeftEyeBag",
	"RightEyebag", "RightEyeBag"
]

const FALLBACK_BROW_NAMES := [
	"Lefteyebrow", "LeftEyebrow",
	"Righteyebrow", "RightEyebrow"
]

const FALLBACK_GLOW_NAMES := [
	"TopFrame", "OuterFrame"
]

@export var eye_node_paths: Array[NodePath] = []
@export var brow_node_paths: Array[NodePath] = []
@export var eye_move_radius := Vector2(3.0, 1.2)
@export var eye_move_interval := Vector2(4.0, 7.0)
@export var eye_idle_pause := Vector2(1.2, 2.6)

@export var brow_sway_degrees := 2.5
@export_range(0.2, 4.0) var brow_sway_period := 2.4

@export var glow_node_paths: Array[NodePath] = []
@export var glow_color := Color(0.19, 1.0, 0.42, 1.0)
@export_range(0.0, 1.0) var glow_strength := 0.4
@export_range(0.5, 6.0) var glow_period := 2.6

@export var pixelate_shader: Shader
@export var pixelate_amount_range := Vector2(48.0, 1.2)
@export_range(0.2, 2.5) var pixelate_duration := 1.1

@export var flash_delay_range := Vector2(0.05, 0.25)
@export_range(0.05, 1.0) var flash_ramp_duration := 0.28

var _active_intro_style := IntroStyle.DROP
var _default_pixelate_shader: Shader = null
var _resolved_eye_nodes: Array[Node2D] = []
var _eye_origins: Dictionary = {}
var _pending_eye_count := 0

var _glow_nodes: Array[Node2D] = []
var _glow_base_colors: Dictionary = {}
var _brow_nodes: Array[Node2D] = []

func _determine_intro_style() -> void:
	_active_intro_style = manual_intro_style
	if randomize_intro:
		_active_intro_style = INTRO_STYLE_POOL[randi() % INTRO_STYLE_POOL.size()]
	print("[LayeredLogo] intro style =", _intro_style_name(_active_intro_style))

func _intro_style_name(style: int) -> String:
	match style:
		IntroStyle.DROP:
			return "drop"
		IntroStyle.SLIDE:
			return "slide"
		IntroStyle.CRASH:
			return "crash"
		IntroStyle.SWIRL:
			return "swirl"
		IntroStyle.PIXELATE:
			return "pixelate"
		IntroStyle.FLASH:
			return "flash"
		_:
			return "unknown"

func _ready() -> void:
	_ensure_default_pixelate_shader()
	randomize()
	_determine_intro_style()
	_resolve_eye_nodes()
	_resolve_brow_nodes()
	_resolve_glow_nodes()
	_pending_eye_count = _resolved_eye_nodes.size()

	for piece in get_children():
		if not piece is Node2D:
			continue
		_store_final_pose(piece)
		_prepare_piece_for_intro(piece)
		_play_intro_for_piece(piece)

func _resolve_eye_nodes() -> void:
	_resolved_eye_nodes.clear()
	_eye_origins.clear()

	for path in eye_node_paths:
		if path.is_empty():
			continue
		var node := get_node_or_null(path)
		_register_eye_node(node)

	if _resolved_eye_nodes.is_empty():
		for name in FALLBACK_EYE_NAMES:
			var candidate := find_child(name, true, false)
			_register_eye_node(candidate)

func _register_eye_node(candidate: Node) -> void:
	if not candidate or not (candidate is Node2D):
		return
	if _resolved_eye_nodes.has(candidate):
		return
	_resolved_eye_nodes.append(candidate)
	_eye_origins[candidate] = candidate.position

func _resolve_glow_nodes() -> void:
	_glow_nodes.clear()
	_glow_base_colors.clear()

	for path in glow_node_paths:
		if path.is_empty():
			continue
		var node := get_node_or_null(path)
		if node and node is Node2D and not _glow_nodes.has(node):
			_glow_nodes.append(node)
			_glow_base_colors[node] = node.modulate

	if _glow_nodes.is_empty():
		for name in FALLBACK_GLOW_NAMES:
			var candidate := find_child(name, true, false)
			if candidate and candidate is Node2D and not _glow_nodes.has(candidate):
				_glow_nodes.append(candidate)
				_glow_base_colors[candidate] = candidate.modulate

func _store_final_pose(piece: Node2D) -> void:
	piece.set_meta("target_pos", piece.position)
	piece.set_meta("target_rot", piece.rotation)
	piece.set_meta("target_scale", piece.scale)
	if _watch_origins.has(piece):
		_watch_origins[piece] = piece.position
	if _glow_nodes.has(piece):
		_glow_base_colors[piece] = piece.modulate

func _prepare_piece_for_intro(piece: Node2D) -> void:
	match _active_intro_style:
		IntroStyle.SLIDE:
			_prepare_slide_intro(piece)
		IntroStyle.CRASH:
			_prepare_crash_intro(piece)
		IntroStyle.SWIRL:
			_prepare_swirl_intro(piece)
		IntroStyle.PIXELATE:
			_prepare_pixelate_intro(piece)
		IntroStyle.FLASH:
			_prepare_flash_intro(piece)
		_:
			_prepare_drop_intro(piece)

func _play_intro_for_piece(piece: Node2D) -> void:
	match _active_intro_style:
		IntroStyle.SLIDE:
			_play_slide_intro(piece)
		IntroStyle.CRASH:
			_play_crash_intro(piece)
		IntroStyle.SWIRL:
			_play_swirl_intro(piece)
		IntroStyle.PIXELATE:
			_play_pixelate_intro(piece)
		IntroStyle.FLASH:
			_play_flash_intro(piece)
		_:
			_play_drop_intro(piece)

func _prepare_drop_intro(piece: Node2D) -> void:
	var x_offset := randf_range(horizontal_offset_range.x, horizontal_offset_range.y)
	var y_offset := -randf_range(vertical_offset_range.x, vertical_offset_range.y)
	var rot_offset := deg_to_rad(randf_range(-max_start_rotation_deg, max_start_rotation_deg))
	piece.position += Vector2(x_offset, y_offset)
	piece.rotation += rot_offset
	_set_initial_alpha(piece, 0.0)

func _prepare_slide_intro(piece: Node2D) -> void:
	var direction := -1 if randf() < 0.5 else 1
	var distance := randf_range(520.0, 860.0)
	piece.position += Vector2(direction * distance, randf_range(-140.0, 140.0))
	piece.rotation += deg_to_rad(randf_range(-10.0, 10.0))
	_set_initial_alpha(piece, 0.0)

func _prepare_crash_intro(piece: Node2D) -> void:
	var target_scale: Vector2 = piece.get_meta("target_scale") as Vector2
	piece.position += Vector2(randf_range(-220.0, 220.0), -randf_range(420.0, 640.0))
	piece.rotation += deg_to_rad(randf_range(-40.0, 40.0))
	piece.scale = target_scale * randf_range(1.15, 1.4)
	_set_initial_alpha(piece, 0.0)

func _prepare_swirl_intro(piece: Node2D) -> void:
	var target_scale: Vector2 = piece.get_meta("target_scale") as Vector2
	var radius := randf_range(220.0, 420.0)
	var angle := randf_range(-PI, PI)
	piece.position += Vector2(cos(angle), sin(angle)) * radius
	piece.rotation += deg_to_rad(randf_range(-180.0, 180.0))
	piece.scale = target_scale * randf_range(0.25, 0.45)
	_set_initial_alpha(piece, 0.0)

func _prepare_pixelate_intro(piece: Node2D) -> void:
	var target_scale: Vector2 = piece.get_meta("target_scale") as Vector2
	piece.scale = target_scale
	_set_initial_alpha(piece, 0.0)

func _prepare_flash_intro(piece: Node2D) -> void:
	var target_scale: Vector2 = piece.get_meta("target_scale") as Vector2
	piece.scale = target_scale * randf_range(0.9, 1.05)
	_set_initial_alpha(piece, 0.0)

func _play_drop_intro(piece: Node2D) -> void:
	var tween := _make_intro_tween()
	var target_pos: Vector2 = piece.get_meta("target_pos") as Vector2
	var target_rot: float = piece.get_meta("target_rot") as float
	var target_scale: Vector2 = piece.get_meta("target_scale") as Vector2

	tween.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(piece, "position", target_pos + settle_offset, drop_duration)
	tween.parallel().tween_property(piece, "rotation", target_rot + deg_to_rad(settle_rotation_deg), drop_duration)
	tween.parallel().tween_property(piece, "scale", target_scale * 1.01, drop_duration)
	tween.parallel().tween_property(piece, "modulate:a", 1.0, drop_duration * fade_in_portion)

	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(piece, "position", target_pos, settle_duration)
	tween.parallel().tween_property(piece, "rotation", target_rot, settle_duration)
	tween.parallel().tween_property(piece, "scale", target_scale, settle_duration)

	tween.tween_callback(func(): _on_piece_settled(piece))

func _play_slide_intro(piece: Node2D) -> void:
	var tween := _make_intro_tween()
	var target_pos: Vector2 = piece.get_meta("target_pos") as Vector2
	var target_rot: float = piece.get_meta("target_rot") as float
	var target_scale: Vector2 = piece.get_meta("target_scale") as Vector2
	var duration: float = drop_duration + 0.4

	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(piece, "position", target_pos, duration)
	tween.parallel().tween_property(piece, "rotation", target_rot, duration)
	tween.parallel().tween_property(piece, "scale", target_scale, duration)
	tween.parallel().tween_property(piece, "modulate:a", 1.0, duration * 0.55)

	tween.tween_callback(func(): _on_piece_settled(piece))

func _play_crash_intro(piece: Node2D) -> void:
	var tween := _make_intro_tween()
	var target_pos: Vector2 = piece.get_meta("target_pos") as Vector2
	var target_rot: float = piece.get_meta("target_rot") as float
	var target_scale: Vector2 = piece.get_meta("target_scale") as Vector2

	var impact_duration: float = max(0.25, drop_duration * 0.55)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(piece, "position", target_pos, impact_duration)
	tween.parallel().tween_property(piece, "rotation", target_rot, impact_duration)
	tween.parallel().tween_property(piece, "scale", target_scale * 0.93, impact_duration)
	tween.parallel().tween_property(piece, "modulate:a", 1.0, impact_duration * 0.6)

	tween.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(piece, "scale", target_scale, 0.35)
	tween.parallel().tween_property(piece, "position", target_pos + Vector2(randf_range(-8.0, 8.0), randf_range(-6.0, 6.0)), 0.2)
	tween.parallel().tween_property(piece, "rotation", target_rot + deg_to_rad(randf_range(-2.5, 2.5)), 0.2)
	tween.tween_property(piece, "position", target_pos, 0.15)
	tween.parallel().tween_property(piece, "rotation", target_rot, 0.15)

	tween.tween_callback(func(): _on_piece_settled(piece))

func _play_swirl_intro(piece: Node2D) -> void:
	var tween := _make_intro_tween()
	var target_pos: Vector2 = piece.get_meta("target_pos") as Vector2
	var target_rot: float = piece.get_meta("target_rot") as float
	var target_scale: Vector2 = piece.get_meta("target_scale") as Vector2

	var travel: float = drop_duration + 0.6
	var spin: float = deg_to_rad(randf_range(540.0, 900.0)) * (-1 if randf() < 0.5 else 1)

	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(piece, "position", target_pos, travel)
	tween.parallel().tween_property(piece, "scale", target_scale, travel)
	tween.parallel().tween_property(piece, "modulate:a", 1.0, travel * 0.6)
	tween.parallel().tween_property(piece, "rotation", target_rot + spin, travel * 0.8)
	tween.tween_property(piece, "rotation", target_rot, 0.35)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_callback(func(): _on_piece_settled(piece))

func _play_pixelate_intro(piece: Node2D) -> void:
	var tween := _make_intro_tween()
	var target_pos: Vector2 = piece.get_meta("target_pos") as Vector2
	var target_rot: float = piece.get_meta("target_rot") as float
	var target_scale: Vector2 = piece.get_meta("target_scale") as Vector2
	var shader := _get_pixelate_shader()
	var shader_material: ShaderMaterial = null
	var start_amount: float = max(1.0, max(pixelate_amount_range.x, pixelate_amount_range.y))
	var end_amount: float = max(1.0, min(pixelate_amount_range.x, pixelate_amount_range.y))

	if shader:
		shader_material = ShaderMaterial.new()
		shader_material.shader = shader
		shader_material.set_shader_parameter("pixelate_amount", start_amount)
		piece.set_meta("intro_original_material", piece.material)
		piece.material = shader_material

	var duration: float = pixelate_duration
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(piece, "modulate:a", 1.0, duration * 0.65)
	tween.parallel().tween_property(piece, "position", target_pos, duration)
	tween.parallel().tween_property(piece, "rotation", target_rot, duration * 0.9)
	tween.parallel().tween_property(piece, "scale", target_scale * 1.02, duration * 0.7)
	if shader_material:
		_tween_shader_param(tween, shader_material, &"pixelate_amount", start_amount, end_amount, duration * 0.9)

	tween.tween_property(piece, "scale", target_scale, settle_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func(): _on_piece_settled(piece))

func _play_flash_intro(piece: Node2D) -> void:
	var tween := _make_intro_tween()
	var target_pos: Vector2 = piece.get_meta("target_pos") as Vector2
	var target_rot: float = piece.get_meta("target_rot") as float
	var target_scale: Vector2 = piece.get_meta("target_scale") as Vector2

	var delay_min: float = min(flash_delay_range.x, flash_delay_range.y)
	var delay_max: float = max(flash_delay_range.x, flash_delay_range.y)
	var hold: float = randf_range(delay_min, delay_max)
	if hold > 0.0:
		tween.tween_interval(hold)

	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(piece, "modulate:a", 1.0, flash_ramp_duration)
	tween.parallel().tween_property(piece, "position", target_pos, flash_ramp_duration)
	tween.parallel().tween_property(piece, "rotation", target_rot, flash_ramp_duration * 0.8)
	tween.parallel().tween_property(piece, "scale", target_scale, flash_ramp_duration)

	tween.tween_property(piece, "scale", target_scale * 1.01, 0.18)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(piece, "scale", target_scale, 0.12)
	tween.tween_callback(func(): _on_piece_settled(piece))

func _make_intro_tween() -> Tween:
	var tween := create_tween()
	if drop_delay_spread > 0.0:
		tween.tween_interval(randf() * drop_delay_spread)
	return tween

func _tween_shader_param(tween: Tween, material: ShaderMaterial, param: StringName, from: float, to: float, duration: float) -> void:
	if not material:
		return
	tween.tween_method(Callable(self, "_set_shader_param").bind(material, param), from, to, duration)

func _set_shader_param(value: float, material: ShaderMaterial, param: StringName) -> void:
	if not material:
		return
	material.set_shader_parameter(param, value)

func _set_initial_alpha(piece: Node2D, target_alpha: float) -> void:
	var fade_color := piece.modulate
	fade_color.a = target_alpha
	piece.modulate = fade_color

func _on_piece_settled(piece: Node2D) -> void:
	_restore_intro_material(piece)
	if _resolved_eye_nodes.has(piece):
		_on_eye_piece_ready()
	if _glow_nodes.has(piece):
		_start_glow_for(piece)
	if _brow_nodes.has(piece):
		_start_brow_sway(piece)

func _restore_intro_material(piece: Node2D) -> void:
	if not piece.has_meta("intro_original_material"):
		return
	var original = piece.get_meta("intro_original_material")
	piece.material = original
	piece.set_meta("intro_original_material", null)

func _ensure_default_pixelate_shader() -> void:
	if pixelate_shader:
		return
	if _default_pixelate_shader:
		pixelate_shader = _default_pixelate_shader
		return
	if not ResourceLoader.exists(DEFAULT_PIXELATE_SHADER_PATH):
		push_warning("[LayeredLogo] Pixelate shader missing at %s" % DEFAULT_PIXELATE_SHADER_PATH)
		return
	var shader := load(DEFAULT_PIXELATE_SHADER_PATH)
	if shader and shader is Shader:
		_default_pixelate_shader = shader
		pixelate_shader = shader

func _get_pixelate_shader() -> Shader:
	if pixelate_shader:
		return pixelate_shader
	_ensure_default_pixelate_shader()
	return pixelate_shader

func _on_eye_piece_ready() -> void:
	_pending_eye_count -= 1
	if _pending_eye_count <= 0:
		_start_eye_motion()

func _start_eye_motion() -> void:
	if _resolved_eye_nodes.is_empty():
		return

	for node in _resolved_eye_nodes:
		if is_instance_valid(node):
			node.position = _watch_origins.get(node, node.position)

	_queue_eye_motion_group()

func _queue_eye_motion_group() -> void:
	if _resolved_eye_nodes.is_empty():
		return

	var offset := Vector2(
		randf_range(-eye_move_radius.x, eye_move_radius.x),
		randf_range(-eye_move_radius.y, eye_move_radius.y)
	)
	var travel_time: float = randf_range(eye_move_interval.x, eye_move_interval.y)
	var pause: float = randf_range(eye_idle_pause.x, eye_idle_pause.y)

	var callback_attached := false
	for tier in _watch_groups.size():
		var nodes: Array = _watch_groups[tier]
		if nodes.is_empty():
			continue

		var start_delay := tier * watch_follow_delay
		var tier_offset := offset * _watch_follow_multiplier(tier)

		for node in nodes:
			if not is_instance_valid(node):
				continue

			var origin: Vector2 = _watch_origins.get(node, node.position)
			var tween := create_tween()
			if start_delay > 0.0:
				tween.tween_interval(start_delay)
			tween.tween_property(node, "position", origin + tier_offset, travel_time)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.tween_interval(pause)

			if not callback_attached:
				callback_attached = true
				tween.tween_callback(func(): _queue_eye_motion_group())

func _watch_follow_multiplier(tier: int) -> float:
	match tier:
		0:
			return watch_follow_scale.x
		1:
			return watch_follow_scale.y
		_:
			return watch_follow_scale.z

func _start_glow_for(piece: Node2D) -> void:
	if not is_instance_valid(piece):
		return

	var base: Color = _glow_base_colors.get(piece, piece.modulate)
	var target := base.lerp(glow_color, glow_strength)

	var tween := create_tween().set_loops()
	var half_period: float = glow_period * 0.5

	tween.tween_property(piece, "modulate", target, half_period)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(piece, "modulate", base, half_period)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
