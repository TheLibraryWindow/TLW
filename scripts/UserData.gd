extends Node

var username: String = ""
var password: String = ""
var icon_index: int = 0
var custom_icon: Texture2D = null
var startup_sound_path: String = ""

# Loads from JSON file if user exists
func load_user(username_in: String) -> void:
	var path = "user://users/%s.json" % username_in
	if not FileAccess.file_exists(path):
		push_warning("User not found: %s" % username_in)
		return
	var f = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if data is Dictionary:
		username = data.get("username", "")
		password = data.get("password", "")
		icon_index = data.get("icon_index", 0)
		startup_sound_path = data.get("startup_sound_path", "")
		print("[UserData] Loaded user:", username)
	else:
		push_warning("Failed to parse user data for %s" % username_in)

# Saves updated info
func save_user() -> void:
	if username.is_empty():
		push_warning("Cannot save empty username")
		return
	var data = {
		"username": username,
		"password": password,
		"icon_index": icon_index,
		"startup_sound_path": startup_sound_path
	}
	var f = FileAccess.open("user://users/%s.json" % username, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()
	print("[UserData] Saved:", username)
