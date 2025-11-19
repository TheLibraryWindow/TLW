extends Panel

const WARP_SHADER := preload("res://scripts/psychedelic_warp.gdshader")
const WARP_MAX_WAVES := 3
const HASH_KEYCODE := 35
const WARP_PATTERN_PRESETS := [
	{"radius": Vector2(0.22, 0.35), "amplitude": Vector2(0.015, 0.03), "pinch": Vector2(0.008, 0.02), "aspect": Vector2(0.45, 0.9), "dispersion": Vector2(6.5, 9.5), "speed": Vector2(1.2, 1.8)},
	{"radius": Vector2(0.30, 0.45), "amplitude": Vector2(0.02, 0.04), "pinch": Vector2(0.012, 0.028), "aspect": Vector2(0.6, 1.2), "dispersion": Vector2(7.0, 11.5), "speed": Vector2(1.4, 2.0)},
	{"radius": Vector2(0.45, 0.65), "amplitude": Vector2(0.018, 0.05), "pinch": Vector2(0.01, 0.03), "aspect": Vector2(0.8, 1.5), "dispersion": Vector2(8.0, 12.0), "speed": Vector2(1.6, 2.3)},
	{"radius": Vector2(0.15, 0.30), "amplitude": Vector2(0.025, 0.06), "pinch": Vector2(0.015, 0.035), "aspect": Vector2(0.3, 0.7), "dispersion": Vector2(5.5, 8.0), "speed": Vector2(1.8, 2.6)},
	{"radius": Vector2(0.55, 0.80), "amplitude": Vector2(0.015, 0.04), "pinch": Vector2(0.005, 0.02), "aspect": Vector2(1.0, 2.0), "dispersion": Vector2(9.0, 13.0), "speed": Vector2(1.1, 1.7)},
	{"radius": Vector2(0.25, 0.50), "amplitude": Vector2(0.03, 0.07), "pinch": Vector2(0.02, 0.04), "aspect": Vector2(0.5, 1.0), "dispersion": Vector2(7.5, 10.5), "speed": Vector2(2.0, 2.8)},
	{"radius": Vector2(0.35, 0.60), "amplitude": Vector2(0.012, 0.03), "pinch": Vector2(0.006, 0.018), "aspect": Vector2(0.9, 1.6), "dispersion": Vector2(8.5, 12.5), "speed": Vector2(1.3, 2.1)},
	{"radius": Vector2(0.18, 0.34), "amplitude": Vector2(0.02, 0.05), "pinch": Vector2(0.014, 0.03), "aspect": Vector2(0.4, 0.9), "dispersion": Vector2(6.0, 9.0), "speed": Vector2(1.9, 2.6)},
	{"radius": Vector2(0.42, 0.70), "amplitude": Vector2(0.025, 0.06), "pinch": Vector2(0.017, 0.033), "aspect": Vector2(0.7, 1.3), "dispersion": Vector2(7.5, 11.0), "speed": Vector2(1.5, 2.2)},
	{"radius": Vector2(0.28, 0.38), "amplitude": Vector2(0.018, 0.032), "pinch": Vector2(0.01, 0.024), "aspect": Vector2(1.1, 1.9), "dispersion": Vector2(8.0, 13.0), "speed": Vector2(1.2, 1.9)},
	{"radius": Vector2(0.32, 0.58), "amplitude": Vector2(0.022, 0.045), "pinch": Vector2(0.012, 0.028), "aspect": Vector2(0.6, 1.3), "dispersion": Vector2(6.5, 10.0), "speed": Vector2(1.7, 2.4)},
	{"radius": Vector2(0.20, 0.36), "amplitude": Vector2(0.028, 0.055), "pinch": Vector2(0.015, 0.034), "aspect": Vector2(0.35, 0.85), "dispersion": Vector2(5.5, 8.5), "speed": Vector2(2.1, 3.1)},
	{"radius": Vector2(0.48, 0.76), "amplitude": Vector2(0.017, 0.04), "pinch": Vector2(0.008, 0.022), "aspect": Vector2(0.9, 1.8), "dispersion": Vector2(9.5, 13.5), "speed": Vector2(1.2, 1.8)},
	{"radius": Vector2(0.24, 0.44), "amplitude": Vector2(0.03, 0.065), "pinch": Vector2(0.02, 0.04), "aspect": Vector2(0.5, 1.1), "dispersion": Vector2(7.0, 10.0), "speed": Vector2(1.8, 2.7)},
	{"radius": Vector2(0.38, 0.62), "amplitude": Vector2(0.02, 0.05), "pinch": Vector2(0.012, 0.03), "aspect": Vector2(0.8, 1.4), "dispersion": Vector2(8.0, 11.5), "speed": Vector2(1.4, 2.2)},
	{"radius": Vector2(0.16, 0.28), "amplitude": Vector2(0.035, 0.07), "pinch": Vector2(0.02, 0.045), "aspect": Vector2(0.3, 0.7), "dispersion": Vector2(5.0, 7.5), "speed": Vector2(2.2, 3.2)},
	{"radius": Vector2(0.50, 0.82), "amplitude": Vector2(0.015, 0.035), "pinch": Vector2(0.006, 0.02), "aspect": Vector2(1.0, 2.2), "dispersion": Vector2(9.0, 14.0), "speed": Vector2(1.1, 1.9)},
	{"radius": Vector2(0.27, 0.49), "amplitude": Vector2(0.024, 0.052), "pinch": Vector2(0.013, 0.03), "aspect": Vector2(0.55, 1.2), "dispersion": Vector2(6.8, 9.8), "speed": Vector2(1.6, 2.5)},
	{"radius": Vector2(0.34, 0.57), "amplitude": Vector2(0.018, 0.04), "pinch": Vector2(0.01, 0.025), "aspect": Vector2(1.2, 2.0), "dispersion": Vector2(8.5, 12.8), "speed": Vector2(1.3, 2.0)},
	{"radius": Vector2(0.21, 0.40), "amplitude": Vector2(0.032, 0.068), "pinch": Vector2(0.018, 0.04), "aspect": Vector2(0.4, 0.95), "dispersion": Vector2(6.0, 9.2), "speed": Vector2(2.0, 3.0)}
]
const WARP_GLOBAL_INTENSITY_RANGE := Vector2(0.85, 1.4)
const WARP_GLOBAL_CHROMA_RANGE := Vector2(0.12, 0.35)
const WARP_GLOBAL_EDGE_RANGE := Vector2(0.004, 0.02)

