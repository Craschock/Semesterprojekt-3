@tool
class_name BiomeData
extends Resource


##where in the world this biome is allowed to be placed (world generator always obeys what u put here)
enum Placement {
	ANYWHERE,      ##can be placed in any region slot
	SURFACE_ONLY,  ##must be in the top row (gets open sky + terrain surface instead of top wall)
	DEEP_ONLY,     ##must be in the bottom row (e.g. Underworld biome)
}
#good boy world generator

@export_group("Identification")

##human-readable name, not used in code only for debug and for fun i guess
@export var biome_name: String = "Unnamed Biome"


@export_group("Placement")

##where this biome is allowed to live in the world grid
@export var placement: Placement = Placement.ANYWHERE

##if true and this biome sits on the surface row, the top wall is replaced by
##an open sky with a terrain surface 
##(only has an effect for SURFACE_ONLY biomes / top row)
@export var has_open_sky: bool = false

##how high (in tiles) the sky reaches before the AVERAGE ground level
##(only has an effect for SURFACE_ONLY biomes / top row)
@export var surface_air_height: int = 24

##max hill amplitude in tiles (how high hills can be from average base level)
@export_range(0, 64) var surface_variation: int = 10

##frequency of the hill heightmap
##lower = smoother hills
##higher = spiky mountains
@export_range(0.001, 0.2, 0.001) var surface_hill_frequency: float = 0.02
# higher haha  (ich war higher als ich dass gecoded hab haha)

##how many octaves hills have 
##(lowkey weiß ich nicht GENAU was das heißt, aber es ist mehr realistisch bei 3 und weniger bei 2 oder 4)
@export_range(1, 6) var surface_hill_octaves: int = 3

##depth in tiles below average ground before caves start
##from y 0 to this depth, the ground is mostly solid, beyond the cave noise takes over
##it is not EXACT, because it slowly fades but should be pretty accurate
@export_range(1, 256) var cave_fade_depth: int = 40


@export_group("Prebuilt Rooms")

##if true, player spawns inside THIS biomes spawn room
##make sure to give this flag to only one biome at a time
##(this biome should be SURFACE_ONLY and have open sky)
@export var is_spawn_biome: bool = false

##carves a spawn room in the top of the cave area
##has no effect if this biomeisnt spawn biome
@export var has_spawn_room: bool = true

##INTERIOR size of the spawn room
@export var spawn_room_size: Vector2i = Vector2i(20, 10)

##carves a boss room in the bottom of the cave area
@export var has_boss_room: bool = true

##INTERIOR size of the boss room
@export var boss_room_size: Vector2i = Vector2i(40, 24)

##thickness of the wall-border of spawn and boss room
@export_range(1, 8) var room_wall_thickness: int = 2


@export_group("Terrain Noise")

##so all biomes are different even if parameters would be the same (keep at 0 if you want no change visible)
@export var seed_offset: int = 0

@export var noise_type: FastNoiseLite.NoiseType = FastNoiseLite.TYPE_PERLIN

##the lower, the bigger the features in world, the higher the more noise like lol
@export_range(0.001, 0.5, 0.001) var frequency: float = 0.04

##cells with nouse value above treshold are solid.
##the lower the more solid blocks in biome, the higher the more open space
@export_range(-1.0, 1.0, 0.01) var threshold: float = 0.0

@export_range(1, 8) var fractal_octaves: int = 3
@export_range(1.0, 4.0, 0.01) var fractal_lacunarity: float = 2.0
@export_range(0.0, 1.0, 0.01) var fractal_gain: float = 0.5


@export_group("Tile Atlas")

##atlas source id of foreground TileMapLayer (edges)
@export var fg_source_id: int = 0

##atlas source id of background TileMapLayer (inner fillout)
@export var bg_source_id: int = 1

##atlas coord of background tile. (is always 0 idk why u'd need this but why not)
@export var bg_atlas_coord: Vector2i = Vector2i(0, 0)

##number of columns. so if 16 textures and 4 cols -> 4x4 grid u get it (just dont change this)
@export var fg_atlas_cols: int = 4

##probability of a cell being solid before smoothing.
@export_range(0.0, 1.0, 0.01) var ca_initial_fill: float = 0.45

##how often u smooth it (0 = not smooth at all, 10 = smooth like a baby ass)
@export_range(0, 10) var ca_iterations: int = 4


##creates new fastnoiselite for this biome
func create_noise(world_seed: int) -> FastNoiseLite:
	var n = FastNoiseLite.new()
	n.seed = world_seed + seed_offset
	n.noise_type = noise_type
	n.frequency = frequency
	n.fractal_octaves = fractal_octaves
	n.fractal_lacunarity = fractal_lacunarity
	n.fractal_gain = fractal_gain
	return n


##noise used for the shape of hilly surface (separate from cave noise)
func create_surface_noise(world_seed: int) -> FastNoiseLite:
	var n = FastNoiseLite.new()
	#offset the seed so the hill line doesnt correlate with the cave pattern
	n.seed = world_seed + seed_offset + 9173
	n.noise_type = FastNoiseLite.TYPE_PERLIN
	n.frequency = surface_hill_frequency
	n.fractal_octaves = surface_hill_octaves
	n.fractal_lacunarity = 2.0
	n.fractal_gain = 0.5
	return n
