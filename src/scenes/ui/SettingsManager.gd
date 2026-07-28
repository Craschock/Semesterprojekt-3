extends Node

# Settings saved in .cfg files. Preffered are the players settings
const PREFERRED_PATH = "user://preferred_options.cfg"
const DEFAULT_PATH = "user://default_options.cfg"

var config = ConfigFile.new()

# Values for default file
var default_settings = {
	"Video": {
		"resolution_x": 1920,
		"resolution_y": 1080,
		"fullscreen": true,
		"vsync": true
	},
	"Audio": {     # 1.0 = 100% and 0.0 = 0%
		"master": 1.0,
		"music": 1.0,
		"sfx": 1.0
	}
	
}

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	# Place Default file if it does not exist
	if not FileAccess.file_exists(DEFAULT_PATH):
		_save_defaults_to_file()
	
	# Try to load player settings
	var err = config.load(PREFERRED_PATH)
	if err != OK:
		config.load(DEFAULT_PATH)
	
	apply_all_settings()

## Function to use when saving settings from settings UI
func save_settings() -> void:
	config.save(PREFERRED_PATH)
	print("settings saved")

# Creating default file
func _save_defaults_to_file() -> void:
	var def_config = ConfigFile.new()
	for section in default_settings.keys():
		for key in default_settings[section].keys():
			def_config.set_value(section, key, default_settings[section][key])
	
	def_config.save(DEFAULT_PATH)



# Logic for applying settings



func apply_all_settings() -> void:
	apply_video_settings()
	apply_audio_settings()

func apply_video_settings() -> void:
	var res_x = config.get_value("Video", "resolution_x", 1920)
	var res_y = config.get_value("Video", "resolution_y", 1080)
	var is_fullscreen = config.get_value("Video", "fullscreen", true)
	var vsync = config.get_value("Video", "vsync", true)
	
	# Set resolution
	DisplayServer.window_set_size(Vector2i(res_x, res_y))
	
	# Set window mode#
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	# Vsync
	if vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	# TODO: Add more screen settings

func apply_audio_settings() -> void:
	set_bus_volume("Master", config.get_value("Audio", "master", 1.0))
	set_bus_volume("Music", config.get_value("Audio", "music", 1.0))
	set_bus_volume("Sounds", config.get_value("Audio", "sfx", 1.0))

func set_bus_volume(bus_name: String, linear_value: float) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	
	if bus_index >= 0:
		var db_volume = linear_to_db(linear_value)
		AudioServer.set_bus_volume_db(bus_index, db_volume)
