extends Node2D

const WARP_SHADER := preload("res://scripts/psychedelic_warp.gdshader")
const WARP_MAX_WAVES := 3
const HASH_KEYCODE := 35
const WARP_PATTERN_PRESETS := [
	{"radius": Vector2(0.22, 0.35), "amplitude": Vector2(0.015, 0.03), "pinch": Vector2(0.008, 0.02), "aspect": Vector2(0.45, 0.9), "dispersion": Vector2(6.5, 9.5), "speed": Vector2(1.2, 1.8)},
	{"radius": Vector2(0.30, 0.45), "amplitude": Vector2(0.02, 0.04), "pinch": Vector2(0.012, 0.028), "aspect": Vector2(0.6, 1.2), "dispersion": Vector2(7.0, 11.5), "speed": Vector2(1.4, 2.0)},
	{"radius": Vector2(0.45, 0.65), "amplitude": Vector2(0.018, 0.05), "pinch": Vector2(0.01, 0.03), "aspect": Vector2(0.8, 1.5), "dispersion": Vector2(8.0, 12.0), "speed": Vector2(1.6, 2.3)},
	{"radius": Vector2(0.15, 0.30), "amplitude": Vector2(0.025, 0.06), "pinch": Vector2(0.015, 0.035), "aspect": Vector2(0.3, 0.7), "dispersion": Vector2(5.5, 8.0), "speed": Vector2(1.8, 2.6)},
	{"radius": Vector2(0.55, 0.80), "amplitude": Vector2(0.015, 0.04), "pinch": Vector2(0.005, 0.02), "aspect": Vector2(1.0, 2.0), "dispersion": Vector2(9.0, 13.0), "speed": Vector2(1.1, 1.7)},
	{"radius": Vector2(0.25, 0.50), "amplitude": Vector2(0.03, 0.07), "pinch": Vector2(0.02, 0.04), "aspect": Vector2(0.5, 1.0), "dispersion": Vector2(7.5, 10.5), "speed": Vector2(2.0, 2.8)},
	{"radius": Vector2(0.35, 0.60), "amplitude": Vector2(0.012, 0.03), "pinch": Vector2(0.006, 0.018), "aspect": Vector2(0.9, 1.6), "dispersion": Vector2(8.5, 12.5), "speed": Vector2(1.3, 2.1)},
	{"radius": Vector2(0.18, 0.34), "amplitude": Vector2(0.02, 0.05), "pinch": Vector2(0.014, 0.03), "aspect": Vector2(0.4, 0.9), "dispersion": Vector2(6.0, 9.0), "speed": Vector2(1.9, 2.6)},
	{"radius": Vector2(0.42, 0.70), "amplitude": Vector2(0.025, 0.06), "pinch": Vector2(0.017, 0.033), "aspect": Vector2(0.7, 1.3), "dispersion": Vector2(7.5, 11.0), "speed": Vector2(1.5, 2.2)},
	{"radius": Vector2(0.28, 0.38), "amplitude": Vector2(0.018, 0.032), "pinch": Vector2(0.01, 0.024), "aspect": Vector2(1.1, 1.9), "dispersion": Vector2(8.0, 13.0), "speed": Vector2(1.2, 1.9)},
	{"radius": Vector2(0.32, 0.58), "amplitude": Vector2(0.022, 0.045), "pinch": Vector2(0.012, 0.028), "aspect": Vector2(0.6, 1.3), "dispersion": Vector2(6.5, 10.0), "speed": Vector2(1.7, 2.4)},
	{"radius": Vector2(0.20, 0.36), "amplitude": Vector2(0.028, 0.055), "pinch": Vector2(0.015, 0.034), "aspect": Vector2(0.35, 0.85), "dispersion": Vector2(5.5, 8.5), "speed": Vector2(2.1, 3.1)},
	{"radius": Vector2(0.48, 0.76), "amplitude": Vector2(0.017, 0.04), "pinch": Vector2(0.008, 0.022), "aspect": Vector2(0.9, 1.8), "dispersion": Vector2(9.5, 13.5), "speed": Vector2(1.2, 1.8)},
	{"radius": Vector2(0.24, 0.44), "amplitude": Vector2(0.03, 0.065), "pinch": Vector2(0.02, 0.04), "aspect": Vector2(0.5, 1.1), "dispersion": Vector2(7.0, 10.0), "speed": Vector2(1.8, 2.7)},
	{"radius": Vector2(0.38, 0.62), "amplitude": Vector2(0.02, 0.05), "pinch": Vector2(0.012, 0.03), "aspect": Vector2(0.8, 1.4), "dispersion": Vector2(8.0, 11.5), "speed": Vector2(1.4, 2.2)},
	{"radius": Vector2(0.16, 0.28), "amplitude": Vector2(0.035, 0.07), "pinch": Vector2(0.02, 0.045), "aspect": Vector2(0.3, 0.7), "dispersion": Vector2(5.0, 7.5), "speed": Vector2(2.2, 3.2)},
	{"radius": Vector2(0.50, 0.82), "amplitude": Vector2(0.015, 0.035), "pinch": Vector2(0.006, 0.02), "aspect": Vector2(1.0, 2.2), "dispersion": Vector2(9.0, 14.0), "speed": Vector2(1.1, 1.9)},
	{"radius": Vector2(0.27, 0.49), "amplitude": Vector2(0.024, 0.052), "pinch": Vector2(0.013, 0.03), "aspect": Vector2(0.55, 1.2), "dispersion": Vector2(6.8, 9.8), "speed": Vector2(1.6, 2.5)},
	{"radius": Vector2(0.34, 0.57), "amplitude": Vector2(0.018, 0.04), "pinch": Vector2(0.01, 0.025), "aspect": Vector2(1.2, 2.0), "dispersion": Vector2(8.5, 12.8), "speed": Vector2(1.3, 2.0)},
	{"radius": Vector2(0.21, 0.40), "amplitude": Vector2(0.032, 0.068), "pinch": Vector2(0.018, 0.04), "aspect": Vector2(0.4, 0.95), "dispersion": Vector2(6.0, 9.2), "speed": Vector2(2.0, 3.0)},
	{"radius": Vector2(0.12, 0.22), "amplitude": Vector2(0.038, 0.08), "pinch": Vector2(0.024, 0.05), "aspect": Vector2(0.25, 0.6), "dispersion": Vector2(4.0, 6.8), "speed": Vector2(2.4, 3.4)},
	{"radius": Vector2(0.58, 0.85), "amplitude": Vector2(0.02, 0.05), "pinch": Vector2(0.01, 0.025), "aspect": Vector2(1.4, 2.4), "dispersion": Vector2(9.5, 14.5), "speed": Vector2(1.5, 2.3)},
	{"radius": Vector2(0.18, 0.52), "amplitude": Vector2(0.028, 0.065), "pinch": Vector2(0.02, 0.045), "aspect": Vector2(0.35, 1.4), "dispersion": Vector2(6.5, 9.5), "speed": Vector2(2.1, 3.2)},
	{"radius": Vector2(0.40, 0.68), "amplitude": Vector2(0.014, 0.03), "pinch": Vector2(0.007, 0.02), "aspect": Vector2(0.9, 1.7), "dispersion": Vector2(7.5, 11.8), "speed": Vector2(1.8, 2.6)},
	{"radius": Vector2(0.22, 0.48), "amplitude": Vector2(0.03, 0.075), "pinch": Vector2(0.02, 0.05), "aspect": Vector2(0.45, 1.0), "dispersion": Vector2(5.8, 8.8), "speed": Vector2(2.3, 3.3)}
]
const WARP_GLOBAL_INTENSITY_RANGE := Vector2(0.85, 1.4)
const WARP_GLOBAL_CHROMA_RANGE := Vector2(0.12, 0.35)
const WARP_GLOBAL_EDGE_RANGE := Vector2(0.004, 0.02)
const WARP_DELAY_RANGE := Vector2(0.0, 0.001)
const WARP_SPEED_MULT_RANGE := Vector2(0.32, 0.58)
const WARP_GLOW_RANGE := Vector2(0.2, 0.45)
const WARP_GLITCH_RANGE := Vector2(0.08, 0.25)
const WARP_DISPERSION_SCALE := Vector2(0.35, 0.65)
const WARP_RADIUS_BOOST_RANGE := Vector2(4.6, 7.2)
const WARP_AMPLITUDE_BOOST_RANGE := Vector2(3.2, 5.2)
const WARP_PINCH_BOOST_RANGE := Vector2(2.4, 4.0)
const WARP_HOLD_REPEAT := 0.0012

