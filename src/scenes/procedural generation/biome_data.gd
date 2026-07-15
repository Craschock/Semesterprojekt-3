@tool
class_name BiomeData
extends Resource


##Where in the world this biome may be placed. The world generator always honours this.
enum Placement {
	ANYWHERE,      ##Can be placed in any region slot.
	SURFACE_ONLY,  ##Must be in the top row. Gets open sky and a terrain surface instead of a top wall.
	DEEP_ONLY,     ##Must be in the bottom row (e.g. an underworld biome).
}

@export_group("Identification")

##Human-readable name. Not used by any logic; shown for debugging and inspector clarity.
@export var biome_name: String = "Unnamed Biome"


@export_group("Placement")

##Where this biome is allowed to live in the world grid.
@export var placement: Placement = Placement.ANYWHERE

##If true and this biome sits on the surface row, the top wall is replaced by
##an open sky with a terrain surface.
##Only has an effect for SURFACE_ONLY biomes in the top row.
@export var has_open_sky: bool = false

##How high, in tiles, the sky reaches above the average ground level.
##Only has an effect for SURFACE_ONLY biomes in the top row.
@export var surface_air_height: int = 24

##Maximum hill amplitude in tiles, measured from the average base level.
@export_range(0, 64) var surface_variation: int = 10

##Frequency of the hill heightmap.
##Lower values give smoother hills.
##Higher values give spiky mountains.
@export_range(0.001, 0.2, 0.001) var surface_hill_frequency: float = 0.02

##Number of octaves used for the hill heightmap.
##3 tends to look the most natural; 2 is smoother and 4 or more gets noisy.
@export_range(1, 6) var surface_hill_octaves: int = 3

##Depth in tiles below the average ground level before caves start.
##Above this depth the ground is mostly solid; below it the cave noise takes over.
##The transition fades gradually, so this is an approximate boundary rather than an exact one.
@export_range(1, 256) var cave_fade_depth: int = 40


@export_group("Prebuilt Rooms")

##If true, the player spawns inside this biome's spawn room.
##Only one biome should carry this flag at a time.
##This biome should be SURFACE_ONLY and have open sky.
@export var is_spawn_biome: bool = false

##Carves a spawn room at the top of the cave area.
##Has no effect unless this biome is the spawn biome.
@export var has_spawn_room: bool = true

##Interior size of the spawn room, excluding walls.
@export var spawn_room_size: Vector2i = Vector2i(20, 10)

##Carves a boss room at the bottom of the cave area.
@export var has_boss_room: bool = true

##Interior size of the boss room, excluding walls.
@export var boss_room_size: Vector2i = Vector2i(40, 24)

##Wall thickness of the spawn and boss rooms.
@export_range(1, 8) var room_wall_thickness: int = 2


@export_group("Terrain Noise")

##Offsets this biome's noise seed so biomes differ even with identical parameters. Leave at 0 for no offset.
@export var seed_offset: int = 0

@export var noise_type: FastNoiseLite.NoiseType = FastNoiseLite.TYPE_PERLIN

##Lower values produce larger terrain features; higher values produce noisier terrain.
@export_range(0.001, 0.5, 0.001) var frequency: float = 0.04

##Cells with a noise value above this threshold are solid.
##Lower values give more solid rock; higher values give more open space.
@export_range(-1.0, 1.0, 0.01) var threshold: float = 0.0

@export_range(1, 8) var fractal_octaves: int = 3
@export_range(1.0, 4.0, 0.01) var fractal_lacunarity: float = 2.0
@export_range(0.0, 1.0, 0.01) var fractal_gain: float = 0.5

@export_group("Decorations")
##All decorations that can spawn in this biome.
@export var decorations: Array[DecorationData] = []

@export_group("Tile Atlas")

##Atlas source id of the foreground TileMapLayer (tile edges).
@export var fg_source_id: int = 0

##Atlas source id of the background TileMapLayer (inner fill).
@export var bg_source_id: int = 1

##Atlas coordinate of the background tile. Normally (0, 0); exposed for flexibility.
@export var bg_atlas_coord: Vector2i = Vector2i(0, 0)

##Number of columns in the foreground atlas (e.g. 16 tiles in 4 columns = a 4x4 grid). Must match the atlas layout.
@export var fg_atlas_cols: int = 4

##Probability of a cell being solid before smoothing.
@export_range(0.0, 1.0, 0.01) var ca_initial_fill: float = 0.45

##Number of smoothing passes. 0 applies no smoothing, 10 is the maximum.
@export_range(0, 10) var ca_iterations: int = 4


##Creates a FastNoiseLite instance configured for this biome.
func create_noise(world_seed: int) -> FastNoiseLite:
	var n = FastNoiseLite.new()
	n.seed = world_seed + seed_offset
	n.noise_type = noise_type
	n.frequency = frequency
	n.fractal_octaves = fractal_octaves
	n.fractal_lacunarity = fractal_lacunarity
	n.fractal_gain = fractal_gain
	return n


##Noise used for the shape of the hilly surface, kept separate from the cave noise.
func create_surface_noise(world_seed: int) -> FastNoiseLite:
	var n = FastNoiseLite.new()
	# Offset the seed so the hill line does not correlate with the cave pattern.
	n.seed = world_seed + seed_offset + 9173
	n.noise_type = FastNoiseLite.TYPE_PERLIN
	n.frequency = surface_hill_frequency
	n.fractal_octaves = surface_hill_octaves
	n.fractal_lacunarity = 2.0
	n.fractal_gain = 0.5
	return n
