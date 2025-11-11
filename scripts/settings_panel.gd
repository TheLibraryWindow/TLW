extends Panel

signal closed
signal minimized
signal maximized

@onready var topbar: ColorRect     = $TopBar
@onready var title_label: Label    = $TopBar/TitleLabel
@onready var close_btn: Button     = $TopBar/CloseBtn
@onready var min_btn: Button       = $TopBar/MinBtn
@onready var max_btn: Button       = $TopBar/MaxBtn

var _dragging := false
var _drag_offset := Vector2.ZERO
var _is_maximized := false
var _saved_rect := Rect2()


func _ready() -> void:
	_apply_neon_style()
	set_anchors_preset(Control.PRESET_TOP_LEFT)

	if topbar and not topbar.gui_input.is_connected(_on_topbar_gui_input):
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
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging = true
				_drag_offset = global_position - event.global_position
				topbar.mouse_filter = Control.MOUSE_FILTER_STOP
			else:
				_dragging = false
				topbar.mouse_filter = Control.MOUSE_FILTER_PASS
	elif event is InputEventMouseMotion and _dragging and not _is_maximized:
		var target: Vector2 = event.global_position + _drag_offset
		var vp_size: Vector2 = get_viewport_rect().size
		var panel_size: Vector2 = size
		target.x = clamp(target.x, 0.0, max(0.0, vp_size.x - panel_size.x))
		target.y = clamp(target.y, 0.0, max(0.0, vp_size.y - panel_size.y))
		global_position = target


# === BUTTONS ===
func _on_close_pressed() -> void:
	visible = false
	emit_signal("closed")

func _on_min_pressed() -> void:
	visible = false
	emit_signal("minimized")

func _on_max_pressed() -> void:
	if _is_maximized:
		# --- Restore original position and size ---
		global_position = _saved_rect.position
		size = _saved_rect.size

		# restore topbar to normal width
		if topbar:
			topbar.anchor_right = 0
			topbar.offset_right = 0

		_is_maximized = false
	else:
		# --- Save current position and size ---
		_saved_rect = Rect2(global_position, size)
		var vp_size = get_viewport_rect().size

		# maximize to full screen
		global_position = Vector2.ZERO
		size = vp_size

		# stretch the top bar horizontally
		if topbar:
			topbar.anchor_right = 1
			topbar.offset_right = 0

		_is_maximized = true

	emit_signal("maximized", _is_maximized)


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