var _warp_layer: CanvasLayer = null
var _warp_rect: ColorRect = null
var _warp_material: ShaderMaterial = null
var _warp_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _warp_queue: Array[Dictionary] = []
var _warp_active: Array[Dictionary] = []
var _warp_running: bool = false
var _hash_held: bool = false
var _hold_timer: float = 0.0

func _ready() -> void:
	_init_warp_overlay()
	set_process_input(true)
	set_process(false)
	call_deferred("_start_intro_warp")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if _is_hash_key(event):
			_hash_held = true
			_hold_timer = WARP_HOLD_REPEAT
			_trigger_warp_burst(true)
	elif event is InputEventKey and not event.pressed and _is_hash_key(event):
		_hash_held = false
		_hold_timer = 0.0
		_stop_warp_immediate()

func _process(delta: float) -> void:
	if not _warp_running:
		if _hash_held:
			_trigger_warp_burst(true)
		return

	var queue_index := 0
	while queue_index < _warp_queue.size():
		_warp_queue[queue_index]["start_delay"] -= delta
		if _warp_queue[queue_index]["start_delay"] <= 0.0:
			var wave = _warp_queue.pop_at(queue_index)
			wave["progress"] = 0.0
			_warp_active.append(wave)
		else:
			queue_index += 1

	var active_index := 0
	while active_index < _warp_active.size():
		var wave = _warp_active[active_index]
		wave["progress"] = min(1.0, wave["progress"] + delta * wave["speed"])
		if wave["progress"] >= 1.0:
			_warp_active.remove_at(active_index)
		else:
			active_index += 1

	if _warp_active.is_empty() and _warp_queue.is_empty():
		_warp_running = false
		if _warp_rect:
			_warp_rect.visible = false
		set_process(false)
	else:
		_update_warp_shader()

	if _hash_held:
		_hold_timer -= delta
		if _hold_timer <= 0.0:
			_trigger_warp_burst(false)
			_hold_timer = WARP_HOLD_REPEAT
	else:
		_hold_timer = 0.0

