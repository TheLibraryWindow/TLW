extends Panel

# Default dystopian requirements
const REQUIRED_USERNAME := "Nombre"
const REQUIRED_PASSWORD := "Someterse"

# UI references
@onready var username_edit: LineEdit = $VBoxContainer/Username/UsernameText
@onready var password_edit: LineEdit = $VBoxContainer/Password/PasswordText
@onready var error_label_username: Label = $VBoxContainer/ErrorLabelUsername
@onready var error_label_password: Label = $VBoxContainer/ErrorLabelPassword
@onready var startup_sound = $VBoxContainer/StartupSound
@onready var preview_icon_rect: TextureRect = $VBoxContainer/ChangeImage/TextureRect
@onready var file_dialog = $FileDialog

# Avatar state
var icons: Array[Texture2D] = []
var current_index: int = 0
var custom_icon: Texture2D = null
var custom_sound_path: String = ""

# Token counters (to cancel overlapping tweens)
var _msg_token_username: int = 0
var _msg_token_password: int = 0


func _ready() -> void:
	error_label_username.visible = false
	error_label_password.visible = false

	icons = [
		load("res://TheLibraryWindowOS/ProfileIcons/test1.png"),
		load("res://TheLibraryWindowOS/ProfileIcons/test2.png")
	]
	_update_display_picture()


func _update_display_picture() -> void:
	preview_icon_rect.texture = icons[current_index]


# =======================
# Message animations
# =======================
func _show_message(label: Label, token_ref: String, msg: String, color: Color = Color.RED, seconds := 4.0) -> void:
	var my_token: int

	# track unique token per label
	if token_ref == "username":
		_msg_token_username += 1
		my_token = _msg_token_username
	else:
		_msg_token_password += 1
		my_token = _msg_token_password

	# setup label
	label.text = msg
	label.add_theme_color_override("font_color", color)
	label.visible = true
	label.modulate.a = 0.0
	label.scale = Vector2(0.2, 1.0)  # start squished horizontally

	# animate "book opening"
	var tween_in = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_in.tween_property(label, "scale", Vector2(1.0, 1.0), 0.35)
	tween_in.parallel().tween_property(label, "modulate:a", 1.0, 0.35)
	await tween_in.finished

	# wait
	var timer = get_tree().create_timer(seconds)
	await timer.timeout

	# ensure still valid
	if (token_ref == "username" and my_token != _msg_token_username) or (token_ref == "password" and my_token != _msg_token_password):
		return

	# animate fade-out
	var tween_out = get_tree().create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween_out.tween_property(label, "modulate:a", 0.0, 0.4)
	tween_out.parallel().tween_property(label, "scale", Vector2(1.2, 1.0), 0.4)
	await tween_out.finished

	# ensure still valid
	if (token_ref == "username" and my_token != _msg_token_username) or (token_ref == "password" and my_token != _msg_token_password):
		return

	label.visible = false


func _show_username_message(msg: String, color: Color = Color.RED, seconds := 4.0) -> void:
	_show_message(error_label_username, "username", msg, color, seconds)


func _show_password_message(msg: String, color: Color = Color.RED, seconds := 4.0) -> void:
	_show_message(error_label_password, "password", msg, color, seconds)


# =======================
# Submit button
# =======================
func _on_submit_button_button_down() -> void:
	var username = username_edit.text.strip_edges()
	var password = password_edit.text.strip_edges()

	# Enforce dystopian values
	if username != REQUIRED_USERNAME:
		_show_username_message("⚠ Username must be '%s'" % REQUIRED_USERNAME)
		return

	if password != REQUIRED_PASSWORD:
		_show_password_message("⚠ Password must be '%s'" % REQUIRED_PASSWORD)
		return

	# Check if username already exists
	var path = "user://users/%s.json" % username
	if FileAccess.file_exists(path):
		_show_username_message("⚠ Username already exists!")
		return

	# if passes checks, build user_data
	var user_data = {
		"username": username,
		"password": password,
		"icon_index": current_index,
		"custom": custom_icon != null,
		"startup_sound_index": startup_sound.current_index if (startup_sound and startup_sound.has_method("current_index")) else 0,
		"custom_icon_path": "user://users/%s_icon.png" % username if custom_icon != null else "",
		"custom_sound_path": ""
	}

	# Save custom icon if present
	if custom_icon:
		var image = custom_icon.get_image()
		image.save_png(user_data["custom_icon_path"])

	# Save custom sound if present
	if custom_sound_path != "":
		var dest_path = "user://users/%s_sound.ogg" % username
		DirAccess.copy_absolute(custom_sound_path, ProjectSettings.globalize_path(dest_path))
		user_data["custom_sound_path"] = dest_path

	# Ensure users folder exists
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("users"):
		dir.make_dir("users")

	# Save JSON
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(user_data))
	file.close()

	_show_username_message("✅ User created successfully", Color.GREEN)

	# Close the create user window and return to login
	queue_free()




# =======================
# Icon browsing
# =======================
func _on_Button_pressed() -> void:
	current_index = (current_index - 1 + icons.size()) % icons.size()
	_update_display_picture()

func _on_Button2_pressed() -> void:
	current_index = (current_index + 1) % icons.size()
	_update_display_picture()


# =======================
# File dialog for custom icon
# =======================
func _on_browsebutton_pressed() -> void:
	file_dialog.popup_centered()

func _on_FileDialog_file_selected(path: String) -> void:
	var tex = load(path) as Texture2D
	if tex:
		var image = tex.get_image()
		image.resize(64, 64, Image.INTERPOLATE_LANCZOS)
		var resized_tex = ImageTexture.create_from_image(image)

		custom_icon = resized_tex
		icons.append(resized_tex)
		current_index = icons.size() - 1
		_update_display_picture()
	else:
		_show_username_message("⚠ Failed to load image", Color.RED)


# =======================
# Close window
# =======================
func _on_close_create_user_window_button_down() -> void:
	queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		# Only submit when one of the fields has focus
		if username_edit.has_focus() or password_edit.has_focus():
			accept_event()  # stop it propagating elsewhere
			_on_submit_button_button_down()

func _on_UsernameText_text_submitted(_new_text: String) -> void:
	password_edit.grab_focus()

func _on_PasswordText_text_submitted(_new_text: String) -> void:
	_on_submit_button_button_down()
