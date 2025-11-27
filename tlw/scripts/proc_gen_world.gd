extends Node2D

signal seed_changed(seed: int)

# === TILEMAP LAYERS ===
@onready var water: TileMapLayer       = $water
@onready var ground: TileMapLayer      = $ground
@onready var environment: TileMapLayer = $environment

# === EXPORTED NOISE TEXTURES ===
@export var noise_height_text: NoiseTexture2D
@export var tree_noise_text: NoiseTexture2D

# === WORLD SIZE ===
@export var width: int = 320
@export var height: int = 180

# === TERRAIN CONFIGURATION ===
# Terrain Set 0 (your setup)
# 0 = water, 1 = sand, 2 = grass, 3 = dirt
const TERRAIN_SET   := 0
const TERRAIN_WATER := 0
const TERRAIN_SAND  := 1
const TERRAIN_GRASS := 2
const TERRAIN_DIRT  := 3

# === CUSTOM DATA ===
var can_place_seed_custom_data := "can_place_seeds"
var can_place_dirt_custom_data := "can_place_dirt"

# === FARMING MODES ===
enum FARMING_MODES { SEEDS, DIRT }
var farming_modes_state: int = FARMING_MODES.DIRT

# === NOISE & SEED ===
var noise: Noise
var tree_noise: Noise
var noise_val_arr: Array = []

const SAVE_PATH := "user://world_seed.json"
var current_seed: int = 0
var world_version: int = 0

# === PROC-GEN ARRAYS ===
var sand_tiles_arr: Array[Vector2i] = []
var grass_tiles_arr: Array[Vector2i] = []
var dirt_tiles_arr: Array[Vector2i] = []
var dirt_tiles: Array[Vector2i] = []


# =============================
# === READY / INITIAL LOAD ===
# =============================
func _ready() -> void:
	set_process_input(true)
	_init_noise()
	_load_or_init_seed()
	_apply_seed_to_noise(current_seed)
	generate_world()
	print("[WORLD] Ready with seed:", current_seed)


# =============================
# === INPUT HANDLING ===
# =============================
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_world"):
		var main := get_tree().root.get_node_or_null("Main")
		if main and main.has_method("toggle_world"):
			main.toggle_world()
		return

	if Input.is_action_just_pressed("toggle_dirt"):
		farming_modes_state = FARMING_MODES.DIRT
		print("[FARM] Mode → DIRT")

	if Input.is_action_just_pressed("toggle_seeds"):
		farming_modes_state = FARMING_MODES.SEEDS
		print("[FARM] Mode → SEEDS")

	if Input.is_action_just_pressed("click"):
		var mouse_pos := get_global_mouse_position()
		var tile_mouse_pos := ground.local_to_map(ground.to_local(mouse_pos))
		
		match farming_modes_state:
			FARMING_MODES.SEEDS:
				if _retrieve_custom_data(ground, tile_mouse_pos, can_place_seed_custom_data):
					handle_seed(tile_mouse_pos, 0, Vector2i(20, 0), 3, world_version)
			FARMING_MODES.DIRT:
				if _retrieve_custom_data(ground, tile_mouse_pos, can_place_dirt_custom_data):
					if not dirt_tiles.has(tile_mouse_pos):
						dirt_tiles.append(tile_mouse_pos)
					ground.set_cells_terrain_connect(dirt_tiles, TERRAIN_SET, TERRAIN_DIRT)


# =============================
# === WORLD RESET / SEED ===
# =============================
func reset_world(use_new_seed: bool = true) -> void:
	world_version += 1
	_clear_world_tiles()
	if use_new_seed:
		randomize()
		current_seed = randi()
		_save_seed(current_seed)
	_apply_seed_to_noise(current_seed)
	generate_world()
	emit_signal("seed_changed", current_seed)

func wipe_world() -> void:
	world_version += 1
	_clear_world_tiles()

func get_seed() -> int:
	return current_seed


# =============================
# === NOISE SETUP ===
# =============================
func _init_noise() -> void:
	noise = noise_height_text.noise if noise_height_text and noise_height_text.noise else FastNoiseLite.new()
	tree_noise = tree_noise_text.noise if tree_noise_text and tree_noise_text.noise else FastNoiseLite.new()

