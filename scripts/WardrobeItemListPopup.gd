extends PopupPanel

# --- SİNYALLER ---
signal item_chosen(item_data) 
signal item_deleted(item_data)
signal item_edited(old_data, new_data)

# --- UI REFERANSLARI ---
@onready var grid = $VBoxContainer/ScrollContainer/GridContainer
@onready var title_label = $VBoxContainer/Label
@onready var close_button = $VBoxContainer/CloseButton 
@onready var confirm_dialog = $ConfirmationDialog

# --- DEĞİŞKENLER ---
var edit_dialog: ConfirmationDialog
var edit_name_input: LineEdit
var edit_category_input: OptionButton
var edit_color_input: OptionButton
var item_being_edited = null
var item_card_prefab = preload("res://scenes/prefabs/ItemCard.tscn")
var item_to_delete = null 
var current_active_category: String = ""

# --- SABİTLER ---
const CATEGORIES = [
	{"id": "upper", "text": "Top"}, {"id": "lower", "text": "Bottom"},
	{"id": "shoes", "text": "Shoes"}, {"id": "outer", "text": "Outerwear"},
	{"id": "dress", "text": "Dress"}
]
const COLORS = ["White", "Black", "Grey", "Red", "Blue", "Green", "Yellow", "Orange", "Pink", "Purple", "Brown", "Beige"]

# --- BAŞLANGIÇ ---
func _ready():
	# 🔥 İŞTE ÇÖZÜM BURADA 🔥
	# Bu ana listenin kendisini "Modal" yapar. 
	# Arkadaki her şeyi kilitler ve dışarı tıklayınca kapanmayı engeller.
	exclusive = true 
	
	if close_button: close_button.pressed.connect(_on_button_pressed)
	
	# 1. DELETE PENCERESİ
	if not confirm_dialog:
		confirm_dialog = ConfirmationDialog.new()
		add_child(confirm_dialog)
	
	# Pencere Ayarları (Buralar zaten doğruydu)
	confirm_dialog.exclusive = true
	confirm_dialog.always_on_top = true
	confirm_dialog.transient = true
	confirm_dialog.title = "" 
	confirm_dialog.borderless = true 
	confirm_dialog.dialog_text = "Are you sure?"
	confirm_dialog.dialog_autowrap = true
	confirm_dialog.min_size = Vector2(350, 200)
	confirm_dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	confirm_dialog.ok_button_text = "Delete"
	confirm_dialog.cancel_button_text = "Cancel"
	
	confirm_dialog.get_ok_button().custom_minimum_size.y = 60
	confirm_dialog.get_cancel_button().custom_minimum_size.y = 60
	
	apply_window_style(confirm_dialog)
	
	if not confirm_dialog.confirmed.is_connected(_on_confirm_delete):
		confirm_dialog.confirmed.connect(_on_confirm_delete)

	# 2. EDIT PENCERESİ
	create_edit_dialog()
	var q_manager = get_node_or_null("/root/QuestManager")
	if q_manager:
		q_manager.trigger_action("first_wardrobe")

# 🔥 PENCERE VE BUTON STİLİ
func apply_window_style(window_node: Window):
	var font = load("res://assets/fonts/PressStart2P-Regular.ttf")
	if font: window_node.add_theme_font_override("font", font)
	
	window_node.add_theme_font_size_override("font_size", 13)
	
	var window_style = StyleBoxFlat.new()
	window_style.bg_color = Color("553801") 
	window_style.border_color = Color("c48605") 
	window_style.set_border_width_all(3) 
	window_style.set_corner_radius_all(15) 
	window_style.content_margin_left = 20; window_style.content_margin_right = 20
	window_style.content_margin_top = 20; window_style.content_margin_bottom = 20
	
	window_node.add_theme_stylebox_override("embedded_border", window_style)
	window_node.add_theme_stylebox_override("panel", window_style)

	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color("6d4c03")
	btn_style.border_color = Color("c48605")
	btn_style.set_border_width_all(2)
	btn_style.set_corner_radius_all(10)
	btn_style.content_margin_top = 15; btn_style.content_margin_bottom = 15
	btn_style.content_margin_left = 20; btn_style.content_margin_right = 20
	
	var btn_hover = btn_style.duplicate(); btn_hover.bg_color = Color("855e04")
	var btn_pressed = btn_style.duplicate(); btn_pressed.bg_color = Color("4a3001")

	var buttons = [window_node.get_ok_button(), window_node.get_cancel_button()]
	for btn in buttons:
		if btn:
			btn.add_theme_stylebox_override("normal", btn_style)
			btn.add_theme_stylebox_override("hover", btn_hover)
			btn.add_theme_stylebox_override("pressed", btn_pressed)
			if font: btn.add_theme_font_override("font", font)
			btn.custom_minimum_size.y = 60

