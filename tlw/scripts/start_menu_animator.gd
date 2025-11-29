extends Panel

@export var entry_delay_step: float = 0.05
@export var entry_random_jitter: Vector2 = Vector2(0.0, 0.08)
@export var entry_pre_scale: Vector2 = Vector2(0.35, 0.65)
@export var fade_duration: float = 0.16
@export var fade_delay_step: float = 0.02
@export var pop_scale: float = 1.25
@export var pop_release_delay: float = 0.18
@export var scatter_rotation_range: float = 10.0

var _buttons: Array[Button] = []
var _base_colors: Dictionary = {}
var _active_tweens: Array[Tween] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
    _rng.randomize()
    _cache_buttons()


func play_open_sequence() -> void:
    _ensure_buttons_cached()
    if _buttons.is_empty():
        return

    _kill_all_tweens()
    _prepare_buttons_for_open()

    for idx in _buttons.size():
        var button := _buttons[idx]
        var delay := float(idx) * entry_delay_step + _rng.randf_range(entry_random_jitter.x, entry_random_jitter.y)
        var overshoot := _rng.randf_range(1.06, 1.14)

        var appear := _track_tween(create_tween())
        appear.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        appear.tween_property(button, "modulate:a", 1.0, 0.18).set_delay(delay)
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