# ---------- Node References ----------
@onready var username_edit: LineEdit = $Username
@onready var password_edit: LineEdit = $Password
@onready var error_label_username: Label = $ErrorLabelUsername
@onready var error_label_password: Label = $ErrorLabelPassword
@onready var login_btn: Button = $Login
@onready var create_btn: Button = $CreateUser
@onready var create_user_panel: Panel = $CreateUserPanel   # <-- child panel

# Cancel overlapping tweens
var _msg_token_username: int = 0
var _msg_token_password: int = 0

var _warp_layer: CanvasLayer
var _warp_rect: ColorRect
var _warp_material: ShaderMaterial
var _warp_rng := RandomNumberGenerator.new()
var _warp_queue: Array = []
var _warp_active: Array = []
var _warp_running: bool = false

func _ready() -> void:
	error_label_username.visible = false
	error_label_password.visible = false
	if create_user_panel:
		create_user_panel.visible = false

	# Connect safely
	if not login_btn.is_connected("button_down", Callable(self, "_on_login_button_down")):
		login_btn.connect("button_down", Callable(self, "_on_login_button_down"))
	if not create_btn.is_connected("pressed", Callable(self, "_on_create_user_pressed")):
		create_btn.connect("pressed", Callable(self, "_on_create_user_pressed"))

	if not username_edit.is_connected("text_submitted", Callable(self, "_on_Username_text_submitted")):
		username_edit.connect("text_submitted", Callable(self, "_on_Username_text_submitted"))
	if not password_edit.is_connected("text_submitted", Callable(self, "_on_Password_text_submitted")):
		password_edit.connect("text_submitted", Callable(self, "_on_Password_text_submitted"))

	_load_last_user()
	_init_warp_overlay()
	set_process(false)


# =======================
# LOGIN LOGIC
# =======================
func _on_login_button_down() -> void:
	var username: String = username_edit.text.strip_edges()
	var password: String = password_edit.text.strip_edges()

	if username.is_empty():
		_show_username_message("⚠ Username incorrect")
		return

	var user_data: Dictionary = _load_user_data(username)
	if user_data.is_empty():
		_show_username_message("⚠ Username incorrect")
		return

	if password.is_empty():
		_show_password_message("⚠ Password incorrect")
		return

	if not user_data.has("password") or String(user_data["password"]) != password:
		_show_password_message("⚠ Password incorrect")
		return

	# ✅ Save user info globally
	if Engine.has_singleton("UserData"):
		UserData.username = username
		UserData.password = password
		UserData.icon_index = user_data.get("icon_index", 0)
		UserData.startup_sound_path = user_data.get("startup_sound_path", "")
		UserData.save_user()

	_save_last_user(username)
	_proceed_to_desktop(user_data)


