extends Control

signal collapsed_changed(is_collapsed: bool)
signal panel_visibility_changed(is_visible: bool)

@export var expanded_size := Vector2(900, 520)
@export var collapsed_size := Vector2(900, 160)
@export_range(0.05, 1.0, 0.01) var resize_time := 0.2

@export var min_button_path: NodePath = NodePath("MinBtn")
@export var max_button_path: NodePath = NodePath("MaxBtn")
@export var close_button_path: NodePath = NodePath("CloseBtn")
@export var body_container_path: NodePath = NodePath("TextureRect")
@export var question_label_path: NodePath = NodePath("Label")

var _is_collapsed := false
var _resize_tween: Tween

var _min_button: Button
var _max_button: Button
var _close_button: Button
var _body_container: Control
var _question_label: Label

func _ready() -> void:
	_set_initial_size()
	_cache_nodes()
	_connect_buttons()
	visible = false

func toggle_visibility() -> void:
	visible = not visible
	emit_signal("panel_visibility_changed", visible)

func show_panel() -> void:
	if not visible:
		visible = true
		emit_signal("panel_visibility_changed", true)

func hide_panel() -> void:
	if visible:
		visible = false
		emit_signal("panel_visibility_changed", false)

func show_question(text: String) -> void:
	if _question_label:
		_question_label.text = text
	if _is_collapsed:
		_on_max_pressed()
	show_panel()

func _set_initial_size() -> void:
	size = expanded_size
	custom_minimum_size = collapsed_size

func _cache_nodes() -> void:
	_min_button = _get_button(min_button_path)
	_max_button = _get_button(max_button_path)
	_close_button = _get_button(close_button_path)
	_body_container = _get_control(body_container_path)
	_question_label = _get_label(question_label_path)

func _get_button(path: NodePath) -> Button:
	if path == NodePath():
		return null
	return get_node_or_null(path) as Button

func _get_control(path: NodePath) -> Control:
	if path == NodePath():
		return null
	return get_node_or_null(path) as Control

func _get_label(path: NodePath) -> Label:
	if path == NodePath():
		return null
	return get_node_or_null(path) as Label

func _connect_buttons() -> void:
	if _min_button and not _min_button.pressed.is_connected(_on_min_pressed):
		_min_button.pressed.connect(_on_min_pressed)
	if _max_button and not _max_button.pressed.is_connected(_on_max_pressed):
		_max_button.pressed.connect(_on_max_pressed)
	if _close_button and not _close_button.pressed.is_connected(_on_close_pressed):
		_close_button.pressed.connect(_on_close_pressed)

func _on_min_pressed() -> void:
	if _is_collapsed:
		return
	_is_collapsed = true
	_update_body_visibility(false)
	_resize_to(collapsed_size)
	emit_signal("collapsed_changed", true)

func _on_max_pressed() -> void:
	if not _is_collapsed:
		return
	_is_collapsed = false
	_update_body_visibility(true)
	_resize_to(expanded_size)
	emit_signal("collapsed_changed", false)

func _on_close_pressed() -> void:
	hide_panel()

func _update_body_visibility(is_visible: bool) -> void:
	if _body_container:
		_body_container.visible = is_visible

func _resize_to(target_size: Vector2) -> void:
	if not is_inside_tree():
		size = target_size
		return
	if _resize_tween:
		_resize_tween.kill()
	_resize_tween = create_tween()
	_resize_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_resize_tween.tween_property(self, "size", target_size, resize_time)
