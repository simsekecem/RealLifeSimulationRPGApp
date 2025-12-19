extends PopupPanel

@onready var grid = $VBoxContainer/ScrollContainer/GridContainer
@onready var title_label = $VBoxContainer/Label
var item_card_prefab = preload("res://scenes/prefabs/ItemCard.tscn")

func open_category(category_name: String):
	title_label.text = category_name.capitalize()
	
	# Önceki içeriği temizle
	for child in grid.get_children():
		child.queue_free()
	
	# Globals.cache içindeki wardrobe listesini filtrele
	var wardrobe = Globals.cache.get("wardrobe", [])
	var filtered = wardrobe.filter(func(i): return i.category == category_name.to_lower())
	
	for data in filtered:
		var card = item_card_prefab.instantiate()
		grid.add_child(card)
		card.setup(data) # ItemCard içindeki setup() fonksiyonu çalışır
		
		# Sinyalleri bağla
		card.item_selected.connect(_on_card_selected)
	
	popup_centered() # Ekranda ortala ve göster

func _on_card_selected(data):
	# Seçilen eşyayı ana dolapta aktif etme mantığı buraya gelecek
	hide()

func _on_button_pressed(): # Kapat butonu
	hide()
