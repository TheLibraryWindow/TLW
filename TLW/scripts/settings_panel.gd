extends Panel

signal closed
signal minimized
signal maximized(is_maximized: bool)

@export var reserved_bottom_pixels := -1.0
@export var min_window_size := Vector2(420, 260)

const RESIZE_MARGIN := 10.0

@onready var topbar: ColorRect     = $TopBar
@onready var title_label: Label    = $TopBar/TitleLabel
@onready var close_btn: Button     = $TopBar/CloseBtn
@onready var min_btn: Button       = $TopBar/MinBtn
@onready var max_btn: Button       = $TopBar/MaxBtn


var _dragging := false
var _drag_offset := Vector2.ZERO
var _is_maximized := false
var _saved_layout: Dictionary = {}
var _resizing := false
var _resize_handle := Vector2.ZERO
var _resize_start_mouse := Vector2.ZERO
var _resize_start_rect := Rect2()


func _ready() -> void:
	_apply_neon_style()
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	if topbar:
		topbar.mouse_filter = Control.MOUSE_FILTER_STOP
		if not topbar.gui_input.is_connected(_on_topbar_gui_input):
			topbar.gui_input.connect(_on_topbar_gui_input)

	if close_btn and not close_btn.pressed.is_connected(_on_close_pressed):
		close_btn.pressed.connect(_on_close_pressed)
	if min_btn and not min_btn.pressed.is_connected(_on_min_pressed):
		min_btn.pressed.connect(_on_min_pressed)
	if max_btn and not max_btn.pressed.is_connected(_on_max_pressed):
		max_btn.pressed.connect(_on_max_pressed)

	visible = false


# === DRAG ===
func _on_topbar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if event.double_click:
				_on_max_pressed()
				_dragging = false
				_resizing = false
				accept_event()
				return
			if _is_maximized:
				return
			_dragging = true
			_drag_offset = global_position - event.global_position
			accept_event()
		else:
			_dragging = false
	elif event is InputEventMouseMotion and _dragging and not _is_maximized:
		var target: Vector2 = event.global_position + _drag_offset
		var vp_size: Vector2 = get_viewport_rect().size
		var panel_size: Vector2 = size
		var reserved_bottom := _get_bottom_reserved()

		target.x = clamp(target.x, 0.0, max(0.0, vp_size.x - panel_size.x))
		target.y = clamp(target.y, 0.0, max(0.0, vp_size.y - reserved_bottom - panel_size.y))

		global_position = target
		accept_event()


func _gui_input(event: InputEvent) -> void:
	if _is_maximized:
		_reset_resize_state()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var handle := _detect_resize_handle(event.position)
			if handle != Vector2.ZERO:
				_start_resize(handle, event.global_position)
				accept_event()
				return
		else:
			if _resizing:
				_finish_resize()
				accept_event()
				return
	elif event is InputEventMouseMotion:
		if _resizing:
			_apply_resize(event.global_position)
			accept_event()
			return
		else:
			var handle := _detect_resize_handle(event.position)
			_update_cursor_shape(handle)


func _input(event: InputEvent) -> void:
	if _resizing and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_finish_resize()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and not _resizing:
		_update_cursor_shape(Vector2.ZERO)


# === BUTTONS ===
func _on_close_pressed() -> void:
	visible = false
	_reset_resize_state()
	emit_signal("closed")


func _on_min_pressed() -> void:
	visible = false
	_reset_resize_state()
	emit_signal("minimized")


func _on_max_pressed() -> void:
	if _is_maximized:
		_restore_layout()
		_is_maximized = false
	else:
		_save_layout()
		_apply_maximize_layout()
		_is_maximized = true
		_dragging = false
		_reset_resize_state()

	emit_signal("maximized", _is_maximized)


