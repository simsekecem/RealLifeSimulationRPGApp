extends Panel

signal item_selected(data)
signal item_edit_requested(data)

@onready var texture_rect = $VBoxContainer/TextureRect
@onready var label = $VBoxContainer/Label

var item_data: Dictionary = {}

func setup(data: Dictionary):
	item_data = data
	# AI'dan gelen sub_category'i (tshirt vb.) başlık yapıyoruz
	label.text = data.get("sub_category", "Unknown").capitalize()
	
	# R2 URL'sinden görseli yükleme
	if data.get("image_url") != "":
		# Globals içindeki resim yükleme fonksiyonunu çağırır
		# Globals.set_remote_image(data["image_url"], texture_rect)
		pass

func _on_select_button_pressed():
	item_selected.emit(item_data)

func _on_edit_button_pressed():
	item_edit_requested.emit(item_data)
