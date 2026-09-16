extends Control

@onready var close_button = $Background/CloseButton
@onready var volume_slider: HSlider = $VolumeSlider

func _ready():
	# Connect close button to hide function
	close_button.pressed.connect(hide_settings_window)
	
	# Load initial volume from Globals.cache (default: 50)
	var saved_volume = 50
	if Globals.cache.has("preferences") and Globals.cache["preferences"].has("music_volume"):
		saved_volume = Globals.cache["preferences"]["music_volume"]
	
	# Set slider value to saved volume
	volume_slider.value = saved_volume
	
	# Apply volume setting on startup
	_apply_volume(saved_volume)
	
	print("SettingsWindow initialized. Volume level: ", saved_volume)

func hide_settings_window():
	"""Hides SettingsWindow."""
	# Save preferences to local cache on close
	Globals.save_cache()
	print("Preferences saved to local cache.")
	
	self.visible = false
	print("SettingsWindow closed.")

func _on_volume_slider_value_changed(value):
	# 1. Apply volume to AudioServer
	_apply_volume(value)
	
	# 2. Update value in Globals.cache
	if Globals.cache.has("preferences"):
		Globals.cache["preferences"]["music_volume"] = value
	
	# Quest trigger
	var q_manager = get_node_or_null("/root/QuestManager")
	if q_manager:
		q_manager.trigger_action("first_music")

# Helper function: applies volume to AudioServer
func _apply_volume(value):
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"), # Ensure "Music" bus exists
		db
	)
