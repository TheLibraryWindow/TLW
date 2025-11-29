extends Control

# === CONSTANTS ===
const WORK_PANEL_DEFAULT_PATH := "res://scenes/WorkPanel.tscn"


# === NODES ===
@onready var seed_label: Label       = $SeedLabel
@onready var reset_btn: Button       = $ResetNewBtn
@onready var start_button: Button    = $StartButton
@onready var start_menu: Panel       = $StartMenu
@onready var settings_panel: Panel   = $SettingsPanel
@onready var taskbar: Panel          = $Taskbar
@onready var taskbar_container: HBoxContainer = $Taskbar/HBoxContainer
@onready var settings_task_btn: Button = $Taskbar/HBoxContainer/SettingsTaskBtn
@onready var work_menu_btn: Button = $StartMenu/VBoxContainer/WorkButton

const DEFAULT_STARTUP_SOUND := "res://audio/startupsounds/startup1.wav"

@export var work_panel_scene: PackedScene

var world: Node = null
var open_windows := {}   # {"Settings": settings_panel}
var taskbar_buttons := {}
var active_user_profile: Dictionary = {}
var startup_sound_player: AudioStreamPlayer = null
var work_panel: Control = null


# === READY ===
func _ready() -> void:
	print("[DESKTOP] Ready – Start Menu + Settings + Taskbar active.")

	# --- Load fallback WorkPanel scene if not assigned ---
	if work_panel_scene == null and ResourceLoader.exists(WORK_PANEL_DEFAULT_PATH):
		work_panel_scene = load(WORK_PANEL_DEFAULT_PATH)

	# --- Locate world node ---
	world = get_tree().root.get_node_or_null("Main/World")
	if world == null:
		world = get_tree().root.find_child("World", true, false)

	# --- Connect Start button ---
	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)

	# --- Connect Work button ---
	if work_menu_btn:
		work_menu_btn.pressed.connect(_on_work_pressed)

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
		taskbar_buttons["Settings"] = settings_task_btn
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
	_ensure_work_panel_instance()

	_ensure_startup_sound_player()
	_hydrate_user_profile()


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
	_on_taskbar_button_pressed("Settings")


# === REGISTER WINDOW TO TASKBAR ===
func _register_window(name: String, panel: Control) -> void:
	if panel == null:
		return
	open_windows[name] = panel
	var btn := _ensure_taskbar_button(name)
	if btn:
		btn.text = name
		btn.visible = true
	else:
		push_warning("[DESKTOP] Taskbar button not found for " + name)


func _ensure_taskbar_button(name: String) -> Button:
	if taskbar_container == null:
		return null
	if taskbar_buttons.has(name):
		return taskbar_buttons[name]

	var existing := taskbar_container.get_node_or_null(name + "TaskBtn") as Button
	var btn := existing if existing else Button.new()
	btn.name = name + "TaskBtn"
	btn.visible = false
	_apply_taskbar_button_theme(btn)

	var callable := Callable(self, "_on_taskbar_button_pressed").bind(name)
	if not btn.pressed.is_connected(callable):
		btn.pressed.connect(callable)

	if existing == null:
		taskbar_container.add_child(btn)

	taskbar_buttons[name] = btn
	return btn


func _on_taskbar_button_pressed(window_name: String) -> void:
	var panel := open_windows.get(window_name, null) as Control
	if panel == null:
		push_warning("[DESKTOP] Taskbar toggle requested for missing window: %s" % window_name)
		return

	if panel.visible:
		if panel.has_method("hide_panel"):
			panel.hide_panel()
		else:
			panel.visible = false
	else:
		if panel.has_method("show_panel"):
			panel.show_panel()
		else:
			panel.visible = true
	print("[DESKTOP] %s toggled from taskbar." % window_name)


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
		_apply_taskbar_button_theme(settings_task_btn)


# === USER PROFILE / STARTUP SOUND ===
func _ensure_startup_sound_player() -> void:
	if startup_sound_player and is_instance_valid(startup_sound_player):
		return
	startup_sound_player = get_node_or_null("StartupSoundPlayer")
	if startup_sound_player == null:
		startup_sound_player = AudioStreamPlayer.new()
		startup_sound_player.name = "StartupSoundPlayer"
		add_child(startup_sound_player)