func _start_intro_warp() -> void:
	if not _warp_material:
		return
	_trigger_warp_burst(true)
	var timer := get_tree().create_timer(0.85)
	timer.timeout.connect(_stop_warp_immediate)

func _stop_warp_immediate() -> void:
	_warp_queue.clear()
	_warp_active.clear()
	_warp_running = false
	if _warp_rect:
		_warp_rect.visible = false
	set_process(false)

func _init_warp_overlay() -> void:
	if _warp_rect or not WARP_SHADER:
		return

	_warp_rng.randomize()

	if not is_instance_valid(_warp_layer):
		_warp_layer = get_node_or_null("Warp")
		if not _warp_layer:
			_warp_layer = CanvasLayer.new()
			_warp_layer.name = "Warp"
			add_child(_warp_layer)

	_warp_layer.layer = 200
	if _warp_layer.has_method("set_follow_viewport_enabled"):
		_warp_layer.set("follow_viewport_enabled", true)

	_warp_rect = _warp_layer.get_node_or_null("WarpOverlay") as ColorRect
	if not _warp_rect:
		_warp_rect = ColorRect.new()
		_warp_rect.name = "WarpOverlay"
		_warp_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_warp_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		_warp_layer.add_child(_warp_rect)

	_warp_rect.color = Color(1, 1, 1, 1)
	_warp_rect.visible = false
	_warp_rect.z_index = 999

	if not _warp_material:
		_warp_material = ShaderMaterial.new()
		_warp_material.shader = WARP_SHADER
	_warp_rect.material = _warp_material

	_update_warp_shader()

func _trigger_warp_burst(reset_existing: bool = true) -> void:
	if not _warp_material:
		return

	if reset_existing:
		_warp_queue.clear()
		_warp_active.clear()

	var delay := 0.0
	var pool := WARP_PATTERN_PRESETS.duplicate()
	for i in range(WARP_MAX_WAVES):
		if pool.is_empty():
			pool = WARP_PATTERN_PRESETS.duplicate()
		var preset_index := _warp_rng.randi_range(0, pool.size() - 1)
		var preset: Dictionary = pool.pop_at(preset_index)
		var wave := _make_wave_from_preset(preset)
		wave["start_delay"] = delay
		delay += _warp_rng.randf_range(WARP_DELAY_RANGE.x, WARP_DELAY_RANGE.y)
		_warp_queue.append(wave)

	_warp_material.set_shader_parameter("global_intensity", _rand_range(WARP_GLOBAL_INTENSITY_RANGE))
	_warp_material.set_shader_parameter("chroma_shift", _rand_range(WARP_GLOBAL_CHROMA_RANGE))
	_warp_material.set_shader_parameter("edge_safety", _rand_range(WARP_GLOBAL_EDGE_RANGE))
	_warp_material.set_shader_parameter("glow_strength", _rand_range(WARP_GLOW_RANGE))
	_warp_material.set_shader_parameter("glow_color", _rand_glow_color())
	_warp_material.set_shader_parameter("glitch_amount", _rand_range(WARP_GLITCH_RANGE))

	_warp_running = true
	if _warp_rect:
		_warp_rect.visible = true
	set_process(true)
	_update_warp_shader()

