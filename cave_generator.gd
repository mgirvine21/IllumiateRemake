extends Node

@export var map_width: int = 20
@export var map_height: int = 20
@export var redraw: bool = false:
	set(value):
		_do_redraw()

@export var world_seed: String = "Hello Godot!"
@export var noise_octaves: int = 2
@export var noise_period: float = 3.0
@export var noise_persistence: float = 0.5
@export var noise_lacunarity: float = 0.4
@export var noise_threshold: float = 0.5

@export var cave_layer: TileMapLayer
@export var vine_layer: TileMapLayer
@export var vine_source_id: int = 0
@export var vine_top_atlas: Vector2i = Vector2i(10,0)
@export var vine_mid_atlas: Vector2i = Vector2i(10,1)
@export var vine_end_atlas: Vector2i = Vector2i(10,2)

@export var vine_spawn_chance: float = 0.25
@export var vine_min_spacing: int = 2
@export var vine_max_length: int = 9

var vine_length_weights := {1: 40, 3: 30, 5: 15, 7: 10, 9: 5}

# Set these to match the Terrain Set / Terrain you configure on the
# TileMapLayer's TileSet resource (TileSet > Terrains tab).
@export var terrain_set: int = 0
@export var terrain: int = 0

var tile_map: TileMapLayer
var simplex_noise: FastNoiseLite = FastNoiseLite.new()

func _ready() -> void:
	tile_map = cave_layer
	_do_redraw()

func _do_redraw() -> void:
	if tile_map == null:
		return
	clear()
	generate()

func clear() -> void:
	tile_map.clear()

func generate() -> void:
	simplex_noise.seed = world_seed.hash()
	simplex_noise.fractal_octaves = noise_octaves
	simplex_noise.frequency = 1.0 / max(noise_period, 0.001)
	simplex_noise.fractal_gain = noise_persistence
	simplex_noise.fractal_lacunarity = noise_lacunarity

	var wall_cells: Array[Vector2i] = []
	var wall_set: Dictionary = {}
	for x in range(-map_width / 2, map_width / 2):
		for y in range(-map_height / 2, map_height / 2):
			if simplex_noise.get_noise_2d(x, y) < noise_threshold:
				var cell = (Vector2i(x, y))
				wall_cells.append(cell)
				wall_set[cell] = true
	# set_cells_terrain_connect looks at each cell's neighbors and picks the
	# matching tile automatically -- this replaces the old manual
	# get_cell_autotile_coord()/update_bitmask_area() calls entirely.
	tile_map.set_cells_terrain_connect(wall_cells, terrain_set, terrain, false)
	generate_vines(wall_set)

func generate_vines(wall_set: Dictionary) -> void:
	vine_layer.clear()
	print("vine_layer tileset: ", vine_layer.tile_set)
	print("source count: ", vine_layer.tile_set.get_source_count() if vine_layer.tile_set else "NO TILESET")
	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed.hash() ^ 0x5EED
	var last_vine_x: int = -9999

	var count_ceiling := 0
	var count_spacing_fail := 0
	var count_chance_fail := 0
	var count_placed := 0

	for cell in wall_set.keys():
		var below = cell + Vector2i(0, 1)
		if wall_set.has(below):
			continue
		count_ceiling += 1

		if abs(cell.x - last_vine_x) < vine_min_spacing:
			count_spacing_fail += 1
			continue
		if rng.randf() > vine_spawn_chance:
			count_chance_fail += 1
			continue

		var depth = _measure_open_depth(cell, wall_set)
		var length = _pick_vine_length(rng, depth)
		if length <= 0:
			continue

		_place_vine(cell, length)
		count_placed += 1
		last_vine_x = cell.x

	print("ceiling candidates: ", count_ceiling)
	print("spacing failed: ", count_spacing_fail)
	print("chance failed: ", count_chance_fail)
	print("vines placed: ", count_placed)

func _measure_open_depth(ceiling_cell: Vector2i, wall_set: Dictionary) -> int:
	var depth := 0
	var check := ceiling_cell + Vector2i(0, 1)
	while not wall_set.has(check) and depth < vine_max_length:
		depth += 1
		check += Vector2i(0, 1)
	return depth

func _pick_vine_length(rng: RandomNumberGenerator, max_depth: int) -> int:
	var candidates: Array = []
	for length in vine_length_weights.keys():
		if length <= max_depth:
			for i in range(vine_length_weights[length]):
				candidates.append(length)
	if candidates.is_empty():
		return 0
	return candidates[rng.randi_range(0, candidates.size() - 1)]

func _place_vine(ceiling_cell: Vector2i, length: int) -> void:
	if length == 1:
		vine_layer.set_cell(ceiling_cell + Vector2i(0, 1), vine_source_id, vine_end_atlas)
		return
	for i in range(length):
		var pos = ceiling_cell + Vector2i(0, 1 + i)
		var atlas: Vector2i
		if i == 0:
			atlas = vine_top_atlas
		elif i == length - 1:
			atlas = vine_end_atlas
		else:
			atlas = vine_mid_atlas
		vine_layer.set_cell(pos, vine_source_id, atlas)
