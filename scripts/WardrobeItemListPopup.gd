extends PopupPanel

# Sinyaller
signal item_chosen(item_data) 
signal item_deleted(item_data)
# 🔥 YENİ: Düzenleme bitti sinyali
signal item_edited(old_data, new_data)

@onready var grid = $VBoxContainer/ScrollContainer/GridContainer
@onready var title_label = $VBoxContainer/Label
@onready var close_button = $VBoxContainer/CloseButton 
@onready var confirm_dialog = $ConfirmationDialog

# 🔥 YENİ DEĞİŞKENLER (Edit Penceresi İçin)
var edit_dialog: ConfirmationDialog
var edit_name_input: LineEdit
var edit_category_input: OptionButton
var edit_color_input: OptionButton
var item_being_edited = null

var item_card_prefab = preload("res://scenes/prefabs/ItemCard.tscn")
var item_to_delete = null 
var current_active_category: String = ""

# Kategori Listesi (Kod - Görünen İsim)
const CATEGORIES = [
	{"id": "upper", "text": "Top"},
	{"id": "lower", "text": "Bottom"},
	{"id": "shoes", "text": "Shoes"},
	{"id": "outer", "text": "Outerwear"},
	{"id": "dress", "text": "Dress"}
]

# Renk Listesi
const COLORS = ["White", "Black", "Grey", "Red", "Blue", "Green", "Yellow", "Orange", "Pink", "Purple", "Brown", "Beige"]

func _ready():
	if close_button: close_button.pressed.connect(_on_button_pressed)
	
	# --- SİLME ONAY PENCERESİ (Önceki Ayarlar) ---
	if not confirm_dialog:
		confirm_dialog = ConfirmationDialog.new()
		add_child(confirm_dialog)
	confirm_dialog.title = "Delete Item"
	confirm_dialog.dialog_text = "Are you sure?"
	confirm_dialog.dialog_autowrap = true
	confirm_dialog.min_size = Vector2(300, 150)
	confirm_dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	confirm_dialog.ok_button_text = "Delete"
	confirm_dialog.cancel_button_text = "Cancel"
	if not confirm_dialog.confirmed.is_connected(_on_confirm_delete):
		confirm_dialog.confirmed.connect(_on_confirm_delete)

	# --- 🔥 YENİ: DÜZENLEME PENCERESİ OLUŞTUR ---
	create_edit_dialog()

func create_edit_dialog():
	edit_dialog = ConfirmationDialog.new()
	edit_dialog.title = "Edit Item"
	edit_dialog.min_size = Vector2(320, 300)
	edit_dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	edit_dialog.ok_button_text = "Save"
	edit_dialog.cancel_button_text = "Cancel"
	
	var vbox = VBoxContainer.new()
	edit_dialog.add_child(vbox)
	
	# 1. İsim Alanı
	vbox.add_child(Label.new().duplicate()) # Spacer
	var lbl_name = Label.new(); lbl_name.text = "Item Name:"; vbox.add_child(lbl_name)
	edit_name_input = LineEdit.new()
	vbox.add_child(edit_name_input)
	
	# 2. Kategori Alanı
	var lbl_cat = Label.new(); lbl_cat.text = "Category:"; vbox.add_child(lbl_cat)
	edit_category_input = OptionButton.new()
	for cat in CATEGORIES:
		edit_category_input.add_item(cat["text"])
		edit_category_input.set_item_metadata(edit_category_input.item_count - 1, cat["id"])
	vbox.add_child(edit_category_input)
	
	# 3. Renk Alanı
	var lbl_col = Label.new(); lbl_col.text = "Color:"; vbox.add_child(lbl_col)
	edit_color_input = OptionButton.new()
	for col in COLORS:
		edit_color_input.add_item(col)
	vbox.add_child(edit_color_input)
	
	add_child(edit_dialog)
	edit_dialog.confirmed.connect(_on_edit_confirmed)

func open_category(category_name: String):
	current_active_category = category_name
	title_label.text = category_name.capitalize()
	
	for child in grid.get_children(): child.queue_free()
	
	var wardrobe = Globals.cache.get("wardrobe", [])
	var target_cat = category_name.to_lower()
	var filtered = wardrobe.filter(func(i): return i.get("category", "").to_lower() == target_cat)
	
	for data in filtered:
		var card = item_card_prefab.instantiate()
		grid.add_child(card)
		card.setup(data) 
		card.item_selected.connect(_on_card_selected)
		card.item_delete_requested.connect(_on_card_delete_request)
		# 🔥 YENİ: Edit sinyalini bağla
		card.item_edit_requested.connect(_on_card_edit_request)
	
	if not visible: popup_centered() 

# --- İŞLEVLER ---

func _on_card_selected(data):
	emit_signal("item_chosen", data)
	hide() 

func _on_card_delete_request(data):
	item_to_delete = data
	confirm_dialog.popup_centered()

func _on_confirm_delete():
	if item_to_delete:
		emit_signal("item_deleted", item_to_delete)
		item_to_delete = null
		open_category(current_active_category) # Listeyi yenile

# 🔥 YENİ: KARTTAN GELEN EDIT İSTEĞİ
func _on_card_edit_request(data):
	item_being_edited = data
	
	# Mevcut verileri kutulara doldur
	edit_name_input.text = data.get("item_name", "")
	
	# Kategoriyi seç
	var current_cat = data.get("category", "upper")
	for i in range(edit_category_input.item_count):
		if edit_category_input.get_item_metadata(i) == current_cat:
			edit_category_input.select(i)
			break
			
	# Rengi seç
	var current_col = data.get("color", "White")
	for i in range(edit_color_input.item_count):
		if edit_color_input.get_item_text(i) == current_col:
			edit_color_input.select(i)
			break
			
	edit_dialog.popup_centered()

# 🔥 YENİ: EDIT KAYDET (SAVE BUTONU)
func _on_edit_confirmed():
	if item_being_edited:
		var new_name = edit_name_input.text
		var new_cat = edit_category_input.get_selected_metadata()
		var new_color = edit_color_input.get_item_text(edit_color_input.selected)
		
		# Yeni veri objesini oluştur
		var new_data = item_being_edited.duplicate()
		new_data["item_name"] = new_name
		new_data["category"] = new_cat
		new_data["color"] = new_color
		
		# Ana sahneye bildir
		emit_signal("item_edited", item_being_edited, new_data)
		
		item_being_edited = null
		# Eğer kategori değiştiyse, o anki listeden kaybolması normaldir, yenile:
		open_category(current_active_category)

func _on_button_pressed(): hide()
