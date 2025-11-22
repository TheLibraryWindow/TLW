extends Panel

# ---------- Node References ----------
@onready var username_edit: LineEdit = $Username
@onready var password_edit: LineEdit = $Password
@onready var error_label_username: Label = $ErrorLabelUsername
@onready var error_label_password: Label = $ErrorLabelPassword
@onready var login_btn: Button = $Login
@onready var create_btn: Button = $CreateUser
@onready var create_user_panel: Panel = $CreateUserPanel   # <-- child panel
@onready var login_audio_player: AudioStreamPlayer = get_node_or_null("AudioStreamPlayer")

const LOGIN_AUDIO_FADE_DURATION := 2.5
const LOGIN_AUDIO_START_DB := -36.0
const LOGIN_AUDIO_TARGET_DB := 0.0

# Cancel overlapping tweens
var _msg_token_username: int = 0
var _msg_token_password: int = 0
var _login_audio_fade_tween: Tween

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
	_start_login_audio()


func _start_login_audio() -> void:
	if login_audio_player == null or login_audio_player.stream == null:
		return

	# Ensure the finished signal restarts the track without additional fades.
	var finished_callable := Callable(self, "_on_login_audio_finished")
	if not login_audio_player.finished.is_connected(finished_callable):
		login_audio_player.finished.connect(finished_callable)

	login_audio_player.stop()
	login_audio_player.volume_db = LOGIN_AUDIO_START_DB
	login_audio_player.play()

	if _login_audio_fade_tween:
		_login_audio_fade_tween.kill()
	_login_audio_fade_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_login_audio_fade_tween.tween_property(login_audio_player, "volume_db", LOGIN_AUDIO_TARGET_DB, LOGIN_AUDIO_FADE_DURATION)
	_login_audio_fade_tween.finished.connect(Callable(self, "_on_login_audio_fade_finished"))


func _on_login_audio_fade_finished() -> void:
	_login_audio_fade_tween = null
	if login_audio_player:
		login_audio_player.volume_db = LOGIN_AUDIO_TARGET_DB


func _on_login_audio_finished() -> void:
	if login_audio_player == null:
		return
	# Ensure subsequent loops start immediately at the final volume (no extra fade).
	login_audio_player.volume_db = LOGIN_AUDIO_TARGET_DB
	login_audio_player.play()


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
