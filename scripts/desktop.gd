extends Control

# === NODES ===
@onready var seed_label: Label       = $SeedLabel
@onready var reset_btn: Button       = $ResetNewBtn
@onready var start_button: Button    = $StartButton
@onready var start_menu: Panel       = $StartMenu
@onready var settings_panel: Panel   = $SettingsPanel
@onready var taskbar: Panel          = $Taskbar
@onready var taskbar_container: HBoxContainer = $Taskbar/HBoxContainer
@onready var settings_task_btn: Button = $Taskbar/HBoxContainer/SettingsTaskBtn

var world: Node = null
var open_windows := {}   # {"Settings": settings_panel}


# === READY ===
func _ready() -> void:
	print("[DESKTOP] Ready – Start Menu + Settings + Taskbar active.")

	# --- Locate world node ---
	world = get_tree().root.get_node_or_null("Main/World")
	if world == null:
		world = get_tree().root.find_child("World", true, false)

	# --- Connect Start button ---
	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)

	# --- Connect Settings button in Start Menu ---
	var settings_btn := $StartMenu/VBoxContainer/SettingsButton
	if settings_btn:
		settings_btn.pressed.connect(_on_settings_pressed)

	# --- Connect Reset button ---
	if reset_btn:
		reset_btn.disabled = false
		if not reset_btn.pressed.is_connected(_on_reset_pressed):
			reset_btn.pressed.connect(_on_reset_pressed)

	# --- Connect Taskbar button ---
	if settings_task_btn:
		settings_task_btn.visible = false
		if not settings_task_btn.pressed.is_connected(_on_taskbar_settings_pressed):
			settings_task_btn.pressed.connect(_on_taskbar_settings_pressed)

	# --- Connect SettingsPanel signals ---
	if settings_panel:
		if not settings_panel.closed.is_connected(_on_settings_closed):
			settings_panel.closed.connect(_on_settings_closed)
		if not settings_panel.minimized.is_connected(_on_settings_minimized):
			settings_panel.minimized.connect(_on_settings_minimized)
		if not settings_panel.maximized.is_connected(_on_settings_maximized):
			settings_panel.maximized.connect(_on_settings_maximized)

	# --- Apply TLW neon theme ---
	_apply_neon_theme()

	# --- Hide start menu + settings on load ---
	start_menu.visible = false
	settings_panel.visible = false


# === START MENU HANDLER ===
func _on_start_button_pressed() -> void:
	start_menu.visible = !start_menu.visible


# === SETTINGS OPEN ===
func _on_settings_pressed() -> void:
	start_menu.visible = false
	if settings_panel:
		settings_panel.visible = true
		settings_panel.global_position = Vector2(320, 200)
		_register_window("Settings", settings_panel)
		print("[DESKTOP] Settings opened.")
	else:
		push_warning("[DESKTOP] SettingsPanel not found.")


# === SETTINGS MINIMIZED ===
func _on_settings_minimized() -> void:
	if settings_panel:
		settings_panel.visible = false
	print("[DESKTOP] Settings minimized (still active in taskbar).")


# === SETTINGS MAXIMIZED ===
func _on_settings_maximized(is_maximized: bool) -> void:
	if is_maximized:
		print("[DESKTOP] Settings maximized to full viewport.")
	else:
		print("[DESKTOP] Settings restored to normal size.")


# === SETTINGS CLOSED ===
func _on_settings_closed() -> void:
	if settings_task_btn:
		settings_task_btn.visible = false
	print("[DESKTOP] Settings closed – taskbar button hidden.")
	if open_windows.has("Settings"):
		open_windows.erase("Settings")


# === SETTINGS TASKBAR BUTTON (MINIMIZE / RESTORE) ===
func _on_taskbar_settings_pressed() -> void:
	if settings_panel:
		settings_panel.visible = not settings_panel.visible
		print("[DESKTOP] Settings toggled from taskbar.")


# === REGISTER WINDOW TO TASKBAR ===
func _register_window(name: String, panel: Control) -> void:
	open_windows[name] = panel
	var btn_path = "Taskbar/HBoxContainer/" + name + "TaskBtn"
	var btn := get_node_or_null(btn_path)
	if btn:
		btn.text = name
		btn.visible = true
		btn.add_theme_color_override("font_color", Color(0, 1, 0))
	else:
		push_warning("[DESKTOP] Taskbar button not found for " + name)


# === RESET BUTTON ===
func _on_reset_pressed() -> void:
	if world and world.has_method("reset_world"):
		world.reset_world(true)
		print("[DESKTOP] Reset pressed – new seed requested.")
	else:
		print("[DESKTOP] Reset pressed but no world yet.")


# === CLICK OUTSIDE HIDES MENUS ===
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if start_menu.visible:
			if not start_menu.get_global_rect().has_point(event.position) \
			and not start_button.get_global_rect().has_point(event.position):
				start_menu.visible = false


# === TLW NEON THEME ===
func _apply_neon_theme() -> void:
	# --- Start button ---
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

	# --- Start menu ---
	if start_menu:
		var menu_box := StyleBoxFlat.new()
		menu_box.bg_color = Color(0, 0, 0)
		menu_box.border_color = Color(0, 1, 0)
		menu_box.set_border_width_all(2)
		start_menu.add_theme_stylebox_override("panel", menu_box)

	# --- Settings panel ---
	if settings_panel:
		var settings_box := StyleBoxFlat.new()
		settings_box.bg_color = Color(0, 0, 0)
		settings_box.border_color = Color(0, 1, 0)
		settings_box.set_border_width_all(2)
		settings_panel.add_theme_stylebox_override("panel", settings_box)

		# Top bar neon + title
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

	# --- Taskbar ---
	if taskbar:
		var bar_box := StyleBoxFlat.new()
		bar_box.bg_color = Color(0, 0, 0)
		bar_box.border_color = Color(0, 1, 0)
		bar_box.set_border_width_all(2)
		taskbar.add_theme_stylebox_override("panel", bar_box)

	# --- Taskbar button (SettingsTaskBtn) ---
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
