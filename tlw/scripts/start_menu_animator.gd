extends Panel

@export var entry_delay_step: float = 0.05
@export var entry_random_jitter: Vector2 = Vector2(0.0, 0.08)
@export var entry_pre_scale: Vector2 = Vector2(0.35, 0.65)
@export var travel_duration: float = 0.32
@export var fade_duration: float = 0.16
@export var fade_delay_step: float = 0.02
@export var pop_scale: float = 1.25
@export var pop_release_delay: float = 0.18
@export var scatter_rotation_range: float = 10.0
@export var burst_distance: Vector2 = Vector2(0.32, 0.24)
@export var safe_frame_size: Vector2 = Vector2(1280.0, 720.0)
@export var frame_padding: Vector2 = Vector2(32.0, 32.0)

var _buttons: Array[Button] = []
var _base_colors: Dictionary = {}
var _rest_positions: Dictionary = {}
var _active_tweens: Array[Tween] = []
var _rng := RandomNumberGenerator.new()
var _frame_size: Vector2 = Vector2(1280.0, 720.0)


func _ready() -> void:
	_rng.randomize()
	_cache_buttons()
	_update_frame_size()
	var viewport := get_viewport()
	if viewport and not viewport.size_changed.is_connected(_on_viewport_resized):
		viewport.size_changed.connect(_on_viewport_resized)


func play_open_sequence() -> void:
	_update_frame_size()
	_ensure_buttons_cached()
	if _buttons.is_empty():
		return

	_capture_rest_positions()
	_kill_all_tweens()
	_prepare_buttons_for_open()

	for idx in _buttons.size():
		var button := _buttons[idx]
		var delay := float(idx) * entry_delay_step + _rng.randf_range(entry_random_jitter.x, entry_random_jitter.y)
		var overshoot := _rng.randf_range(1.06, 1.14)
		var rest_position := _rest_positions.get(button, button.global_position)

		var appear := _track_tween(create_tween())
		appear.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		appear.tween_property(button, "modulate:a", 1.0, 0.18).set_delay(delay)
		appear.parallel().tween_property(button, "global_position", rest_position, travel_duration).set_delay(delay)
		appear.parallel().tween_property(button, "scale", Vector2.ONE * overshoot, 0.22).set_delay(delay)

		var settle := _track_tween(create_tween())
		settle.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		settle.tween_property(button, "scale", Vector2.ONE, 0.12).set_delay(delay + 0.22)
		settle.parallel().tween_property(button, "rotation_degrees", 0.0, 0.12).set_delay(delay + 0.22)


func play_close_sequence(focus_control: Control = null) -> void:
	_ensure_buttons_cached()
	if _buttons.is_empty():
		return

	var selected := focus_control as Button

	_kill_all_tweens()
	if selected:
		_set_alpha(selected, 1.0)
		_play_selection_pop(selected)

	for idx in _buttons.size():
		var button := _buttons[idx]
		var delay := float(idx) * fade_delay_step
		if button == selected:
			delay += pop_release_delay

		var fade := _track_tween(create_tween())
		fade.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		fade.tween_property(button, "modulate:a", 0.0, fade_duration).set_delay(delay)
		fade.parallel().tween_property(button, "scale", Vector2.ONE * 0.82, fade_duration).set_delay(delay)


func _play_selection_pop(button: Button) -> void:
	var pop := _track_tween(create_tween())
	pop.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(button, "scale", Vector2.ONE * pop_scale, 0.14)
	pop.tween_property(button, "scale", Vector2.ONE, 0.16)


func _prepare_buttons_for_open() -> void:
	for button in _buttons:
		var rest_position := _rest_positions.get(button, button.global_position)
		var burst_point := _compute_burst_point(button, rest_position)
		button.global_position = burst_point
		var pre_scale := _rng.randf_range(entry_pre_scale.x, entry_pre_scale.y)
		button.scale = Vector2.ONE * pre_scale
		button.rotation_degrees = _rng.randf_range(-scatter_rotation_range, scatter_rotation_range)
		_set_alpha(button, 0.0)


func _cache_buttons() -> void:
	_buttons.clear()
	_base_colors.clear()

	var container := get_node_or_null("VBoxContainer")
	if container == null:
		return

	for child in container.get_children():
		var button := child as Button
		if button == null:
			continue
		button.pivot_offset = button.size * 0.5
		_buttons.append(button)
		_base_colors[button] = button.modulate


func _capture_rest_positions() -> void:
	_rest_positions.clear()
	for button in _buttons:
		_rest_positions[button] = button.global_position


func _ensure_buttons_cached() -> void:
	if _buttons.is_empty():
		_cache_buttons()


func _set_alpha(button: Button, alpha: float) -> void:
	var base_color: Color = _base_colors.get(button, button.modulate)
	button.modulate = Color(base_color.r, base_color.g, base_color.b, clamp(alpha, 0.0, 1.0))


func _track_tween(tween: Tween) -> Tween:
	if tween == null:
		return tween
	_active_tweens.append(tween)
	tween.finished.connect(func() -> void:
		_active_tweens.erase(tween)
	)
	return tween


func _kill_all_tweens() -> void:
	for tween in _active_tweens:
		if tween:
			tween.kill()
	_active_tweens.clear()


func _compute_burst_point(button: Button, rest_position: Vector2) -> Vector2:
	var button_size := button.size
	if button_size == Vector2.ZERO:
		button_size = button.get_combined_minimum_size()

	var horizontal_push := _rng.randf_range(0.18, burst_distance.x) * _frame_size.x
	var vertical_pull := -_rng.randf_range(0.08, burst_distance.y) * _frame_size.y
	var offset := Vector2(horizontal_push, vertical_pull)
	offset = offset.rotated(deg2rad(_rng.randf_range(-12.0, 42.0)))
	var candidate := rest_position + offset
	return _clamp_to_frame(candidate, button_size)


func _clamp_to_frame(point: Vector2, control_size: Vector2) -> Vector2:
	var min_bounds := frame_padding
	var max_bounds := _frame_size - control_size - frame_padding
	return Vector2(
		clamp(point.x, min_bounds.x, max_bounds.x),
		clamp(point.y, min_bounds.y, max_bounds.y)
	)


func _update_frame_size() -> void:
	var viewport_rect := get_viewport_rect()
	if viewport_rect.size != Vector2.ZERO:
		_frame_size = viewport_rect.size
	else:
		_frame_size = safe_frame_size


func _on_viewport_resized() -> void:
	_update_frame_size()
