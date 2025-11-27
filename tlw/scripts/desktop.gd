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
@onready var work_task_btn: Button = get_node_or_null("Taskbar/HBoxContainer/WorkTaskBtn") as Button
@onready var neon_background: ColorRect = get_node_or_null("NeonBackdrop") as ColorRect
@onready var glass_overlay: ColorRect = get_node_or_null("GlassOverlay") as ColorRect
@onready var work_panel: Panel = get_node_or_null("WorkPanel") as Panel
@onready var work_button: Button = get_node_or_null("StartMenu/VBoxContainer/WorkButton") as Button

const DEFAULT_STARTUP_SOUND := "res://audio/startupsounds/startup1.wav"
const ACCENT_COLOR := Color(0.0, 0.95, 0.68)
const ACCENT_SHADOW := Color(0.0, 0.9, 0.6, 0.42)
const PANEL_BG_COLOR := Color(0.02, 0.03, 0.05, 0.96)
const GLASS_BG_COLOR := Color(0.05, 0.08, 0.11, 0.88)
const ALIGN_LEFT := 0

var world: Node = null
var open_windows := {}   # {"Settings": settings_panel}
var active_user_profile: Dictionary = {}
var startup_sound_player: AudioStreamPlayer = null
var _background_material: ShaderMaterial = null
var _background_seed: float = 0.0
var _panel_tweens: Dictionary = {}
var _panel_states: Dictionary = {}
var _viewport_size: Vector2 = Vector2.ZERO


# === READY ===
func _ready() -> void:
	randomize()
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
	if work_button:
		if work_panel:
			work_button.disabled = false
			work_button.pressed.connect(_on_work_pressed)
		else:
			work_button.disabled = true

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
	if work_task_btn:
		work_task_btn.visible = false
		if not work_task_btn.pressed.is_connected(_on_taskbar_work_pressed):
			work_task_btn.pressed.connect(_on_taskbar_work_pressed)

	# --- Connect SettingsPanel signals ---
	if settings_panel:
		if not settings_panel.closed.is_connected(_on_settings_closed):
			settings_panel.closed.connect(_on_settings_closed)
		if not settings_panel.minimized.is_connected(_on_settings_minimized):
			settings_panel.minimized.connect(_on_settings_minimized)
		if not settings_panel.maximized.is_connected(_on_settings_maximized):
			settings_panel.maximized.connect(_on_settings_maximized)
	if work_panel:
		if not work_panel.closed.is_connected(_on_work_closed):
			work_panel.closed.connect(_on_work_closed)
		if not work_panel.minimized.is_connected(_on_work_minimized):
			work_panel.minimized.connect(_on_work_minimized)
		if not work_panel.maximized.is_connected(_on_work_maximized):
			work_panel.maximized.connect(_on_work_maximized)

	# --- Apply TLW neon theme ---
	_apply_neon_theme()
	_apply_background_effects()

	# --- Hide start menu + settings on load ---
	start_menu.visible = false
	settings_panel.visible = false
	_set_panel_state(start_menu, false)

	_ensure_startup_sound_player()
	_hydrate_user_profile()


# === START MENU HANDLER ===
func _on_start_button_pressed() -> void:
	_toggle_panel_with_tween(start_menu)


# === SETTINGS OPEN ===
func _on_settings_pressed() -> void:
	_hide_panel_with_tween(start_menu)
	_open_application_panel("Settings", settings_panel, Vector2(320, 200))


func _on_work_pressed() -> void:
	_hide_panel_with_tween(start_menu)
	_open_application_panel("Work", work_panel)


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


func _on_work_minimized() -> void:
	if work_panel:
		work_panel.visible = false
	print("[DESKTOP] Work minimized (still active in taskbar).")


func _on_work_maximized(is_maximized: bool) -> void:
	if is_maximized:
		print("[DESKTOP] Work panel maximized to full viewport.")
	else:
		print("[DESKTOP] Work panel restored to normal size.")


# === SETTINGS CLOSED ===
func _on_settings_closed() -> void:
	_handle_panel_closed("Settings", settings_task_btn)
	print("[DESKTOP] Settings closed – taskbar button hidden.")


func _on_work_closed() -> void:
	_handle_panel_closed("Work", work_task_btn)
	print("[DESKTOP] Work panel closed – taskbar button hidden.")


# === SETTINGS TASKBAR BUTTON (MINIMIZE / RESTORE) ===
func _on_taskbar_settings_pressed() -> void:
	_toggle_application_panel("Settings", settings_panel)
	print("[DESKTOP] Settings toggled from taskbar.")


func _on_taskbar_work_pressed() -> void:
	_toggle_application_panel("Work", work_panel)
	print("[DESKTOP] Work panel toggled from taskbar.")


