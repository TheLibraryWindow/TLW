extends Control

# === PRIMARY NODES ===
@onready var seed_label: Label       = $SeedLabel
@onready var reset_btn: Button       = $ResetNewBtn
@onready var start_button: Button    = $StartButton
@onready var start_menu: Panel       = $StartMenu
@onready var start_menu_container: Control = start_menu.get_node_or_null("VBoxContainer") if start_menu else null
@onready var settings_panel: Panel   = $SettingsPanel
@onready var taskbar: Panel          = $Taskbar
@onready var taskbar_container: HBoxContainer = taskbar.get_node_or_null("HBoxContainer") if taskbar else null
@onready var settings_task_btn: Button = taskbar_container.get_node_or_null("SettingsTaskBtn") if taskbar_container else null

# === CONSTANTS ===
const START_MENU_ENTRY_DELAY := 0.05
const START_MENU_ENTRY_DURATION := 0.24
const START_MENU_ROTATION_START := -18.0

# === STATE ===
var world: Node = null
var open_windows: Dictionary = {}

var _start_menu_items: Array[Control] = []
var _start_menu_item_modulate: Dictionary = {}
var _start_menu_item_tweens: Array[Tween] = []
var _start_menu_tween: Tween = null
var _start_menu_default_modulate: Color = Color(1, 1, 1, 1)
var _start_menu_open: bool = false
var _start_menu_setup_done: bool = false


func _ready() -> void:
	print("[DESKTOP] Ready – Start Menu + Settings + Taskbar active.")

	_register_world_reference()

	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)

	var settings_btn: BaseButton = (start_menu_container.get_node_or_null("SettingsButton") if start_menu_container else null) as BaseButton
	if settings_btn:
		settings_btn.pressed.connect(_on_settings_pressed)

	if reset_btn:
		reset_btn.disabled = false
		if not reset_btn.pressed.is_connected(_on_reset_pressed):
			reset_btn.pressed.connect(_on_reset_pressed)

	if settings_task_btn:
		settings_task_btn.visible = false
		if not settings_task_btn.pressed.is_connected(_on_taskbar_settings_pressed):
			settings_task_btn.pressed.connect(_on_taskbar_settings_pressed)

	if settings_panel:
		if not settings_panel.closed.is_connected(_on_settings_closed):
			settings_panel.closed.connect(_on_settings_closed)
		if not settings_panel.minimized.is_connected(_on_settings_minimized):
			settings_panel.minimized.connect(_on_settings_minimized)
		if not settings_panel.maximized.is_connected(_on_settings_maximized):
			settings_panel.maximized.connect(_on_settings_maximized)

	if start_menu:
		start_menu.visible = false
		_start_menu_default_modulate = start_menu.modulate
		call_deferred("_finalize_start_menu_setup")

	_apply_neon_theme()


func _register_world_reference() -> void:
	world = get_tree().root.get_node_or_null("Main/World")
	if world == null:
		world = get_tree().root.find_child("World", true, false)

	if world and world.has_signal("seed_changed") and seed_label and not world.is_connected("seed_changed", Callable(self, "_on_seed_changed")):
		world.seed_changed.connect(_on_seed_changed)
		_on_seed_changed(world.get_seed() if world.has_method("get_seed") else 0)


func _finalize_start_menu_setup() -> void:
	if not start_menu or _start_menu_setup_done:
		return

	if start_menu.size == Vector2.ZERO:
		await get_tree().process_frame

	start_menu.pivot_offset = Vector2(0.0, start_menu.size.y)
	_collect_start_menu_items()
	_prepare_start_menu_items(false)
	start_menu.visible = false
	_start_menu_setup_done = true


# === START MENU ===
func _on_start_button_pressed() -> void:
	if _start_menu_open:
		_hide_start_menu_with_animation()
	else:
		_show_start_menu_with_animation()


