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

const LETTER_WAVE_ORDER := [
	"T", "H", "E",
	"L", "I", "B", "R", "A", "R2", "Y",
	"W", "I2", "N", "D", "O", "W3", "O2", "S"
]

@export var eye_node_paths: Array[NodePath] = []
@export var brow_node_paths: Array[NodePath] = []
@export var eye_range := Vector2(3.0, 1.2)
@export var eye_speed := Vector2(4.0, 7.0)
@export var eye_pause := Vector2(1.2, 2.6)

@export var brow_sway_degrees := 2.5
@export_range(0.2, 4.0) var brow_sway_period := 2.4

@export var glow_node_paths: Array[NodePath] = []
@export var glow_color := Color(0.19, 1.0, 0.42, 1.0)
@export_range(0.0, 1.0) var glow_strength := 0.4
@export_range(0.5, 6.0) var glow_period := 2.6

@export var letter_wave_color := Color(0.25, 1.0, 0.45, 1.0)
@export_range(0.05, 1.0) var letter_wave_letter_duration := 0.18
@export var letter_wave_delay_range := Vector2(1.0, 60.0)
@export_range(1, 8) var letter_wave_min_passes := 2
@export_range(1, 8) var letter_wave_max_passes := 4
@export_range(0.0, 0.5) var letter_wave_scale_strength := 0.06
@export var letter_wave_wobble_offset := Vector2(6.0, 3.0)
@export var letter_wave_wobble_degrees := 4.0

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
var _brow_base_rotations: Dictionary = {}
var _letter_nodes: Array[Node2D] = []
var _letter_base_colors: Dictionary = {}
var _letter_base_scales: Dictionary = {}
var _letter_base_positions: Dictionary = {}
var _letter_base_rotations: Dictionary = {}
var _letter_wave_timer: SceneTreeTimer = null

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
	_resolve_letter_nodes()
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

func _resolve_brow_nodes() -> void:
	_brow_nodes.clear()
	_brow_base_rotations.clear()

	for path in brow_node_paths:
		if path.is_empty():
			continue
		var node := get_node_or_null(path)
		_register_brow_node(node)

	if _brow_nodes.is_empty():
		for name in FALLBACK_BROW_NAMES:
			var candidate := find_child(name, true, false)
			_register_brow_node(candidate)

func _register_brow_node(candidate: Node) -> void:
	if not candidate or not (candidate is Node2D):
		return
	if _brow_nodes.has(candidate):
		return
	_brow_nodes.append(candidate)
	_brow_base_rotations[candidate] = candidate.rotation

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
	if _eye_origins.has(piece):
		_eye_origins[piece] = piece.position
	if _brow_base_rotations.has(piece):
		_brow_base_rotations[piece] = piece.rotation
	if _glow_nodes.has(piece):
		_glow_base_colors[piece] = piece.modulate
	if _letter_base_colors.has(piece):
		_letter_base_colors[piece] = piece.modulate
	if _letter_base_scales.has(piece):
		_letter_base_scales[piece] = piece.scale
func _resolve_letter_nodes() -> void:
	_letter_nodes.clear()
	_letter_base_colors.clear()
	_letter_base_scales.clear()
	_letter_base_positions.clear()
	_letter_base_rotations.clear()

	for name in LETTER_WAVE_ORDER:
		var node := find_child(name, true, false)
		if node and node is Node2D and not _letter_nodes.has(node):
			_letter_nodes.append(node)
			_letter_base_colors[node] = node.modulate
			_letter_base_scales[node] = node.scale
			_letter_base_positions[node] = node.position
			_letter_base_rotations[node] = node.rotation


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
			node.position = _eye_origins.get(node, node.position)

	_queue_eye_motion_group()
	_schedule_letter_wave()

func _queue_eye_motion_group() -> void:
	if _resolved_eye_nodes.is_empty():
		return

	var offset := Vector2(
		randf_range(-eye_range.x, eye_range.x),
		randf_range(-eye_range.y, 0.0) # prevent downward motion
	)
	var travel_time: float = randf_range(eye_speed.x, eye_speed.y)
	var pause: float = randf_range(eye_pause.x, eye_pause.y)

	var callback_attached := false
	for node in _resolved_eye_nodes:
		if not is_instance_valid(node):
			continue

		var origin: Vector2 = _eye_origins.get(node, node.position)
		var tween := create_tween()
		var half_travel: float = max(0.1, travel_time * 0.5)

		tween.tween_property(node, "position", origin + offset, half_travel)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(node, "position", origin, half_travel)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_interval(pause)

		if not callback_attached:
			callback_attached = true
			tween.tween_callback(func(): _queue_eye_motion_group())