func _hydrate_user_profile() -> void:
	active_user_profile = {
		"username": "",
		"password": "",
		"icon_index": 0,
		"startup_sound_path": ""
	}

	if Engine.has_singleton("UserData"):
		active_user_profile["username"] = str(UserData.username)
		active_user_profile["password"] = str(UserData.password)
		active_user_profile["icon_index"] = int(UserData.icon_index)
		active_user_profile["startup_sound_path"] = str(UserData.startup_sound_path)
	else:
		push_warning("[DESKTOP] UserData singleton missing; falling back to defaults.")

	var username := String(active_user_profile.get("username", ""))
	if username.is_empty():
		print("[DESKTOP] No authenticated user detected – using guest profile.")
	else:
		print("[DESKTOP] Active user profile loaded for:", username)

	_play_user_startup_sound()


func _play_user_startup_sound() -> void:
	if startup_sound_player == null:
		return

	var sound_path := String(active_user_profile.get("startup_sound_path", ""))
	if sound_path.is_empty():
		sound_path = DEFAULT_STARTUP_SOUND

	if sound_path.is_empty():
		return

	var stream := load(sound_path)
	if stream is AudioStream:
		startup_sound_player.stop()
		startup_sound_player.stream = stream
		startup_sound_player.play()
		print("[DESKTOP] Startup sound playing from:", sound_path)
	else:
		push_warning("[DESKTOP] Failed to load startup sound at: %s" % sound_path)


func get_active_user_profile() -> Dictionary:
	return active_user_profile.duplicate()


# === WORK PANEL SUPPORT ===
func _ensure_work_panel_instance() -> void:
	if is_instance_valid(work_panel):
		return

	if has_node("WorkPanel"):
		work_panel = $WorkPanel
	elif work_panel_scene:
		work_panel = work_panel_scene.instantiate()
		work_panel.name = "WorkPanel"
		add_child(work_panel)
	else:
		return

	work_panel.visible = false
	_connect_work_panel_signals()


func _connect_work_panel_signals() -> void:
	if work_panel == null:
		return

	if work_panel.has_signal("panel_visibility_changed") and not work_panel.panel_visibility_changed.is_connected(_on_work_panel_visibility_changed):
		work_panel.panel_visibility_changed.connect(_on_work_panel_visibility_changed)

	if work_panel.has_signal("collapsed_changed") and not work_panel.collapsed_changed.is_connected(_on_work_panel_collapsed_changed):
		work_panel.collapsed_changed.connect(_on_work_panel_collapsed_changed)


func _on_work_pressed() -> void:
	start_menu.visible = false
	_ensure_work_panel_instance()

	if work_panel == null:
		push_warning("[DESKTOP] Work panel could not be loaded.")
		return

	if work_panel.has_method("show_panel"):
		work_panel.show_panel()
	else:
		work_panel.visible = true

	_register_window("Work", work_panel)


func _on_work_panel_visibility_changed(is_visible: bool) -> void:
	var btn := _ensure_taskbar_button("Work")
	if btn:
		btn.visible = is_visible

	if is_visible:
		_register_window("Work", work_panel)
	else:
		if open_windows.has("Work"):
			open_windows.erase("Work")


func _on_work_panel_collapsed_changed(is_collapsed: bool) -> void:
	print("[DESKTOP] Work panel collapsed: ", is_collapsed)


func _apply_taskbar_button_theme(btn: Button) -> void:
	if btn == null:
		return
	btn.add_theme_color_override("font_color", Color(0, 1, 0))
	btn.add_theme_color_override("font_hover_color", Color(0.3, 1, 0.3))
	var tb_box := StyleBoxFlat.new()
	tb_box.bg_color = Color(0, 0, 0)
	tb_box.border_color = Color(0, 1, 0)
	tb_box.set_border_width_all(1)
	tb_box.content_margin_left = 8
	tb_box.content_margin_right = 8
	tb_box.content_margin_top = 4
	tb_box.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", tb_box)
	btn.add_theme_stylebox_override("hover", tb_box)
	btn.add_theme_stylebox_override("pressed", tb_box)