func _make_wave_from_preset(preset: Dictionary) -> Dictionary:
	var center := Vector2(_warp_rng.randf_range(-0.55, 1.55), _warp_rng.randf_range(-0.45, 1.45))
	var angle := deg_to_rad(_warp_rng.randf_range(0.0, 360.0))
	var amplitude := _rand_range(preset.get("amplitude", Vector2(0.02, 0.04))) * _rand_range(WARP_AMPLITUDE_BOOST_RANGE)
	var base_radius: float = _rand_range(preset.get("radius", Vector2(0.9, 1.25)))
	var radius: float = max(1.2, base_radius * _rand_range(WARP_RADIUS_BOOST_RANGE))
	var pinch := _rand_range(preset.get("pinch", Vector2(0.01, 0.03))) * _rand_range(WARP_PINCH_BOOST_RANGE)
	var aspect := _rand_range(preset.get("aspect", Vector2(0.6, 1.4)))
	var dispersion: float = max(2.5, _rand_range(preset.get("dispersion", Vector2(7.0, 11.0))) * _rand_range(WARP_DISPERSION_SCALE))
	var speed := _rand_range(preset.get("speed", Vector2(1.5, 2.3))) * _rand_range(WARP_SPEED_MULT_RANGE)

	return {
		"center": center,
		"angle": angle,
		"amplitude": amplitude,
		"radius": radius,
		"pinch": pinch,
		"aspect": aspect,
		"dispersion": dispersion,
		"speed": speed,
		"progress": 0.0,
		"start_delay": 0.0
	}

func _rand_range(range: Vector2) -> float:
	return _warp_rng.randf_range(range.x, range.y)

func _rand_glow_color() -> Color:
	var hue := _warp_rng.randf()
	var sat := _warp_rng.randf_range(0.55, 0.95)
	var val := _warp_rng.randf_range(0.85, 1.0)
	return Color.from_hsv(hue, sat, val)

func _update_warp_shader() -> void:
	if not _warp_material:
		return

	var centers: PackedVector2Array = PackedVector2Array()
	var angles: PackedFloat32Array = PackedFloat32Array()
	var amplitudes: PackedFloat32Array = PackedFloat32Array()
	var radii: PackedFloat32Array = PackedFloat32Array()
	var pinches: PackedFloat32Array = PackedFloat32Array()
	var aspects: PackedFloat32Array = PackedFloat32Array()
	var progresses: PackedFloat32Array = PackedFloat32Array()
	var dispersions: PackedFloat32Array = PackedFloat32Array()

	var active_count: int = _warp_active.size()
	if active_count > WARP_MAX_WAVES:
		active_count = WARP_MAX_WAVES
	for i in range(WARP_MAX_WAVES):
		if i < active_count:
			var wave: Dictionary = _warp_active[i]
			centers.append(wave["center"])
			angles.append(wave["angle"])
			amplitudes.append(wave["amplitude"])
			radii.append(wave["radius"])
			pinches.append(wave["pinch"])
			aspects.append(wave["aspect"])
			progresses.append(clamp(wave["progress"], 0.0, 1.0))
			dispersions.append(wave["dispersion"])
		else:
			centers.append(Vector2.ZERO)
			angles.append(0.0)
			amplitudes.append(0.0)
			radii.append(0.0)
			pinches.append(0.0)
			aspects.append(1.0)
			progresses.append(0.0)
			dispersions.append(1.0)

	_warp_material.set_shader_parameter("wave_count", active_count)
	_warp_material.set_shader_parameter("wave_centers", centers)
	_warp_material.set_shader_parameter("wave_angles", angles)
	_warp_material.set_shader_parameter("wave_amplitudes", amplitudes)
	_warp_material.set_shader_parameter("wave_radius", radii)
	_warp_material.set_shader_parameter("wave_pinch", pinches)
	_warp_material.set_shader_parameter("wave_aspect", aspects)
	_warp_material.set_shader_parameter("wave_progress", progresses)
	_warp_material.set_shader_parameter("wave_dispersion", dispersions)

func _is_hash_key(event: InputEventKey) -> bool:
	return event.unicode == HASH_KEYCODE or event.keycode == HASH_KEYCODE or event.physical_keycode == HASH_KEYCODE
