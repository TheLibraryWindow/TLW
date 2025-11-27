extends Node

# === NODES ===
@onready var camera: Camera2D       = $Camera2D
@onready var world_layer: Node2D    = $WorldLayer
@onready var desktop_layer: CanvasLayer = $DesktopLayer
@onready var world: Node            = $WorldLayer/world
@onready var desktop: Node          = $DesktopLayer/Desktop

# === STATE ===
var in_world: bool = false


# === READY ===
func _ready() -> void:
	in_world = false
	_apply_active()
	print("[MAIN] Startup → Desktop visible =", desktop.visible, ", World visible =", world.visible)

	# --- Connect Reset Seed button ---
	var reset_btn := desktop.get_node_or_null("ResetNewBtn")
	if reset_btn:
		reset_btn.pressed.connect(_on_reset_pressed)
	else:
		push_warning("[MAIN] ResetNewBtn not found in Desktop scene.")


# === GLOBAL INPUT (handles Tab anywhere) ===
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_world"):
		toggle_world()


# === TOGGLE WORLD / DESKTOP ===
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


# === RESET BUTTON HANDLER ===
func _on_reset_pressed() -> void:
	if world and world.has_method("reset_world"):
		world.reset_world()
		print("[MAIN] World reset triggered from Desktop ResetNewBtn.")
	else:
		push_warning("[MAIN] World node missing or reset_world() not found.")