# === REGISTER WINDOW TO TASKBAR ===
func _register_window(window_name: String, panel: Control) -> void:
	open_windows[window_name] = panel
	var btn_path = "Taskbar/HBoxContainer/" + window_name + "TaskBtn"
	var btn := get_node_or_null(btn_path)
	if btn:
		btn.text = window_name
		btn.visible = true
		btn.custom_minimum_size = Vector2(140, 40)
		_style_button(btn)
	else:
		push_warning("[DESKTOP] Taskbar button not found for " + window_name)


func _open_application_panel(window_name: String, panel: Control, position: Variant = null) -> void:
	if panel == null:
		push_warning("[DESKTOP] %s panel not found." % window_name)
		return
	if position is Vector2:
		panel.global_position = position
	if panel.has_method("show_panel"):
		panel.call("show_panel")
	else:
		panel.visible = true
	_register_window(window_name, panel)
	print("[DESKTOP] %s opened." % window_name)


func _toggle_application_panel(window_name: String, panel: Control) -> void:
	if panel == null:
		push_warning("[DESKTOP] %s panel not found." % window_name)
		return
	if panel.visible:
		if panel.has_method("hide_panel"):
			panel.call("hide_panel", true, "taskbar")
		else:
			panel.visible = false
	else:
		_open_application_panel(window_name, panel)


func _handle_panel_closed(window_name: String, task_button: Button) -> void:
	if task_button:
		task_button.visible = false
	if open_windows.has(window_name):
		open_windows.erase(window_name)


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
		if _get_panel_state(start_menu):
			if not start_menu.get_global_rect().has_point(event.position) \
			and not start_button.get_global_rect().has_point(event.position):
				_hide_panel_with_tween(start_menu)


# === TLW NEON THEME ===
func _apply_neon_theme() -> void:
	# --- Start button ---
	if start_button:
		start_button.custom_minimum_size = Vector2(168, 52)
		start_button.text = "◎  Start"
		_style_button(start_button, true)

	# --- Seed label + reset action ---
	if seed_label:
		seed_label.add_theme_color_override("font_color", ACCENT_COLOR.lightened(0.2))
		seed_label.add_theme_constant_override("outline_size", 1)
		seed_label.add_theme_color_override("font_outline_color", Color.BLACK)
	if reset_btn:
		_style_button(reset_btn)
		reset_btn.text = "Generate New Seed"
		reset_btn.custom_minimum_size = Vector2(190, 38)

	# --- Start menu ---
	if start_menu:
		var menu_box := _create_glass_stylebox(PANEL_BG_COLOR, 2, 18)
		start_menu.add_theme_stylebox_override("panel", menu_box)
		var menu_container := start_menu.get_node_or_null("VBoxContainer")
		if menu_container:
			menu_container.add_theme_constant_override("separation", 8)
			for child in menu_container.get_children():
				var btn := child as Button
				if btn:
					_align_button_left(btn)
					btn.custom_minimum_size = Vector2(0, 44)
					btn.add_theme_constant_override("h_separation", 12)
					_style_button(btn)

	# --- Settings panel ---
	if settings_panel:
		var settings_box := _create_glass_stylebox(PANEL_BG_COLOR, 2, 16)
		settings_panel.add_theme_stylebox_override("panel", settings_box)

		var topbar := settings_panel.get_node_or_null("TopBar")
		if topbar:
			topbar.color = ACCENT_COLOR
			topbar.modulate = Color(ACCENT_COLOR.r, ACCENT_COLOR.g, ACCENT_COLOR.b, 0.85)
		var title := settings_panel.get_node_or_null("TopBar/TitleLabel")
		if title:
			title.add_theme_color_override("font_color", Color(0, 0, 0))
		for btn_name in ["CloseBtn", "MinBtn", "MaxBtn"]:
			var btn := settings_panel.get_node_or_null("TopBar/" + btn_name)
			if btn:
				btn.flat = true
				btn.focus_mode = Control.FOCUS_NONE
				btn.add_theme_color_override("font_color", Color(0, 0, 0))
				btn.add_theme_color_override("font_hover_color", Color(0, 0, 0))

	# --- Taskbar ---
	if taskbar:
		var bar_box := _create_glass_stylebox(PANEL_BG_COLOR.darkened(0.15), 2, 20)
		bar_box.content_margin_left = 24
		bar_box.content_margin_right = 24
		taskbar.add_theme_stylebox_override("panel", bar_box)

	if taskbar_container:
		taskbar_container.add_theme_constant_override("separation", 12)

	# --- Taskbar button (SettingsTaskBtn) ---
	if settings_task_btn:
		settings_task_btn.custom_minimum_size = Vector2(140, 40)
		_style_button(settings_task_btn)
	if work_task_btn:
		work_task_btn.custom_minimum_size = Vector2(140, 40)
		_style_button(work_task_btn)


