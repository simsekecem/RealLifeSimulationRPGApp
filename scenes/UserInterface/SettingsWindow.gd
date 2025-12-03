extends Control
@onready var close_button = $Background/CloseButton

func _ready():
	# CloseButton'a basılınca pencereyi kapatma fonksiyonunu bağla
	close_button.pressed.connect(hide_settings_window)
	print("SettingsWindow bağlantıları kuruldu.")

func hide_settings_window():
	"""SettingsWindow'u tamamen gizler."""
	# Bu düğümün kendisini (SettingsWindow'u) gizler.
	self.visible = false
	print("SettingsWindow kapandı.")
