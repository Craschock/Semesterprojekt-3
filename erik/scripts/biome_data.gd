@tool
class_name BiomeData
extends Resource


@export_group("Identification")

##human-readable name, not used in code only for debug and for fun i guess
@export var biome_name: String = "Unnamed Biome"


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
#hahahahahaha warum klingt inner fillout wie ein porno titel geht es mir gut oder brauch ich hilfe
@export var bg_source_id: int = 1

##atlas coord of background tile. (is always 0 idk why u'd need this but why not)
@export var bg_atlas_coord: Vector2i = Vector2i(0, 0)

##number of columns. so if 16 textures and 4 cols -> 4x4 grid u get it (just dont change this)
@export var fg_atlas_cols: int = 4

##probability of a cell being solid before smoothing.
@export_range(0.0, 1.0, 0.01) var ca_initial_fill: float = 0.45
##how often u smooth it (0 = not smooth at all, 10 = smooth like a baby ass)
#if this is pedophilia then i have long distance to this
#alles satire btw ich sage damit NICHT dass ich weiß wie smooth der hintern eines babies ist
#kunstfreiheit.
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