func _apply_background_effects() -> void:
	if neon_background:
		_background_material = neon_background.material as ShaderMaterial
		if _background_material:
			_background_seed = randf_range(0.0, 512.0)
			_viewport_size = get_viewport_rect().size
			_background_material.set_shader_parameter("seed", _background_seed)
			_background_material.set_shader_parameter("screen_size", _viewport_size)
			_background_material.set_shader_parameter("density", 2.4)
			_background_material.set_shader_parameter("twinkle_speed", 1.15)
			_background_material.set_shader_parameter("brightness", 1.3)
	if glass_overlay:
		glass_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glass_overlay.modulate = Color(1, 1, 1, 0.18)

	var viewport := get_viewport()
	if viewport and not viewport.size_changed.is_connected(_on_viewport_size_changed):
		viewport.size_changed.connect(_on_viewport_size_changed)


func _on_viewport_size_changed() -> void:
	_viewport_size = get_viewport_rect().size
	if _background_material:
		_background_material.set_shader_parameter("screen_size", _viewport_size)


func _create_glass_stylebox(bg_color: Color, border: int, radius: int) -> StyleBoxFlat:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = bg_color
	stylebox.border_color = ACCENT_COLOR
	stylebox.set_border_width_all(border)
	stylebox.corner_radius_bottom_left = radius
	stylebox.corner_radius_bottom_right = radius
	stylebox.corner_radius_top_left = radius
	stylebox.corner_radius_top_right = radius
	stylebox.shadow_size = 18
	stylebox.shadow_offset = Vector2(0, 8)
	stylebox.shadow_color = ACCENT_SHADOW
	stylebox.anti_aliasing = true
	return stylebox


func _style_button(button: Button, is_primary: bool = false) -> void:
	if button == null:
		return
	var base_color := (GLASS_BG_COLOR if is_primary else PANEL_BG_COLOR)
	var normal := _create_glass_stylebox(base_color, 2, 12)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover := normal.duplicate()
	hover.bg_color = hover.bg_color.lightened(0.08)
	var pressed := hover.duplicate()
	pressed.bg_color = hover.bg_color.darkened(0.18)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", ACCENT_COLOR)
	button.add_theme_color_override("font_hover_color", ACCENT_COLOR.lightened(0.12))
	button.add_theme_color_override("font_pressed_color", ACCENT_COLOR.darkened(0.15))
	button.focus_mode = Control.FOCUS_ALL


func _align_button_left(button: Button) -> void:
	if button == null:
		return
	if button.has_method("set_horizontal_alignment"):
		button.set("horizontal_alignment", ALIGN_LEFT)
	elif button.has_method("set_text_alignment"):
		button.set("text_alignment", ALIGN_LEFT)
	elif button.has_method("set_align"):
		button.call("set_align", ALIGN_LEFT)
	elif button.has_method("set_alignment"):
		button.call("set_alignment", ALIGN_LEFT)
	else:
		button.set("align", ALIGN_LEFT)


func _toggle_panel_with_tween(panel: Control) -> void:
	if panel == null:
		return
	var target_visible := not _get_panel_state(panel)
	_play_panel_tween(panel, target_visible)


func _hide_panel_with_tween(panel: Control) -> void:
	if panel == null or not _get_panel_state(panel):
		return
	_play_panel_tween(panel, false)


func _play_panel_tween(panel: Control, make_visible: bool) -> void:
	_stop_panel_tween(panel)
	_set_panel_state(panel, make_visible)

	if make_visible:
		panel.visible = true
		panel.scale = Vector2(0.92, 0.92)
		panel.modulate = Color(panel.modulate.r, panel.modulate.g, panel.modulate.b, 0.0)

	var tween := create_tween()
	var panel_id := panel.get_instance_id()
	_panel_tweens[panel_id] = tween

	if make_visible:
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(panel, "modulate:a", 1.0, 0.22)
		tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.22)
		tween.finished.connect(func() -> void:
			_panel_tweens.erase(panel_id)
		)
	else:
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(panel, "modulate:a", 0.0, 0.16)
		tween.parallel().tween_property(panel, "scale", Vector2(0.9, 0.9), 0.16)
		tween.finished.connect(func() -> void:
			panel.visible = false
			panel.scale = Vector2.ONE
			panel.modulate = Color(panel.modulate.r, panel.modulate.g, panel.modulate.b, 1.0)
			_panel_tweens.erase(panel_id)
			_set_panel_state(panel, false)
		)


func _stop_panel_tween(panel: Control) -> void:
	var panel_id := panel.get_instance_id()
	if _panel_tweens.has(panel_id):
		var tween: Tween = _panel_tweens[panel_id]
		if tween:
			tween.kill()
		_panel_tweens.erase(panel_id)


func _get_panel_state(panel: Control) -> bool:
	return _panel_states.get(panel.get_instance_id(), panel.visible)


func _set_panel_state(panel: Control, value: bool) -> void:
	_panel_states[panel.get_instance_id()] = value


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