func _start_brow_sway(piece: Node2D) -> void:
	if not is_instance_valid(piece):
		return

	var base_rotation: float = _brow_base_rotations.get(piece, piece.rotation)
	piece.rotation = base_rotation

	var sway_radians := deg_to_rad(brow_sway_degrees)
	var half_period: float = max(0.1, brow_sway_period * 0.5)

	var tween := create_tween().set_loops()
	tween.tween_property(piece, "rotation", base_rotation + sway_radians, half_period)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(piece, "rotation", base_rotation - sway_radians, half_period)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

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

func _schedule_letter_wave() -> void:
	if _letter_nodes.is_empty():
		return
	var min_delay: float = min(letter_wave_delay_range.x, letter_wave_delay_range.y)
	var max_delay: float = max(letter_wave_delay_range.x, letter_wave_delay_range.y)
	var delay: float = randf_range(min_delay, max_delay)
	if delay <= 0.0:
		_play_letter_wave()
		return
	_letter_wave_timer = get_tree().create_timer(delay)
	_letter_wave_timer.timeout.connect(Callable(self, "_play_letter_wave"), CONNECT_ONE_SHOT)

func _play_letter_wave() -> void:
	if _letter_nodes.is_empty():
		_schedule_letter_wave()
		return

	var duration: float = letter_wave_letter_duration
	var step: float = max(0.01, duration * 0.25)
	var hold: float = duration * 0.4
	var min_passes: int = min(letter_wave_min_passes, letter_wave_max_passes)
	var max_passes: int = max(letter_wave_min_passes, letter_wave_max_passes)
	var passes: int = randi_range(min_passes, max_passes)
	var pass_span: float = ((_letter_nodes.size() - 1) * step) + (duration * 0.8) + hold

	for pass_idx in range(passes):
		var pass_delay: float = pass_idx * pass_span
		for i in range(_letter_nodes.size()):
			var letter: Node2D = _letter_nodes[i]
			if not is_instance_valid(letter):
				continue
			var base_color: Color = _letter_base_colors.get(letter, letter.modulate)
			var base_scale: Vector2 = _letter_base_scales.get(letter, letter.scale)
			var base_pos: Vector2 = _letter_base_positions.get(letter, letter.position)
			var base_rot: float = _letter_base_rotations.get(letter, letter.rotation)
			var target_scale: Vector2 = base_scale * (1.0 + letter_wave_scale_strength)
			var wobble_offset := Vector2(
				randf_range(-letter_wave_wobble_offset.x, letter_wave_wobble_offset.x),
				randf_range(-letter_wave_wobble_offset.y, letter_wave_wobble_offset.y)
			)
			wobble_offset.y = -abs(wobble_offset.y) # bias upward
			var wobble_rot := deg_to_rad(randf_range(-letter_wave_wobble_degrees, letter_wave_wobble_degrees))

			var tween := create_tween()
			var delay: float = pass_delay + (i * step)
			if delay > 0.0:
				tween.tween_interval(delay)

			var swirl_target := base_pos + wobble_offset.rotated(deg_to_rad(randf_range(60.0, 140.0)))

			tween.tween_property(letter, "modulate", letter_wave_color, duration * 0.35)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(letter, "scale", target_scale, duration * 0.35)\
				.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(letter, "position", base_pos + wobble_offset, duration * 0.35)\
				.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(letter, "rotation", base_rot + wobble_rot, duration * 0.35)\
				.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

			if hold > 0.0:
				tween.parallel().tween_property(letter, "position", swirl_target, hold)\
					.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				tween.parallel().tween_property(letter, "rotation", base_rot - wobble_rot, hold)\
					.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				tween.tween_interval(hold * 0.2)

			tween.tween_property(letter, "modulate", base_color, duration * 0.35)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			tween.parallel().tween_property(letter, "scale", base_scale, duration * 0.35)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			tween.parallel().tween_property(letter, "position", base_pos, duration * 0.35)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			tween.parallel().tween_property(letter, "rotation", base_rot, duration * 0.35)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	_schedule_letter_wave()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_G:
		_play_letter_wave()
		get_viewport().set_input_as_handled()
