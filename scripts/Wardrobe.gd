extends Control

# 🔵 PROJE AYARLARI
const PROJECT_ID = "rzsndtstonztfuayodmg"
const BUCKET_NAME = "wardrobe"

# 🔵 POPUP SAHNESİNİ ÖNCEDEN YÜKLE
var popup_scene := preload("res://scenes/WardrobeItemListPopup.tscn")
var popup: Node

# Mevcut seçimleri takip eden indexler
var current_indices = {"outer": 0, "dress": 0, "upper": 0, "lower": 0, "shoes": 0}
var filtered_cache = {}

func _ready():
	print("🚀 [WARDROBE] Başlatılıyor...")
	
	if UI.has_node("UIRoot"):
		UI.get_node("UIRoot").show_only_top_right_buttons()
	
	# Popup oluşturma
	popup = popup_scene.instantiate()
	add_child(popup)
	popup.hide()
	
	# Buton Bağlantıları
	if has_node("CloseButton"):
		$CloseButton.pressed.connect(_on_close_button_pressed)
	
	# "AddClothesButton" bağlantısını buradan yapıyoruz
	if has_node("AddClothesButton"):
		$AddClothesButton.pressed.connect(_on_add_clothes_button_pressed)
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	refresh_wardrobe_ui()

# --- 📸 RESİM SEÇME VE İŞLEME MANTIĞI ---

func _on_add_clothes_button_pressed():
	print("📂 [WARDROBE] Dosya seçici açılıyor...")
	# Web ve Mobilde galeriyi/dosyaları açar
	DisplayServer.file_dialog_show(
		"Kıyafet Fotoğrafı Seç", 
		"", "", false, 
		DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, 
		["*.jpg", "*.png", "*.jpeg"], 
		_on_file_selected
	)

func _on_file_selected(status: bool, selected_paths: PackedStringArray, _selected_filter_index: int):
	if not status or selected_paths.is_empty():
		return
		
	var img := Image.load_from_file(selected_paths[0])
	if img:
		# 1. BOYUT KÜÇÜLTME: Resim 800px'den genişse küçült
		if img.get_width() > 800:
			var scale = 800.0 / img.get_width()
			img.resize(800, int(img.get_height() * scale), Image.INTERPOLATE_LANCZOS)
		
		# 2. KALİTE DÜŞÜRME: JPEG %70 kalite (Dosya boyutunu KB seviyesine indirir)
		var buffer = img.save_jpg_to_buffer(0.7)
		upload_to_supabase(buffer)

# --- 📤 SUPABASE STORAGE YÜKLEME ---
func upload_to_supabase(image_buffer: PackedByteArray) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	
	var project_id = "rzsndtstonztfuayodmg"
	var file_name = "item_" + str(Time.get_unix_time_from_system()) + ".jpg"
	var url = "https://" + project_id + ".supabase.co/storage/v1/object/wardrobe/" + file_name
	
	var headers = [
		"Authorization: Bearer " + Globals.supabase_anon_key,
		"Content-Type: image/jpeg"
	]
	
	print("📤 [SUPABASE] İkili veri (raw) yükleme başlıyor...")
	
	# HATA ÇÖZÜMÜ: request -> request_raw olarak değiştirildi
	http.request_raw(url, headers, HTTPClient.METHOD_POST, image_buffer)
	
	var response = await http.request_completed
	
	if response[1] == 200:
		var public_url = "https://" + project_id + ".supabase.co/storage/v1/object/public/wardrobe/" + file_name
		print("✅ [SUPABASE] Yüklendi! URL: ", public_url)
	else:
		print("❌ [SUPABASE] Hata Kodu: ", response[1])
		# Hata 400 ise URL yapısını, 403 ise RLS politikalarını kontrol et
# --- 🛠️ DİĞER FONKSİYONLARIN ---

func refresh_wardrobe_ui():
	var full_wardrobe = Globals.cache.get("wardrobe", [])
	for cat in current_indices.keys():
		filtered_cache[cat] = full_wardrobe.filter(func(i): return i.category == cat)
		update_slot_visual(cat)

func update_slot_visual(category: String):
	var vbox_path = "HBoxContainer/VBoxContainer/"
	if category == "outer" or category == "dress":
		vbox_path = "HBoxContainer/VBoxContainer2/"
	
	var full_path = vbox_path + "Slot" + category.capitalize() + "/HBoxContainer/TextureRect"
	var texture_rect = get_node_or_null(full_path)
	
	if texture_rect:
		var items = filtered_cache.get(category, [])
		if items.size() > 0:
			# Resim yükleme görselleştirme buraya gelecek
			pass
		else:
			texture_rect.texture = null

func _on_slot_gui_input(event, category: String):
	if event is InputEventMouseButton and event.pressed:
		print("🖱️ [WARDROBE] SLOT'A TIKLANDI: ", category)
		if popup.has_method("open_category"):
			popup.call("open_category", category)

func _on_close_button_pressed():
	get_tree().paused = false
	if UI.has_node("UIRoot"):
		UI.get_node("UIRoot").show_full_ui()
	queue_free()
