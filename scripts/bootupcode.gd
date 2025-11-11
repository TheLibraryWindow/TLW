extends Node2D

@onready var animation_player: AnimationPlayer = $main/AnimationPlayer

func _ready() -> void:
	print("[BOOT] Starting boot sequence...")

	# Play boot animation if found
	if animation_player and animation_player.has_animation("bootupcode"):
		animation_player.play("bootupcode")
		# Connect the animation finished signal once
		if not animation_player.animation_finished.is_connected(_on_boot_animation_finished):
			animation_player.animation_finished.connect(_on_boot_animation_finished)
	else:
		print("[BOOT] No boot animation found, skipping directly to BootupLogo.")
		_change_to_logo()


func _on_boot_animation_finished(anim_name: String) -> void:
	if anim_name == "bootupcode":
		print("[BOOT] Bootup animation complete — moving to BootupLogo...")
		_change_to_logo()


func _change_to_logo() -> void:
	print("[BOOT] Loading BootupLogo scene...")
	
	# Use change_scene_to_file to fully replace the current scene
	get_tree().change_scene_to_file("res://scenes/bootuplogo.tscn")