# === LAYOUT HELPERS ===
func _save_layout() -> void:
	_saved_layout = {
		"anchor_left": anchor_left,
		"anchor_top": anchor_top,
		"anchor_right": anchor_right,
		"anchor_bottom": anchor_bottom,
		"offset_left": offset_left,
		"offset_top": offset_top,
		"offset_right": offset_right,
		"offset_bottom": offset_bottom,
		"position": global_position,
		"size": size
	}

	if topbar:
		_saved_layout["topbar_anchor_left"] = topbar.anchor_left
		_saved_layout["topbar_anchor_right"] = topbar.anchor_right
		_saved_layout["topbar_offset_left"] = topbar.offset_left
		_saved_layout["topbar_offset_right"] = topbar.offset_right


func _restore_layout() -> void:
	if _saved_layout.is_empty():
		return

	anchor_left = _saved_layout.get("anchor_left", anchor_left)
	anchor_top = _saved_layout.get("anchor_top", anchor_top)
	anchor_right = _saved_layout.get("anchor_right", anchor_right)
	anchor_bottom = _saved_layout.get("anchor_bottom", anchor_bottom)

	offset_left = _saved_layout.get("offset_left", offset_left)
	offset_top = _saved_layout.get("offset_top", offset_top)
	offset_right = _saved_layout.get("offset_right", offset_right)
	offset_bottom = _saved_layout.get("offset_bottom", offset_bottom)

	size = _saved_layout.get("size", size)
	global_position = _saved_layout.get("position", global_position)

	if topbar:
		topbar.anchor_left = _saved_layout.get("topbar_anchor_left", topbar.anchor_left)
		topbar.anchor_right = _saved_layout.get("topbar_anchor_right", topbar.anchor_right)
		topbar.offset_left = _saved_layout.get("topbar_offset_left", topbar.offset_left)
		topbar.offset_right = _saved_layout.get("topbar_offset_right", topbar.offset_right)

	_saved_layout.clear()


func _apply_maximize_layout() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var reserved_bottom: float = clampf(_get_bottom_reserved(), 0.0, get_viewport_rect().size.y)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = -reserved_bottom

	global_position = Vector2.ZERO
	if reserved_bottom > 0.0:
		size = Vector2(get_viewport_rect().size.x, get_viewport_rect().size.y - reserved_bottom)
	else:
		size = get_viewport_rect().size

	if topbar:
		topbar.anchor_left = 0.0
		topbar.anchor_right = 1.0
		topbar.offset_left = 0.0
		topbar.offset_right = 0.0


func _get_bottom_reserved() -> float:
	if reserved_bottom_pixels >= 0.0:
		return reserved_bottom_pixels

	var desktop := get_parent() as Control
	if desktop:
		var taskbar := desktop.get_node_or_null("Taskbar") as Control
		if taskbar:
			var height := taskbar.size.y
			if height <= 0.0:
				height = taskbar.custom_minimum_size.y
			if height <= 0.0:
				height = taskbar.get_combined_minimum_size().y
			if height > 0.0:
				return height

	return 0.0


func _detect_resize_handle(local_pos: Vector2) -> Vector2:
	var handle := Vector2.ZERO
	var margin := RESIZE_MARGIN

	if local_pos.x <= margin:
		handle.x = -1
	elif local_pos.x >= size.x - margin:
		handle.x = 1

	if local_pos.y <= margin:
		handle.y = -1
	elif local_pos.y >= size.y - margin:
		handle.y = 1

	return handle


func _start_resize(handle: Vector2, mouse_global: Vector2) -> void:
	_resizing = true
	_resize_handle = handle
	_resize_start_mouse = mouse_global
	_resize_start_rect = Rect2(global_position, size)
	_update_cursor_shape(handle)


func _apply_resize(mouse_global: Vector2) -> void:
	if not _resizing:
		return

	var delta := mouse_global - _resize_start_mouse
	var rect := _resize_start_rect

	if _resize_handle.x == -1:
		rect.position.x += delta.x
		rect.size.x -= delta.x
	elif _resize_handle.x == 1:
		rect.size.x += delta.x

	if _resize_handle.y == -1:
		rect.position.y += delta.y
		rect.size.y -= delta.y
	elif _resize_handle.y == 1:
		rect.size.y += delta.y

	rect = _enforce_min_size(rect)
	rect = _clamp_rect_to_viewport(rect)

	global_position = rect.position
	size = rect.size