func _show_start_menu_with_animation() -> void:
	if not start_menu or _start_menu_open:
		return

	_start_menu_open = true

	if not _start_menu_setup_done:
		await _finalize_start_menu_setup()

	_cancel_start_menu_tweens()

	start_menu.visible = true
	start_menu.scale = Vector2(0.9, 0.7)
	start_menu.pivot_offset = Vector2(0.0, start_menu.size.y if start_menu.size.y > 0.0 else start_menu.get_combined_minimum_size().y)
	_set_canvas_alpha(start_menu, 0.0, _start_menu_default_modulate)

	if _start_menu_items.is_empty():
		_collect_start_menu_items()

	_prepare_start_menu_items(true)

	_start_menu_tween = get_tree().create_tween()
	_start_menu_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_start_menu_tween.tween_property(start_menu, "scale", Vector2.ONE, 0.18)
	_start_menu_tween.parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).tween_property(start_menu, "modulate:a", 1.0, 0.14)

	var delay: float = 0.0
	for item in _start_menu_items:
		var base_color: Color = _start_menu_item_modulate.get(item, item.modulate)
		item.pivot_offset = item.size * 0.5
		_set_canvas_alpha(item, 0.0, base_color)
		item.scale = Vector2(0.7, 0.0)
		item.rotation_degrees = START_MENU_ROTATION_START

		var tween: Tween = get_tree().create_tween()
		tween.set_delay(delay)
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(item, "scale", Vector2.ONE, START_MENU_ENTRY_DURATION)
		tween.parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).tween_property(item, "modulate:a", 1.0, START_MENU_ENTRY_DURATION * 0.75)
		tween.parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).tween_property(item, "rotation_degrees", 0.0, START_MENU_ENTRY_DURATION)
		_start_menu_item_tweens.append(tween)

		delay += START_MENU_ENTRY_DELAY


func _hide_start_menu_with_animation() -> void:
	if not start_menu:
		return

	_start_menu_open = false

	_cancel_start_menu_tweens()

	if not start_menu.visible:
		return

	_start_menu_tween = get_tree().create_tween()
	_start_menu_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_start_menu_tween.tween_property(start_menu, "modulate:a", 0.0, 0.12)
	_start_menu_tween.parallel().tween_property(start_menu, "scale", Vector2(0.92, 0.85), 0.12)
	_start_menu_tween.finished.connect(func() -> void:
		start_menu.visible = false
		start_menu.scale = Vector2.ONE
		start_menu.modulate = _start_menu_default_modulate
		_prepare_start_menu_items(false)
	)


func _cancel_start_menu_tweens() -> void:
	if _start_menu_tween:
		_start_menu_tween.kill()
	_start_menu_tween = null

	for tween in _start_menu_item_tweens:
		if tween:
			tween.kill()
	_start_menu_item_tweens.clear()


func _collect_start_menu_items() -> void:
	_start_menu_items.clear()
	_start_menu_item_modulate.clear()

	if not start_menu_container:
		return

	_collect_menu_controls(start_menu_container)


func _collect_menu_controls(node: Node) -> void:
	for child in node.get_children():
		if child is BaseButton:
			var button := child as Control
			_start_menu_items.append(button)
			_start_menu_item_modulate[button] = button.modulate
		if child is Control and child.get_child_count() > 0:
			_collect_menu_controls(child)


func _prepare_start_menu_items(for_animation: bool) -> void:
	for item in _start_menu_items:
		var base_color: Color = _start_menu_item_modulate.get(item, item.modulate)
		if for_animation:
			item.pivot_offset = item.size * 0.5
			item.scale = Vector2(0.7, 0.0)
			item.rotation_degrees = START_MENU_ROTATION_START
			_set_canvas_alpha(item, 0.0, base_color)
		else:
			item.scale = Vector2.ONE
			item.rotation_degrees = 0.0
			_set_canvas_alpha(item, 1.0, base_color)


func _set_canvas_alpha(canvas_item: CanvasItem, alpha: float, base_color: Color) -> void:
	var color := base_color
	color.a = alpha
	canvas_item.modulate = color


# === SETTINGS EVENT HANDLERS ===
func _on_settings_pressed() -> void:
	_hide_start_menu_with_animation()

	if settings_panel:
		settings_panel.visible = true
		settings_panel.global_position = Vector2(320, 200)
		_register_window("Settings", settings_panel)
		print("[DESKTOP] Settings opened.")
	else:
		push_warning("[DESKTOP] SettingsPanel not found.")


func _on_settings_minimized() -> void:
	if settings_panel:
		settings_panel.visible = false
	print("[DESKTOP] Settings minimized (still active in taskbar).")


func _on_settings_maximized(is_maximized: bool) -> void:
	if is_maximized:
		print("[DESKTOP] Settings maximized to full viewport.")
	else:
		print("[DESKTOP] Settings restored to normal size.")


func _on_settings_closed() -> void:
	if settings_task_btn:
		settings_task_btn.visible = false
	print("[DESKTOP] Settings closed – taskbar button hidden.")
	if open_windows.has("Settings"):
		open_windows.erase("Settings")