func _apply_seed_to_noise(seed_value: int) -> void:
	if noise is FastNoiseLite:
		(noise as FastNoiseLite).seed = seed_value
	if tree_noise is FastNoiseLite:
		(tree_noise as FastNoiseLite).seed = seed_value + 99


# =============================
# === LOAD / SAVE SEED ===
# =============================
func _load_or_init_seed() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		var data = JSON.parse_string(f.get_as_text())
		current_seed = int(data.get("seed", 0)) if typeof(data) == TYPE_DICTIONARY else 0
	else:
		current_seed = 0
		_save_seed(current_seed)
	emit_signal("seed_changed", current_seed)

func _save_seed(seed_value: int) -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({"seed": seed_value}))


# =============================
# === WORLD GENERATION ===
# =============================
func generate_world() -> void:
	sand_tiles_arr.clear()
	grass_tiles_arr.clear()
	dirt_tiles_arr.clear()
	noise_val_arr.clear()

	var min_val := 999.0
	var max_val := -999.0

	for x in range(-width / 2, width / 2):
		for y in range(-height / 2, height / 2):
			var pos := Vector2i(x, y)
			var noise_val := noise.get_noise_2d(x, y)
			var tree_val := tree_noise.get_noise_2d(x, y)
			noise_val_arr.append(noise_val)
			min_val = min(noise_val, min_val)
			max_val = max(noise_val, max_val)

			# Base water
			water.set_cells_terrain_connect([pos], TERRAIN_SET, TERRAIN_WATER)

			# Sand region (shore)
			if noise_val >= -0.05 and noise_val < 0.18:
				sand_tiles_arr.append(pos)
				if tree_val > 0.6 and randi() % 70 == 0:
					environment.set_cells_terrain_connect([pos], TERRAIN_SET, TERRAIN_SAND)

			# Grass region (inner land)
			elif noise_val >= 0.18 and noise_val < 0.55:
				grass_tiles_arr.append(pos)
				if tree_val > 0.7 and randi() % 80 == 0:
					environment.set_cells_terrain_connect([pos], TERRAIN_SET, TERRAIN_GRASS)

			# Dirt / inland peaks
			elif noise_val >= 0.55:
				dirt_tiles_arr.append(pos)
				if tree_val > 0.5 and randi() % 100 == 0:
					environment.set_cells_terrain_connect([pos], TERRAIN_SET, TERRAIN_DIRT)

	print("[NOISE RANGE] min:", str("%.3f" % min_val), " max:", str("%.3f" % max_val))
	print("[DEBUG] Counts → Sand:", sand_tiles_arr.size(), " Grass:", grass_tiles_arr.size(), " Dirt:", dirt_tiles_arr.size())

	ground.set_cells_terrain_connect(sand_tiles_arr, TERRAIN_SET, TERRAIN_SAND)
	ground.set_cells_terrain_connect(grass_tiles_arr, TERRAIN_SET, TERRAIN_GRASS)
	ground.set_cells_terrain_connect(dirt_tiles_arr, TERRAIN_SET, TERRAIN_DIRT)

	print("[WORLD] Generation complete!")


# =============================
# === CLEAR WORLD ===
# =============================
func _clear_world_tiles() -> void:
	for layer in [ground, environment, water]:
		layer.clear()
	dirt_tiles.clear()


# =============================
# === CUSTOM DATA ===
# =============================
func _retrieve_custom_data(layer: TileMapLayer, tile_pos: Vector2i, key: String) -> bool:
	var tile_data := layer.get_cell_tile_data(tile_pos)
	return tile_data and tile_data.get_custom_data(key)


# =============================
# === SEED GROWTH ===
# =============================
func handle_seed(tile_pos: Vector2i, level: int, atlas_coord: Vector2i, final_seed_level: int, version: int) -> void:
	if version != world_version:
		return
	environment.set_cell(tile_pos, 0, atlas_coord)
	if level >= final_seed_level:
		return
	await get_tree().create_timer(5.0).timeout
	handle_seed(tile_pos, level + 1, Vector2i(atlas_coord.x + 1, atlas_coord.y), final_seed_level, version)
