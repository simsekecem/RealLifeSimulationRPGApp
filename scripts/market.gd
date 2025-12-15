extends Control

@onready var btn_g = $VBoxContainer2/G_Button
@onready var btn_hg = $VBoxContainer2/HG_Button
@onready var btn_c = $VBoxContainer2/C_Button
@onready var btn_pc = $VBoxContainer2/PC_Button
@onready var btn_he = $VBoxContainer2/HE_Button
@onready var back_button = $Back_Button

# Panel koduna erişim
@onready var panel: Panel = $Panel

# Hangi kategorideyiz?
var current_category_name = ""

func _ready():
	UI.get_node("UIRoot").show_only_top_right_buttons()
	
	
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Butonları kategorilere göre bağla
	btn_g.pressed.connect(func(): _switch_category("Groceries"))
	btn_hg.pressed.connect(func(): _switch_category("Home Goods"))
	btn_c.pressed.connect(func(): _switch_category("Clothing"))
	btn_pc.pressed.connect(func(): _switch_category("Personal Care"))
	btn_he.pressed.connect(func(): _switch_category("Household Essentials"))

	# Paneli başta gizle
	panel.visible = false
	
	# Globals sinyalini dinle (Veri güncellenirse listeyi yenile)
	if Globals.has_signal("data_updated"):
		if not Globals.data_updated.is_connected(_on_global_data_updated):
			Globals.data_updated.connect(_on_global_data_updated)

func _switch_category(cat_name: String):
	# Eğer zaten açıksa ve panel görünürse işlem yapma (veya yenile)
	# Önceki kategoriyi kaydet (Panel açıksa)
	if panel.visible and current_category_name != "":
		panel.save_items_to_cache()
	
	current_category_name = cat_name
	panel.visible = true
	
	print("🛒 Kategori Açıldı: ", cat_name)
	
	# Panel scriptindeki yükleme fonksiyonunu çağır
	panel.load_category(cat_name)

func _on_back_button_pressed():
	# Çıkarken kaydet
	if panel.visible and current_category_name != "":
		panel.save_items_to_cache()
	
	if UI.has_node("UIRoot"): UI.get_node("UIRoot").return_to_town()

func _on_global_data_updated():
	# Eğer panel açıksa, o anki kategoriyi tekrar yükle
	if panel.visible and current_category_name != "":
		print("🔄 Market: Veri güncellendi, liste yenileniyor...")
		# Not: Kullanıcı yazı yazarken yenilenirse yazısı gidebilir, 
		# ama veri bütünlüğü için yenilemek genelde iyidir.
		panel.load_category(current_category_name)