func _on_taskbar_settings_pressed() -> void:
	if settings_panel:
		settings_panel.visible = not settings_panel.visible
		print("[DESKTOP] Settings toggled from taskbar.")
		if settings_panel.visible and settings_panel.has_method("_reset_resize_state"):
			settings_panel.call("_reset_resize_state")


func _register_window(name: String, panel: Control) -> void:
	open_windows[name] = panel
	var btn_path := "Taskbar/HBoxContainer/%sTaskBtn" % name
	var btn: Button = get_node_or_null(btn_path) as Button
	if btn:
		btn.text = name
		btn.visible = true
		btn.add_theme_color_override("font_color", Color(0, 1, 0))
	else:
		push_warning("[DESKTOP] Taskbar button not found for " + name)


# === START MENU AUTO CLOSE ===
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if start_menu and start_menu.visible:
			var clicked_inside_menu := start_menu.get_global_rect().has_point(event.position)
			var clicked_start_button := start_button and start_button.get_global_rect().has_point(event.position)
			if not clicked_inside_menu and not clicked_start_button:
				_hide_start_menu_with_animation()


# === RESET BUTTON ===
func _on_reset_pressed() -> void:
	if world and world.has_method("reset_world"):
		world.reset_world(true)
		print("[DESKTOP] Reset pressed – new seed requested.")
	else:
		print("[DESKTOP] Reset pressed but no world yet.")


func _on_seed_changed(new_seed: int) -> void:
	if seed_label:
		seed_label.text = "Seed: %s" % str(new_seed)


# === TLW NEON THEME ===
func _apply_neon_theme() -> void:
	if start_button:
		for color_name in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color"]:
			start_button.add_theme_color_override(color_name, Color(0, 1, 0))
		var btn_box := StyleBoxFlat.new()
		btn_box.bg_color = Color(0, 0, 0)
		btn_box.border_color = Color(0, 1, 0)
		btn_box.set_border_width_all(1)
		start_button.add_theme_stylebox_override("normal", btn_box)
		start_button.add_theme_stylebox_override("hover", btn_box)
		start_button.add_theme_stylebox_override("pressed", btn_box)

	if start_menu:
		var menu_box := StyleBoxFlat.new()
		menu_box.bg_color = Color(0, 0, 0)
		menu_box.border_color = Color(0, 1, 0)
		menu_box.set_border_width_all(2)
		start_menu.add_theme_stylebox_override("panel", menu_box)

	if settings_panel:
		var settings_box := StyleBoxFlat.new()
		settings_box.bg_color = Color(0, 0, 0)
		settings_box.border_color = Color(0, 1, 0)
		settings_box.set_border_width_all(2)
		settings_panel.add_theme_stylebox_override("panel", settings_box)

		var topbar := settings_panel.get_node_or_null("TopBar")
		if topbar:
			topbar.color = Color(0, 1, 0)
		var title := settings_panel.get_node_or_null("TopBar/TitleLabel")
		if title:
			title.add_theme_color_override("font_color", Color(0, 0, 0))
		for btn_name in ["CloseBtn", "MinBtn", "MaxBtn"]:
			var btn := settings_panel.get_node_or_null("TopBar/" + btn_name)
			if btn:
				btn.add_theme_color_override("font_color", Color(0, 0, 0))

	if taskbar:
		var bar_box := StyleBoxFlat.new()
		bar_box.bg_color = Color(0, 0, 0)
		bar_box.border_color = Color(0, 1, 0)
		bar_box.set_border_width_all(2)
		taskbar.add_theme_stylebox_override("panel", bar_box)

	if settings_task_btn:
		settings_task_btn.add_theme_color_override("font_color", Color(0, 1, 0))
		settings_task_btn.add_theme_color_override("font_hover_color", Color(0.3, 1, 0.3))
		var tb_box := StyleBoxFlat.new()
		tb_box.bg_color = Color(0, 0, 0)
		tb_box.border_color = Color(0, 1, 0)
		tb_box.set_border_width_all(1)
		tb_box.content_margin_left = 8
		tb_box.content_margin_right = 8
		tb_box.content_margin_top = 4
		tb_box.content_margin_bottom = 4
		settings_task_btn.add_theme_stylebox_override("normal", tb_box)
		settings_task_btn.add_theme_stylebox_override("hover", tb_box)
		settings_task_btn.add_theme_stylebox_override("pressed", tb_box)
