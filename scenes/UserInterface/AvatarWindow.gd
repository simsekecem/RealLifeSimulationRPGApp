extends Control

# Pencere içindeki önemli düğümlere @onready ile erişim
@onready var close_button_main = $CloseButton 
@onready var edit_button = $EditButton
@onready var edit_window = $EditWindow
@onready var close_button_edit = $EditWindow/Background/CloseButton

func _ready():
	# AvatarWindow Kapatma İşlemi
	# Ana penceredeki CloseButton'a basılınca pencereyi kapat.
	close_button_main.pressed.connect(hide_avatar_window)
	
	# EditWindow Açma İşlemi
	# EditButton'a basılınca EditWindow'u göster.
	edit_button.pressed.connect(show_edit_window)
	
	# EditWindow Kapatma İşlemi
	# EditWindow'un içindeki CloseButton'a basılınca EditWindow'u gizle.
	close_button_edit.pressed.connect(hide_edit_window)

	# Başlangıçta EditWindow'u gizli tutun.
	edit_window.visible = false
	
### --- Fonksiyonlar --- ###

func hide_avatar_window():
	"""AvatarWindow'u tamamen gizler."""
	# Bu düğümün kendisini (AvatarWindow'u) gizler.
	self.visible = false
	print("AvatarWindow kapandı.")

func show_edit_window():
	"""EditButton'a tıklandığında EditWindow'u gösterir."""
	edit_window.visible = true
	print("EditWindow açıldı.")

func hide_edit_window():
	"""EditWindow'un içindeki CloseButton'a tıklandığında EditWindow'u gizler."""
	edit_window.visible = false
	print("EditWindow kapandı.")
