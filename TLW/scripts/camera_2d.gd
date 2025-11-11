extends Camera2D

# === CONFIGURABLE SETTINGS ===
@export var screen_size := Vector2(1280, 720)
@export var move_speed := 600.0
@export var accel := 8.0
@export var zoom_step := 0.1
@export var min_zoom := 0.5
@export var max_zoom := 2.0
@export var zoom_smooth := 8.0
@export var tilemap_path: NodePath     # assign in Inspector → Main/WorldLayer/World/TileMap

# === INTERNAL STATE ===
var world_bounds: Rect2
var bounds_ready := false
var velocity := Vector2.ZERO
var target_zoom := Vector2.ONE

func _ready():
	_setup_bounds()
	target_zoom = zoom

	# Make sure we become current after scene switch
	await get_tree().process_frame
	make_current()

	# Ensure we receive input regardless of branch
	set_process_input(true)
	set_process_unhandled_input(true)

	print("✅ Global camera active:", is_current())

func _setup_bounds():
	var tilemap: TileMap = get_node_or_null(tilemap_path)
	if tilemap:
		var used_rect: Rect2i = tilemap.get_used_rect()
		var cell_size: Vector2i = tilemap.tile_set.tile_size
		world_bounds = Rect2(used_rect.position * cell_size, used_rect.size * cell_size)
		bounds_ready = world_bounds.size.x > 0 and world_bounds.size.y > 0
		if bounds_ready:
			position = world_bounds.position + world_bounds.size / 2
	else:
		bounds_ready = false
		print("⚠️ Camera couldn't find TileMap at:", tilemap_path)

func _process(delta):
	_handle_movement(delta)
	_handle_zoom(delta)
	_clamp_to_bounds()

func _handle_movement(delta):
	var dir := Vector2.ZERO

	# WASD + arrows
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		dir.x += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		dir.x -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		dir.y += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		dir.y -= 1

	if dir != Vector2.ZERO:
		dir = dir.normalized()
		velocity = velocity.lerp(dir * move_speed, accel * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, accel * move_speed * delta)

	position += velocity * delta

func _handle_zoom(delta):
	if Input.is_action_just_pressed("zoom_in"):
		target_zoom -= Vector2(zoom_step, zoom_step)
	elif Input.is_action_just_pressed("zoom_out"):
		target_zoom += Vector2(zoom_step, zoom_step)

	target_zoom = target_zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
	zoom = zoom.lerp(target_zoom, zoom_smooth * delta)

func _clamp_to_bounds():
	if not bounds_ready:
		return
	var half_view = (screen_size * zoom) / 2
	position.x = clamp(
		position.x,
		world_bounds.position.x + half_view.x,
		world_bounds.position.x + world_bounds.size.x - half_view.x
	)
	position.y = clamp(
		position.y,
		world_bounds.position.y + half_view.y,
		world_bounds.position.y + world_bounds.size.y - half_view.y
	)

# Optional helper if you repaint/resize the map at runtime:
func refresh_bounds():
	_setup_bounds()
