extends Node2D

const WARP_SHADER := preload("res://scripts/psychedelic_warp.gdshader")
const WARP_MAX_WAVES := 3
const WARP_DELAY_RANGE := Vector2(0.08, 0.22)
const WARP_SPEED_RANGE := Vector2(0.08, 0.18)
const WARP_RADIUS_RANGE := Vector2(0.9, 1.6)
const WARP_RADIUS_BOOST := Vector2(1.2, 1.8)
const WARP_AMPLITUDE_RANGE := Vector2(0.015, 0.04)
const WARP_PINCH_RANGE := Vector2(0.008, 0.02)
const WARP_ASPECT_RANGE := Vector2(0.5, 1.2)
const WARP_DISPERSION_RANGE := Vector2(4.0, 7.0)
const INTRO_WARP_MIN_DELAY := 0.0
const INTRO_WARP_MAX_DELAY := 7.0

@onready var animation_player: AnimationPlayer = $Sprite2D/AnimationPlayer

signal logo_finished

var _warp_layer: CanvasLayer
var _warp_rect: ColorRect
var _warp_material: ShaderMaterial
var _warp_rng := RandomNumberGenerator.new()
var _warp_queue: Array[Dictionary] = []
var _warp_active: Array[Dictionary] = []
var _warp_running: bool = false

func _ready() -> void:
	print("[BOOTLOGO] Bootup logo started.")
	_warp_rng.randomize()
	_init_warp_overlay()
	_schedule_intro_warp()
	
	if animation_player and animation_player.has_animation("bootuplogo"):
		animation_player.play("bootuplogo")
		if not animation_player.animation_finished.is_connected(_on_animation_finished):
			animation_player.animation_finished.connect(_on_animation_finished)
	else:
		print("[BOOTLOGO] No animation found, skipping.")
		emit_signal("logo_finished")

func _process(delta: float) -> void:
	if not _warp_running:
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
		_stop_warp()
	else:
		_update_warp_shader()

func _schedule_intro_warp() -> void:
	var delay := INTRO_WARP_MIN_DELAY
	var timer := get_tree().create_timer(delay)
	timer.timeout.connect(_start_intro_warp)

func _start_intro_warp() -> void:
	if _warp_running or not _warp_material:
		return
	_trigger_warp_burst()
	if _warp_rect:
		_warp_rect.visible = true
	_warp_running = true
	set_process(true)

func _trigger_warp_burst() -> void:
	_warp_queue.clear()
	_warp_active.clear()

	var delay := 0.0
	for i in range(WARP_MAX_WAVES):
		var wave := _make_wave()
		wave["start_delay"] = delay
		delay += _warp_rng.randf_range(WARP_DELAY_RANGE.x, WARP_DELAY_RANGE.y)
		_warp_queue.append(wave)

	_update_warp_shader()

func _make_wave() -> Dictionary:
	var center := Vector2(_warp_rng.randf_range(-0.3, 1.3), _warp_rng.randf_range(-0.25, 1.25))
	var angle := deg_to_rad(_warp_rng.randf_range(0.0, 360.0))
	var amplitude := _warp_rng.randf_range(WARP_AMPLITUDE_RANGE.x, WARP_AMPLITUDE_RANGE.y)
	var radius_base := _warp_rng.randf_range(WARP_RADIUS_RANGE.x, WARP_RADIUS_RANGE.y)
	var radius := radius_base * _warp_rng.randf_range(WARP_RADIUS_BOOST.x, WARP_RADIUS_BOOST.y)
	var pinch := _warp_rng.randf_range(WARP_PINCH_RANGE.x, WARP_PINCH_RANGE.y)
	var aspect := _warp_rng.randf_range(WARP_ASPECT_RANGE.x, WARP_ASPECT_RANGE.y)
	var dispersion := _warp_rng.randf_range(WARP_DISPERSION_RANGE.x, WARP_DISPERSION_RANGE.y)
	var speed := _warp_rng.randf_range(WARP_SPEED_RANGE.x, WARP_SPEED_RANGE.y)

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

func _stop_warp() -> void:
	_warp_queue.clear()
	_warp_active.clear()
	_warp_running = false
	if _warp_rect:
		_warp_rect.visible = false
	set_process(false)

func _init_warp_overlay() -> void:
	if not WARP_SHADER:
		return

	_warp_layer = get_node_or_null("Warp")
	if not _warp_layer:
		_warp_layer = CanvasLayer.new()
		_warp_layer.name = "Warp"
		add_child(_warp_layer)

	_warp_rect = _warp_layer.get_node_or_null("WarpOverlay") as ColorRect
	if not _warp_rect:
		_warp_rect = ColorRect.new()
		_warp_rect.name = "WarpOverlay"
		_warp_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_warp_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		_warp_layer.add_child(_warp_rect)

	if not _warp_material:
		_warp_material = ShaderMaterial.new()
		_warp_material.shader = WARP_SHADER
	_warp_rect.material = _warp_material
	_warp_rect.visible = false

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

	var active_count: int = min(WARP_MAX_WAVES, _warp_active.size())
	for i in range(WARP_MAX_WAVES):
		if i < active_count:
			var wave := _warp_active[i]
			centers.append(wave["center"])
			angles.append(wave["angle"])
			amplitudes.append(wave["amplitude"])
			radii.append(wave["radius"])
			pinches.append(wave["pinch"])
			aspects.append(wave["aspect"])
			progresses.append(wave["progress"])
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

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "bootuplogo":
		print("[BOOTLOGO] Animation complete — loading next scene.")
		emit_signal("logo_finished")
		get_tree().change_scene_to_file("res://scenes/loginmenu.tscn")