# =======================
# FILE & DATA HELPERS
# =======================
func _load_user_data(username: String) -> Dictionary:
	var path: String = "user://users/%s.json" % username
	if not FileAccess.file_exists(path):
		return {}
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		return parsed as Dictionary
	return {}

func _save_last_user(username: String) -> void:
	var f: FileAccess = FileAccess.open("user://last_user.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"username": username}))
	f.close()

func _load_last_user() -> void:
	var path: String = "user://last_user.json"
	if not FileAccess.file_exists(path):
		return
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary and (parsed as Dictionary).has("username"):
		username_edit.text = str((parsed as Dictionary)["username"])


# =======================
# ERROR ANIMATIONS
# =======================
func _show_message(label: Label, token_ref: String, msg: String, color: Color = Color.RED, seconds: float = 4.0) -> void:
	var my_token: int = 0
	if token_ref == "username":
		_msg_token_username += 1
		my_token = _msg_token_username
	else:
		_msg_token_password += 1
		my_token = _msg_token_password

	label.text = msg
	label.add_theme_color_override("font_color", color)
	label.visible = true
	label.modulate.a = 0.0
	label.scale = Vector2(0.2, 1.0)

	var tween_in: Tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_in.tween_property(label, "scale", Vector2(1.0, 1.0), 0.35)
	tween_in.parallel().tween_property(label, "modulate:a", 1.0, 0.35)
	await tween_in.finished

	await get_tree().create_timer(seconds).timeout

	if (token_ref == "username" and my_token != _msg_token_username) or (token_ref == "password" and my_token != _msg_token_password):
		return

	var tween_out: Tween = get_tree().create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween_out.tween_property(label, "modulate:a", 0.0, 0.4)
	tween_out.parallel().tween_property(label, "scale", Vector2(1.2, 1.0), 0.4)
	await tween_out.finished
	label.visible = false

func _show_username_message(msg: String, color: Color = Color.RED, seconds: float = 4.0) -> void:
	_show_message(error_label_username, "username", msg, color, seconds)

func _show_password_message(msg: String, color: Color = Color.RED, seconds: float = 4.0) -> void:
	_show_message(error_label_password, "password", msg, color, seconds)


# =======================
# SCENE TRANSITIONS
# =======================
func _proceed_to_desktop(user_data: Dictionary) -> void:
	print("✅ Login success for:", user_data.get("username", "<?>"))
	get_tree().change_scene_to_file("res://scenes/main.tscn")


# =======================
# ENTER KEY SUPPORT
# =======================
func _on_Username_text_submitted(_new_text: String) -> void:
	password_edit.grab_focus()

func _on_Password_text_submitted(_new_text: String) -> void:
	_on_login_button_down()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if username_edit.has_focus() or password_edit.has_focus():
			accept_event()
			_on_login_button_down()
	if event is InputEventKey and event.pressed and not event.echo:
		if _is_hash_key(event):
			_trigger_warp_burst()


# =======================
# OPEN / CLOSE CREATE USER PANEL
# =======================
func _on_create_user_pressed() -> void:
	if not create_user_panel:
		return

	$Username.visible = false
	$Password.visible = false
	$Login.visible = false
	$CreateUser.visible = false
	create_user_panel.visible = true

func _on_cancel_create_user_pressed() -> void:
	if not create_user_panel:
		return

	create_user_panel.visible = false
	$Username.visible = true
	$Password.visible = true
	$Login.visible = true
	$CreateUser.visible = true

func _on_confirm_create_user_pressed() -> void:
	var username_field = create_user_panel.get_node_or_null("VBoxContainer/Username/TextEdit")
	var password_field = create_user_panel.get_node_or_null("VBoxContainer/Password/TextEdit")
	if not username_field or not password_field:
		push_warning("Missing fields in CreateUser panel")
		return

	var username = username_field.text.strip_edges()
	var password = password_field.text.strip_edges()

	if username != "Nombre":
		push_warning("Username must be 'Nombre'")
		return
	if password != "Someterse":
		push_warning("Password must be 'Someterse'")
		return

	print("[CreateUser] Credentials accepted.")
	_on_cancel_create_user_pressed()

# =======================
# PSYCHEDELIC WARP LOGIC
# =======================

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
		_warp_running = false
		if _warp_rect:
			_warp_rect.visible = false
		set_process(false)

	_update_warp_shader()

func _init_warp_overlay() -> void:
	if _warp_rect or not WARP_SHADER:
		return

	_warp_rng.randomize()

	_warp_layer = CanvasLayer.new()
	_warp_layer.name = "WarpLayer"
	_warp_layer.layer = 200
	_warp_layer.follow_viewport = true
	add_child(_warp_layer)

	_warp_rect = ColorRect.new()
	_warp_rect.name = "WarpOverlay"
	_warp_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_warp_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_warp_rect.color = Color(1, 1, 1, 1)
	_warp_rect.visible = false
	_warp_rect.z_index = 999

	_warp_material = ShaderMaterial.new()
	_warp_material.shader = WARP_SHADER
	_warp_rect.material = _warp_material

	_warp_layer.add_child(_warp_rect)
	_update_warp_shader()

func _trigger_warp_burst() -> void:
	if not _warp_material:
		return

	_warp_queue.clear()
	_warp_active.clear()

	var delay := 0.0
	var pool := WARP_PATTERN_PRESETS.duplicate()
	for i in range(WARP_MAX_WAVES):
		if pool.is_empty():
			pool = WARP_PATTERN_PRESETS.duplicate()
		var preset_index := _warp_rng.randi_range(0, pool.size() - 1)
		var preset: Dictionary = pool.pop_at(preset_index)
		var wave := _make_wave_from_preset(preset)
		wave["start_delay"] = delay
		delay += _warp_rng.randf_range(0.08, 0.18)
		_warp_queue.append(wave)

	_warp_material.set_shader_parameter("global_intensity", _rand_range(WARP_GLOBAL_INTENSITY_RANGE))
	_warp_material.set_shader_parameter("chroma_shift", _rand_range(WARP_GLOBAL_CHROMA_RANGE))
	_warp_material.set_shader_parameter("edge_safety", _rand_range(WARP_GLOBAL_EDGE_RANGE))

	_warp_running = true
	if _warp_rect:
		_warp_rect.visible = true
	set_process(true)
	_update_warp_shader()

func _make_wave_from_preset(preset: Dictionary) -> Dictionary:
	return {
		"center": Vector2(_warp_rng.randf_range(-0.15, 1.15), _warp_rng.randf_range(-0.1, 1.1)),
		"angle": deg_to_rad(_warp_rng.randf_range(0.0, 360.0)),
		"amplitude": _rand_range(preset.get("amplitude", Vector2(0.02, 0.04))),
		"radius": _rand_range(preset.get("radius", Vector2(0.3, 0.6))),
		"pinch": _rand_range(preset.get("pinch", Vector2(0.01, 0.03))),
		"aspect": _rand_range(preset.get("aspect", Vector2(0.6, 1.4))),
		"dispersion": _rand_range(preset.get("dispersion", Vector2(7.0, 11.0))),
		"speed": _rand_range(preset.get("speed", Vector2(1.5, 2.3))),
		"progress": 0.0,
		"start_delay": 0.0
	}

func _rand_range(range: Vector2) -> float:
	return _warp_rng.randf_range(range.x, range.y)

func _update_warp_shader() -> void:
	if not _warp_material:
		return

	var centers := PackedVector2Array()
	var angles := PackedFloat32Array()
	var amplitudes := PackedFloat32Array()
	var radii := PackedFloat32Array()
	var pinches := PackedFloat32Array()
	var aspects := PackedFloat32Array()
	var progresses := PackedFloat32Array()
	var dispersions := PackedFloat32Array()

	var active_count := min(WARP_MAX_WAVES, _warp_active.size())
	for i in range(WARP_MAX_WAVES):
		if i < active_count:
			var wave: Dictionary = _warp_active[i]
			centers.append(wave["center"])
			angles.append(wave["angle"])
			amplitudes.append(wave["amplitude"])
			radii.append(wave["radius"])
			pinches.append(wave["pinch"])
			aspects.append(wave["aspect"])
			progresses.append(clamp(wave["progress"], 0.0, 1.0))
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

func _is_hash_key(event: InputEventKey) -> bool:
	return event.unicode == HASH_KEYCODE or event.keycode == HASH_KEYCODE or event.physical_keycode == HASH_KEYCODE
