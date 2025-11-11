extends HBoxContainer

var sounds = [
	preload("res://TheLibraryWindowOS/startupsounds/startup1.wav"),
	preload("res://TheLibraryWindowOS/startupsounds/startup2.wav")
]
var sound_names = ["Startup Sound 1", "Startup Sound 2"]
var current_index = 0

@onready var label = $Sounds
@onready var player = $AudioStreamPlayer
@onready var file_dialog = $SoundFileDialog
var custom_sound_path = ""

func _ready():
	update_display()

func update_display():
	label.text = sound_names[current_index]
	player.stream = sounds[current_index]

func _on_Sound_pressed():
	current_index = (current_index - 1 + sounds.size()) % sounds.size()
	update_display()

func _on_Sounds_pressed():
	current_index = (current_index + 1) % sounds.size()
	update_display()

func _on_Preview_pressed():
	player.play()

func _on_SelectSound_pressed():
	print("Selected:", sound_names[current_index])

func _on_Choosesound_pressed():
	file_dialog.popup_centered()

func _on_SoundFileDialog_file_selected(path):
	var new_stream = load(path)
	if new_stream and new_stream is AudioStream:
		sounds.append(new_stream)
		sound_names.append("Custom Sound")
		current_index = sounds.size() - 1
		custom_sound_path = path   # save path for storing later
		update_display()
	else:
		print("Not a valid audio file:", path)