func _finish_resize() -> void:
	_resizing = false
	_resize_handle = Vector2.ZERO
	_resize_start_mouse = Vector2.ZERO
	_resize_start_rect = Rect2()
	_update_cursor_shape(Vector2.ZERO)


func _reset_resize_state() -> void:
	if _resizing:
		_finish_resize()
	else:
		_update_cursor_shape(Vector2.ZERO)


func _enforce_min_size(rect: Rect2) -> Rect2:
	var min_size := min_window_size.max(get_combined_minimum_size())

	if rect.size.x < min_size.x:
		if _resize_handle.x == -1:
			rect.position.x -= (min_size.x - rect.size.x)
		rect.size.x = min_size.x

	if rect.size.y < min_size.y:
		if _resize_handle.y == -1:
			rect.position.y -= (min_size.y - rect.size.y)
		rect.size.y = min_size.y

	return rect


func _clamp_rect_to_viewport(rect: Rect2) -> Rect2:
	var vp_size := get_viewport_rect().size
	var reserved_bottom: float = clampf(_get_bottom_reserved(), 0.0, vp_size.y)
	var max_height := max(0.0, vp_size.y - reserved_bottom)

	if rect.position.x < 0.0:
		if _resize_handle.x == -1:
			rect.size.x += rect.position.x
		rect.position.x = 0.0

	if rect.position.y < 0.0:
		if _resize_handle.y == -1:
			rect.size.y += rect.position.y
		rect.position.y = 0.0

	var overflow_x := rect.position.x + rect.size.x - vp_size.x
	if overflow_x > 0.0:
		if _resize_handle.x == 1:
			rect.size.x -= overflow_x
		else:
			rect.position.x -= overflow_x

	var overflow_y := rect.position.y + rect.size.y - max_height
	if overflow_y > 0.0:
		if _resize_handle.y == 1:
			rect.size.y -= overflow_y
		else:
			rect.position.y -= overflow_y

	var min_size := min_window_size.max(get_combined_minimum_size())
	var max_width := max(vp_size.x, min_size.x)
	var max_allowed_height := max(max_height, min_size.y)
	rect.size.x = clampf(rect.size.x, min_size.x, max_width)
	rect.size.y = clampf(rect.size.y, min_size.y, max_allowed_height)

	rect.position.x = clampf(rect.position.x, 0.0, max(0.0, vp_size.x - rect.size.x))
	rect.position.y = clampf(rect.position.y, 0.0, max(0.0, max_height - rect.size.y))

	return rect


func _update_cursor_shape(handle: Vector2) -> void:
	var shape := Control.CURSOR_ARROW

	if handle != Vector2.ZERO:
		if handle.x != 0 and handle.y != 0:
			if handle.x == handle.y:
				shape = Control.CURSOR_FDIAGONAL
			else:
				shape = Control.CURSOR_BDIAGONAL
		elif handle.x != 0:
			shape = Control.CURSOR_HSIZE
		else:
			shape = Control.CURSOR_VSIZE

	mouse_default_cursor_shape = shape


# === THEME ===
func _apply_neon_style() -> void:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color(0, 0, 0)
	stylebox.border_color = Color(0, 1, 0)
	stylebox.set_border_width_all(2)
	add_theme_stylebox_override("panel", stylebox)

	if topbar:
		topbar.color = Color(0, 1, 0)

	if title_label:
		title_label.add_theme_color_override("font_color", Color(0, 0, 0))

	for b in [close_btn, min_btn, max_btn]:
		if b:
			b.add_theme_color_override("font_color", Color(0, 0, 0))
			b.flat = true
			b.focus_mode = Control.FOCUS_NONE
