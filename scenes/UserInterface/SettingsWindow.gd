extends Control
@onready var close_button = $Background/CloseButton
@onready var volume_slider: HSlider = $VolumeSlider


func _ready():
	# CloseButton'a basılınca pencereyi kapatma fonksiyonunu bağla
	close_button.pressed.connect(hide_settings_window)
	print("SettingsWindow bağlantıları kuruldu.")

func hide_settings_window():
	"""SettingsWindow'u tamamen gizler."""
	# Bu düğümün kendisini (SettingsWindow'u) gizler.
	self.visible = false
	print("SettingsWindow kapandı.")


func _on_volume_slider_value_changed(value):
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		db
	)
