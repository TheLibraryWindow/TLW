extends Node2D

signal seed_changed(seed: int)

@onready var tile_map: TileMap = $TileMap

# Layers
var ground_layer: int = 1
var environment_layer: int = 2

# Tileset custom data
var can_place_seed_custom_data := "can_place_seeds"
var can_place_dirt_custom_data := "can_place_dirt"

# Farming modes
enum FARMING_MODES { SEEDS, DIRT }
var farming_modes_state: int = FARMING_MODES.DIRT

# Terrain connect IDs
# These correspond to your Tileset Terrain Sets (top to bottom = 0–3)
const TERRAIN_WATER_SAND := 0
const TERRAIN_SAND_GRASS := 1
const TERRAIN_GRASS_DIRT := 2
const TERRAIN_CLIFFS := 3

var dirt_tiles: Array[Vector2i] = []

# Proc-gen
@export var noise_texture: NoiseTexture2D
@export var map_width: int  = 320
@export var map_height: int = 180
@export var noise_frequency: float = 0.05

# --- Terrain thresholds ---
@export var land_threshold: float = -0.1
@export var sand_threshold: float = 0.05
@export var grass_threshold: float = 0.25
@export var cliff_threshold: float = 0.55

@export var source_id: int = 0

var noise: Noise
const SAVE_PATH := "user://world_seed.json"
var current_seed: int = 0
var world_version: int = 0

# === READY ===
func _ready() -> void:
	set_process_input(true)
	set_process_unhandled_input(true)
	_init_noise()
	_load_or_init_seed()
	_generate_world()
	print("[WORLD] Ready → ground:", ground_layer, " env:", environment_layer, " seed:", current_seed)

# === INPUT ===
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_world"):
		var main := get_tree().root.get_node_or_null("Main")
		if main and main.has_method("toggle_world"):
			main.toggle_world()
		return

	if Input.is_action_just_pressed("toggle_dirt"):
		farming_modes_state = FARMING_MODES.DIRT

	if Input.is_action_just_pressed("toggle_seeds"):
		farming_modes_state = FARMING_MODES.SEEDS

	if Input.is_action_just_pressed("click"):
		var tile_mouse_pos: Vector2i = tile_map.local_to_map(tile_map.to_local(get_global_mouse_position()))
		if farming_modes_state == FARMING_MODES.SEEDS:
			var atlas_coord := Vector2i(20, 0)
			if _retrieve_custom_data(tile_mouse_pos, can_place_seed_custom_data, ground_layer):
				handle_seed(tile_mouse_pos, 0, atlas_coord, 3, world_version)
		elif farming_modes_state == FARMING_MODES.DIRT:
			if _retrieve_custom_data(tile_mouse_pos, can_place_dirt_custom_data, ground_layer):
				if not dirt_tiles.has(tile_mouse_pos):
					dirt_tiles.append(tile_mouse_pos)
				tile_map.set_cells_terrain_connect(ground_layer, dirt_tiles, TERRAIN_GRASS_DIRT, 0)

# === WORLD RESET ===
func reset_world(use_new_seed: bool = true) -> void:
	world_version += 1
	_clear_world_tiles()
	if use_new_seed:
		randomize()
		current_seed = randi()
		_save_seed(current_seed)
	_apply_seed_to_noise(current_seed)
	_generate_world()
	emit_signal("seed_changed", current_seed)

func wipe_world() -> void:
	world_version += 1
	_clear_world_tiles()

func get_seed() -> int:
	return current_seed

# === NOISE / SEED ===
func _init_noise() -> void:
	if noise_texture and noise_texture.noise:
		noise = noise_texture.noise
	else:
		noise = FastNoiseLite.new()

func _apply_seed_to_noise(seed_value: int) -> void:
	if noise is FastNoiseLite:
		(noise as FastNoiseLite).seed = seed_value

func _load_or_init_seed() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		var data = JSON.parse_string(f.get_as_text())
		if typeof(data) == TYPE_DICTIONARY and data.has("seed"):
			current_seed = int(data.get("seed"))
		else:
			current_seed = 0
	else:
		current_seed = 0
		_save_seed(current_seed)
	_apply_seed_to_noise(current_seed)
	emit_signal("seed_changed", current_seed)

func _save_seed(seed_value: int) -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({"seed": seed_value}))

# === PROC-GEN ===
func _generate_world() -> void:
	for x in range(map_width):
		for y in range(map_height):
			var n := noise.get_noise_2d(float(x), float(y))
			n = (n + 1.0) * 0.5  # normalize from [-1,1] to [0,1]
			var pos := Vector2i(x, y)

			# Terrain selection by noise thresholds
			if n < land_threshold:
				tile_map.set_cells_terrain_connect(ground_layer, [pos], TERRAIN_WATER_SAND, 0)
			elif n >= land_threshold and n < sand_threshold:
				tile_map.set_cells_terrain_connect(ground_layer, [pos], TERRAIN_WATER_SAND, 0)
			elif n >= sand_threshold and n < grass_threshold:
				tile_map.set_cells_terrain_connect(ground_layer, [pos], TERRAIN_SAND_GRASS, 0)
			elif n >= grass_threshold and n < cliff_threshold:
				tile_map.set_cells_terrain_connect(ground_layer, [pos], TERRAIN_GRASS_DIRT, 0)
			elif n >= cliff_threshold:
				tile_map.set_cells_terrain_connect(ground_layer, [pos], TERRAIN_CLIFFS, 0)

func _clear_world_tiles() -> void:
	tile_map.clear_layer(ground_layer)
	tile_map.clear_layer(environment_layer)
	dirt_tiles.clear()

# === HELPERS ===
func _retrieve_custom_data(tile_pos: Vector2i, custom_data_key: String, layer: int) -> bool:
	var tile_data: TileData = tile_map.get_cell_tile_data(layer, tile_pos)
	return tile_data and tile_data.get_custom_data(custom_data_key)

# === SEED GROWTH ===
func handle_seed(tile_pos: Vector2i, level: int, atlas_coord: Vector2i, final_seed_level: int, version: int) -> void:
	if version != world_version:
		return
	tile_map.set_cell(environment_layer, tile_pos, 0, atlas_coord)
	if level >= final_seed_level:
		return
	await get_tree().create_timer(5.0).timeout
	var next_atlas := Vector2i(atlas_coord.x + 1, atlas_coord.y)
	handle_seed(tile_pos, level + 1, next_atlas, final_seed_level, version)
