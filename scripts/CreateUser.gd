extends Panel

# ---------- UI References ----------
@onready var error_label_username: Label = $ErrorLabelUsername
@onready var error_label_password: Label = $ErrorLabelPassword
@onready var file_dialog: FileDialog = $FileDialog
@onready var sound_panel: Node = $StartupSound
@onready var username_field: LineEdit = $Username/TextEdit
@onready var password_field: LineEdit = $Password/TextEdit
@onready var texture_rect: TextureRect = $ChangeImage/TextureRect
@onready var confirm_button: Button = $ConfirmButton
@onready var cancel_button: Button = $CancelButton

# ---------- Icon Handling ----------
var icons: Array[Texture2D] = []
var current_index: int = 0
var custom_icon: Texture2D = null

# ---------- Tween Tokens ----------
var _msg_token_username: int = 0
var _msg_token_password: int = 0


func _ready() -> void:
	
	# Connect enter key events
	if username_field and not username_field.is_connected("text_submitted", Callable(self, "_on_username_submitted")):
		username_field.connect("text_submitted", Callable(self, "_on_username_submitted"))
	if password_field and not password_field.is_connected("text_submitted", Callable(self, "_on_password_submitted")):
		password_field.connect("text_submitted", Callable(self, "_on_password_submitted"))

	# Hide error labels by default
	if error_label_username:
		error_label_username.visible = false
	if error_label_password:
		error_label_password.visible = false

	# Connect buttons
	if confirm_button and not confirm_button.is_connected("pressed", Callable(self, "_on_ConfirmButton_pressed")):
		confirm_button.connect("pressed", Callable(self, "_on_ConfirmButton_pressed"))
	if cancel_button and not cancel_button.is_connected("pressed", Callable(self, "_on_CancelButton_pressed")):
		cancel_button.connect("pressed", Callable(self, "_on_CancelButton_pressed"))

	# Load sample icons
	icons = [
		load("res://graphics/ProfileIcons/test1.png"),
		load("res://graphics/ProfileIcons/test2.png")
	]
	_update_display_picture()


# =======================
# DISPLAY & ICONS
# =======================
func _update_display_picture() -> void:
	if current_index >= 0 and current_index < icons.size():
		texture_rect.texture = icons[current_index]


func _on_Button_pressed() -> void:
	current_index = (current_index - 1 + icons.size()) % icons.size()
	_update_display_picture()


func _on_Button2_pressed() -> void:
	current_index = (current_index + 1) % icons.size()
	_update_display_picture()


# =======================
# IMAGE IMPORT
# =======================
func _on_browsebutton_pressed() -> void:
	file_dialog.popup_centered()


func _on_FileDialog_file_selected(path: String) -> void:
	var image := Image.new()
	var err := image.load(path)
	if err == OK:
		image.resize(64, 64, Image.INTERPOLATE_LANCZOS)
		var tex := ImageTexture.create_from_image(image)
		custom_icon = tex
		icons.append(tex)
		current_index = icons.size() - 1
		_update_display_picture()
	else:
		_show_message(error_label_username, "⚠ Failed to load image", Color.RED)


# =======================
# CREATE USER VALIDATION
# =======================
func _on_ConfirmButton_pressed() -> void:
	var username := username_field.text.strip_edges()
	var password := password_field.text.strip_edges()

	# Enforce “Nombre” / “Someterse” dystopian rules
	if username != "Nombre":
		_show_message(error_label_username, "⚠ Username must be 'Nombre'", Color.RED)
		return

	if password != "Someterse":
		_show_message(error_label_password, "⚠ Password must be 'Someterse'", Color.RED)
		return

	# Check if folder exists
	var dir := DirAccess.open("user://")
	if not dir.dir_exists("users"):
		dir.make_dir("users")

	var path := "user://users/%s.json" % username
	if FileAccess.file_exists(path):
		_show_message(error_label_username, "⚠ Username already exists!", Color.RED)
		return

	# Gather sound data
	var startup_sound_path := ""
	if sound_panel and sound_panel.has_method("get_current_sound_path"):
		startup_sound_path = sound_panel.get_current_sound_path()

	# Build user data
	var user_data := {
		"username": username,
		"password": password,
		"icon_index": current_index,
		"custom": custom_icon != null,
		"startup_sound_path": startup_sound_path
	}

	# Save user JSON
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(user_data))
	file.close()

	_show_message(error_label_username, "✅ User created successfully", Color.GREEN)
	print("✅ User created:", user_data)

	# Save custom icon
	if custom_icon:
		var img := custom_icon.get_image()
		img.save_png("user://users/%s_icon.png" % username)

	# Notify parent (LoginPanel) that user creation finished
	var parent := get_parent()
	if parent and parent.has_method("_on_cancel_create_user_pressed"):
		await get_tree().create_timer(1.5).timeout  # brief delay before returning
		parent._on_cancel_create_user_pressed()


# =======================
# CANCEL BUTTON
# =======================
func _on_CancelButton_pressed() -> void:
	var parent := get_parent()
	if parent and parent.has_method("_on_cancel_create_user_pressed"):
		parent._on_cancel_create_user_pressed()


# =======================
# MESSAGE ANIMATIONS
# =======================
func _show_message(label: Label, msg: String, color: Color = Color.RED, seconds: float = 4.0) -> void:
	if not label:
		return
	var token_ref := "username" if label == error_label_username else "password"
	var my_token: int
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

	var tween_in := get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_in.tween_property(label, "scale", Vector2(1.0, 1.0), 0.3)
	tween_in.parallel().tween_property(label, "modulate:a", 1.0, 0.3)
	await tween_in.finished

	await get_tree().create_timer(seconds).timeout

	if (token_ref == "username" and my_token != _msg_token_username) or (token_ref == "password" and my_token != _msg_token_password):
		return

	var tween_out := get_tree().create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween_out.tween_property(label, "modulate:a", 0.0, 0.4)
	tween_out.parallel().tween_property(label, "scale", Vector2(1.2, 1.0), 0.4)
	await tween_out.finished

	if (token_ref == "username" and my_token != _msg_token_username) or (token_ref == "password" and my_token != _msg_token_password):
		return
	label.visible = false
