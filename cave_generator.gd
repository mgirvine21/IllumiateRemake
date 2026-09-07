extends Node

@export var map_width: int = 80
@export var map_height: int = 50
@export var redraw: bool = false:
	set(value):
		_do_redraw()

@export var world_seed: String = "Hello Godot!"
@export var noise_octaves: int = 2
@export var noise_period: float = 3.0
@export var noise_persistence: float = 0.5
@export var noise_lacunarity: float = 0.4
@export var noise_threshold: float = 0.5

# Set these to match the Terrain Set / Terrain you configure on the
# TileMapLayer's TileSet resource (TileSet > Terrains tab).
@export var terrain_set: int = 0
@export var terrain: int = 0

var tile_map: TileMapLayer
var simplex_noise: FastNoiseLite = FastNoiseLite.new()

func _ready() -> void:
	tile_map = get_parent() as TileMapLayer
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
	for x in range(-map_width / 2, map_width / 2):
		for y in range(-map_height / 2, map_height / 2):
			if simplex_noise.get_noise_2d(x, y) < noise_threshold:
				wall_cells.append(Vector2i(x, y))

	# set_cells_terrain_connect looks at each cell's neighbors and picks the
	# matching tile automatically -- this replaces the old manual
	# get_cell_autotile_coord()/update_bitmask_area() calls entirely.
	tile_map.set_cells_terrain_connect(wall_cells, terrain_set, terrain, false)
