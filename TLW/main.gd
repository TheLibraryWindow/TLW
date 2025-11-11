extends Node

# === NODES ===
@onready var camera: Camera2D = $Camera2D
@onready var world_layer: Node2D = $WorldLayer
@onready var desktop_layer: CanvasLayer = $DesktopLayer
@onready var world: Node   = $WorldLayer/proc_gen_world
@onready var desktop: Node = $DesktopLayer/Desktop

# === STATE ===
var in_world: bool = false


# === READY ===
func _ready() -> void:
	in_world = false
	_apply_active()
	print("[MAIN] Startup → Desktop visible =", desktop.visible, ", World visible =", world.visible)


# === INPUT TOGGLE ===
func toggle_world() -> void:
	in_world = !in_world
	_apply_active()
	print("[MAIN] Now showing:", "World" if in_world else "Desktop")


# === APPLY VISIBILITY & INPUT ===
func _apply_active() -> void:
	# Safely toggle visibility only if nodes exist
	if desktop:
		desktop.visible = not in_world
	else:
		push_warning("[MAIN] Desktop node not found!")

	if world:
		world.visible = in_world
	else:
		push_warning("[MAIN] World node not found!")

	# Route input only to active scene
	if desktop:
		desktop.set_process_input(not in_world)
		desktop.set_process_unhandled_input(not in_world)
	if world:
		world.set_process_input(in_world)
		world.set_process_unhandled_input(in_world)

	# Camera activation
	if in_world:
		await get_tree().process_frame
		if camera:
			camera.make_current()
		print("[MAIN] Camera activated for World.")
	else:
		print("[MAIN] Back to Desktop (no camera).")