# 🔥 INPUT ALANI STİLİ
func apply_input_style(input_node: Control):
	var font = load("res://assets/fonts/PressStart2P-Regular.ttf")
	if font: input_node.add_theme_font_override("font", font)
	input_node.add_theme_font_size_override("font_size", 12)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color("553801") 
	style.border_color = Color("c48605") 
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 10 
	style.content_margin_right = 10 
	
	input_node.add_theme_stylebox_override("normal", style)
	input_node.add_theme_stylebox_override("focus", style)
	input_node.add_theme_stylebox_override("hover", style)
	input_node.add_theme_stylebox_override("pressed", style)
	
	input_node.add_theme_color_override("font_color", Color.WHITE)
	input_node.add_theme_color_override("font_focus_color", Color.WHITE)
	input_node.add_theme_color_override("font_hover_color", Color.WHITE)
	input_node.add_theme_color_override("font_pressed_color", Color.WHITE)
	
	if input_node is OptionButton:
		var popup = input_node.get_popup()
		if popup:
			popup.always_on_top = true 
			popup.transparent_bg = true 
			
			var popup_style = style.duplicate()
			popup_style.bg_color = Color("4a3001") 
			
			popup.add_theme_stylebox_override("panel", popup_style)
			
			var hover_style = style.duplicate()
			hover_style.bg_color = Color("2b1a00")
			hover_style.set_border_width_all(0)
			popup.add_theme_stylebox_override("hover", hover_style)
			
			if font: popup.add_theme_font_override("font", font)
			popup.add_theme_font_size_override("font_size", 12)
			popup.add_theme_color_override("font_color", Color.WHITE)
			popup.add_theme_color_override("font_hover_color", Color("c48605"))

func create_edit_dialog():
	edit_dialog = ConfirmationDialog.new()
	
	# Bu küçük pencereler zaten exclusive idi ama garanti olsun
	edit_dialog.exclusive = true
	edit_dialog.always_on_top = true
	edit_dialog.transient = true
	
	edit_dialog.title = "" 
	edit_dialog.borderless = true
	edit_dialog.min_size = Vector2(350, 320)
	edit_dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	edit_dialog.ok_button_text = "Save"
	edit_dialog.cancel_button_text = "Cancel"
	
	edit_dialog.get_ok_button().custom_minimum_size.y = 60
	edit_dialog.get_cancel_button().custom_minimum_size.y = 60
	
	apply_window_style(edit_dialog)
	
	var vbox = VBoxContainer.new()
	edit_dialog.add_child(vbox)
	
	vbox.add_child(Label.new().duplicate()) 
	var lbl_name = Label.new(); lbl_name.text = "Item Name:"; vbox.add_child(lbl_name)
	
	edit_name_input = LineEdit.new()
	edit_name_input.custom_minimum_size.y = 45
	apply_input_style(edit_name_input) 
	vbox.add_child(edit_name_input)
	
	var lbl_cat = Label.new(); lbl_cat.text = "Category:"; vbox.add_child(lbl_cat)
	
	edit_category_input = OptionButton.new()
	edit_category_input.custom_minimum_size.y = 45
	apply_input_style(edit_category_input) 
	for cat in CATEGORIES:
		edit_category_input.add_item(cat["text"])
		edit_category_input.set_item_metadata(edit_category_input.item_count - 1, cat["id"])
	vbox.add_child(edit_category_input)
	
	var lbl_col = Label.new(); lbl_col.text = "Color:"; vbox.add_child(lbl_col)
	
	edit_color_input = OptionButton.new()
	edit_color_input.custom_minimum_size.y = 45
	apply_input_style(edit_color_input) 
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
		open_category(current_active_category)

func _on_card_edit_request(data):
	item_being_edited = data
	edit_name_input.text = data.get("item_name", "")
	
	var current_cat = data.get("category", "upper")
	for i in range(edit_category_input.item_count):
		if edit_category_input.get_item_metadata(i) == current_cat:
			edit_category_input.select(i); break
			
	var current_col = data.get("color", "White")
	for i in range(edit_color_input.item_count):
		if edit_color_input.get_item_text(i) == current_col:
			edit_color_input.select(i); break
			
	edit_dialog.popup_centered()

func _on_edit_confirmed():
	if item_being_edited:
		var new_name = edit_name_input.text
		var new_cat = edit_category_input.get_selected_metadata()
		var new_color = edit_color_input.get_item_text(edit_color_input.selected)
		
		var new_data = item_being_edited.duplicate()
		new_data["item_name"] = new_name
		new_data["category"] = new_cat
		new_data["color"] = new_color
		
		emit_signal("item_edited", item_being_edited, new_data)
		item_being_edited = null
		open_category(current_active_category)

func _on_button_pressed(): hide()
