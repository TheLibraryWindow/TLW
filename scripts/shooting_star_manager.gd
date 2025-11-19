extends Node2D

@export_range(5.0, 120.0) var min_delay: float = 5.0
@export_range(5.0, 120.0) var max_delay: float = 120.0
@export var min_speed: float = 200.0
@export var max_speed: float = 600.0
@export var star_size: Vector2 = Vector2.ONE
@export var spawn_margin: float = 12.0
@export var travel_multiplier: float = 1.8
@export var star_color: Color = Color.WHITE


func _ready() -> void:
	randomize()
	_spawn_loop()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ASTERISK or (event.keycode == KEY_8 and event.shift_pressed):
			_spawn_star()


func _spawn_loop() -> void:
	_spawn_loop_async()


func _spawn_loop_async() -> void:
	while is_instance_valid(self):
		var wait_time := randf_range(min_delay, max_delay)
		await get_tree().create_timer(wait_time).timeout

		if is_inside_tree():
			_spawn_star()


func _spawn_star() -> void:
	var viewport_rect := get_viewport().get_visible_rect()
	var viewport_size := viewport_rect.size

	var side := randi() % 4
	var start_pos := _random_point_on_side(side, viewport_size)
	var direction := _direction_for_side(side)

	var speed := randf_range(min_speed, max_speed)
	var travel_distance: float = float(max(viewport_size.x, viewport_size.y)) * travel_multiplier
	var end_pos := start_pos + direction * travel_distance
	var duration := travel_distance / speed

	var star := ColorRect.new()
	star.color = star_color
	star.size = star_size
	star.position = start_pos
	add_child(star)

	var tween := create_tween()
	tween.tween_property(star, "position", end_pos, duration).set_trans(Tween.TRANS_LINEAR)
	tween.finished.connect(star.queue_free)


func _random_point_on_side(side: int, viewport_size: Vector2) -> Vector2:
	match side:
		0:  # left
			return Vector2(-spawn_margin, randf_range(-spawn_margin, viewport_size.y + spawn_margin))
		1:  # right
			return Vector2(viewport_size.x + spawn_margin, randf_range(-spawn_margin, viewport_size.y + spawn_margin))
		2:  # top
			return Vector2(randf_range(-spawn_margin, viewport_size.x + spawn_margin), -spawn_margin)
		3:  # bottom
			return Vector2(randf_range(-spawn_margin, viewport_size.x + spawn_margin), viewport_size.y + spawn_margin)
	return Vector2.ZERO


func _direction_for_side(side: int) -> Vector2:
	var angle_offset := randf_range(-PI / 2.0, PI / 2.0)
	var direction := Vector2.ZERO
	match side:
		0:
			direction = Vector2.RIGHT.rotated(angle_offset)
		1:
			direction = Vector2.LEFT.rotated(angle_offset)
		2:
			direction = Vector2.DOWN.rotated(angle_offset)
		3:
			direction = Vector2.UP.rotated(angle_offset)
	return direction.normalized()
