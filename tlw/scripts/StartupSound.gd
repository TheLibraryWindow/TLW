extends HBoxContainer

@onready var choose_text: Label = $ChooseText
@onready var prev_button: Button = $"<Sound"
@onready var next_button: Button = $"Sounds>"
@onready var player: AudioStreamPlayer = $AudioStreamPlayer
@onready var preview_button: Button = $Preview
@onready var choose_sound_button: Button = $Choosesound
@onready var file_dialog: FileDialog = $SoundFileDialog

var sounds: Array[AudioStream] = [
	preload("res://audio/startupsounds/startup1.wav"),
	preload("res://audio/startupsounds/startup2.wav")
]
var sound_names: Array[String] = ["Startup Sound 1", "Startup Sound 2"]
var current_index: int = 0

func _ready() -> void:
	_update_display()

func _update_display() -> void:
	choose_text.text = sound_names[current_index]
	player.stream = sounds[current_index]

func _on__Sound_pressed() -> void:
	current_index = (current_index - 1 + sounds.size()) % sounds.size()
	_update_display()

func _on_Sounds_pressed() -> void:
	current_index = (current_index + 1) % sounds.size()
	_update_display()

func _on_Preview_pressed() -> void:
	player.play()

func _on_Choosesound_pressed() -> void:
	file_dialog.popup_centered()

func _on_SoundFileDial_file_selected(path: String) -> void:
	var new_stream = load(path)
	if new_stream is AudioStream:
		sounds.append(new_stream)
		sound_names.append("Custom Sound")
		current_index = sounds.size() - 1
		_update_display()
	else:
		push_warning("Invalid audio file: " + path)

func get_current_sound_path() -> String:
	# Returns the path of the current sound for saving in user data
	return "res://audio/startupsounds/startup%d.wav" % (current_index + 1)
