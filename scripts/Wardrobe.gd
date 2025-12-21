extends Control

# 🔵 PROJECT SETTINGS
const PROJECT_ID = "rzsndtstonztfuayodmg"
const SUPABASE_URL = "https://" + PROJECT_ID + ".supabase.co/storage/v1/object/wardrobe/"
const PUBLIC_URL_BASE = "https://" + PROJECT_ID + ".supabase.co/storage/v1/object/public/wardrobe/"

# 👇 Endpointler
const WORKER_URL = "https://life-sim-worker.life-simulation.workers.dev/api/classify_clothing_vit"
const WORKER_URL_DELETE = "https://life-sim-worker.life-simulation.workers.dev/api/delete_item"
# 🔥 YENİ: Kombin Endpoints'i
const WORKER_URL_OUTFIT = "https://life-sim-worker.life-simulation.workers.dev/api/generate_outfit"

# 🔵 POPUP SCENES
var popup_scene := preload("res://scenes/WardrobeItemListPopup.tscn")
# 🔥 YENİ: Kombin Sonuç Popup'ı
var outfit_popup_scene := preload("res://scenes/OutfitResultPopup.tscn")

var popup: Node

# Mevcut indeksler
var current_indices = {
	"outer": 0, "dress": 0, "upper": 0, "lower": 0, "shoes": 0
}

var category_en_map = {
	"outer": "Outerwear", "upper": "Top", "lower": "Bottoms", "shoes": "Shoes", "dress": "Dress"
}

# HTTPRequest referansları
var current_classify_request: HTTPRequest = null
var current_upload_request: HTTPRequest = null

# Texture cache
var texture_cache: Dictionary = {}
var placeholder_texture: Texture2D = null

# ------------------------------------------------------------
# ITEM → SLOT MAPPING
# ------------------------------------------------------------
const ITEM_TO_SLOT = {
	"Shirts": "upper", "Casual Shirts": "upper", "Formal Shirts": "upper", "Tshirts": "upper",
	"Blouses": "upper", "Sweaters": "upper", "Tops": "upper", "Kurtas": "upper", "Hoodies": "upper",
	"Sweatshirts": "upper", "Jeans": "lower", "Pants": "lower", "Track Pants": "lower",
	"Shorts": "lower", "Skirts": "lower", "Leggings": "lower", "Trousers": "lower",
	"Dresses": "dress", "Jackets": "outer", "Coats": "outer", "Blazers": "outer",
	"Waistcoat": "outer", "Shrugs": "outer", "Casual Shoes": "shoes", "Sports Shoes": "shoes",
	"Boots": "shoes", "Heels": "shoes", "Sandals": "shoes", "Flip Flops": "shoes", "Shoes": "shoes",
}

func get_slot_from_item(item_name: String) -> String:
	if ITEM_TO_SLOT.has(item_name): return ITEM_TO_SLOT[item_name]
	var lower = item_name.to_lower()
	if lower.contains("shirt") or lower.contains("blouse") or lower.contains("top") or lower.contains("hoodie") or lower.contains("sweatshirt"): return "upper"
	if lower.contains("pant") or lower.contains("jean") or lower.contains("short") or lower.contains("skirt") or lower.contains("legging"): return "lower"
	if lower.contains("dress"): return "dress"
	if lower.contains("jacket") or lower.contains("coat") or lower.contains("blazer"): return "outer"
	if lower.contains("shoe") or lower.contains("boot") or lower.contains("heel") or lower.contains("sandal"): return "shoes"
	return "upper"

# ------------------------------------------------------------
# RENK ALGILAMA
# ------------------------------------------------------------
func detect_dominant_color(img: Image) -> String:
	img.convert(Image.FORMAT_RGB8)
	var data = img.get_data()
	var r_total = 0; var g_total = 0; var b_total = 0; var pixel_count = 0
	var w = img.get_width(); var h = img.get_height()
	var start_x = int(w * 0.2); var end_x = int(w * 0.8)
	var start_y = int(h * 0.2); var end_y = int(h * 0.8)

	for y in range(start_y, end_y, 4):
		for x in range(start_x, end_x, 4):
			var idx = (y * w + x) * 3
			r_total += data[idx]; g_total += data[idx + 1]; b_total += data[idx + 2]
			pixel_count += 1

	if pixel_count == 0: return "Grey"
	var r_avg = r_total / pixel_count / 255.0
	var g_avg = g_total / pixel_count / 255.0
	var b_avg = b_total / pixel_count / 255.0

	if r_avg > 0.7 and g_avg > 0.7 and b_avg > 0.7: return "White"
	if r_avg < 0.3 and g_avg < 0.3 and b_avg < 0.3: return "Black"
	if r_avg > g_avg + 0.2 and r_avg > b_avg + 0.2: return "Red"
	if g_avg > r_avg + 0.2 and g_avg > b_avg + 0.2: return "Green"
	if b_avg > r_avg + 0.2 and b_avg > g_avg + 0.2: return "Blue"
	if r_avg > 0.6 and g_avg > 0.4 and b_avg < 0.4: return "Orange"
	if r_avg > 0.5 and g_avg > 0.4 and b_avg > 0.5: return "Pink"
	if r_avg > 0.5 and g_avg > 0.4 and b_avg < 0.3: return "Brown"
	if r_avg > 0.6 and g_avg > 0.5 and b_avg > 0.4: return "Beige"
	return "Grey"

# ------------------------------------------------------------
# SLOT PATH RESOLVER
# ------------------------------------------------------------
func get_slot_path(category: String) -> String:
	var slot_name = "Slot" + category.capitalize()
	if category in ["outer", "dress"]:
		return "HBoxContainer/VBoxContainer2/" + slot_name
	else:
		return "HBoxContainer/VBoxContainer/" + slot_name

# ------------------------------------------------------------
# READY & BAŞLANGIÇ
# ------------------------------------------------------------
func _ready():
	print("🚀 [WARDROBE] Starting...")

	var ph_img = Image.create(200, 200, false, Image.FORMAT_RGB8)
	ph_img.fill(Color(0.4, 0.4, 0.4))
	placeholder_texture = ImageTexture.create_from_image(ph_img)

	if UI.has_node("UIRoot"):
		UI.get_node("UIRoot").show_only_top_right_buttons()

	# Popup Kurulumu
	popup = popup_scene.instantiate()
	add_child(popup)
	popup.hide()
	
	if popup.has_signal("item_chosen"): popup.item_chosen.connect(_on_popup_item_chosen)
	if popup.has_signal("item_deleted"): popup.item_deleted.connect(_on_popup_item_deleted)
	if popup.has_signal("item_edited"): popup.item_edited.connect(_on_popup_item_edited)

	# Buton Bağlantıları
	if has_node("CloseButton"): $CloseButton.pressed.connect(_on_close_button_pressed)
	if has_node("AddClothesButton"): $AddClothesButton.pressed.connect(_on_add_clothes_button_pressed)

	# 🔥 YENİ: "Kombin Yap" Butonu Bağlantısı (Butonun adının 'MagicButton' olduğundan emin ol)
	if has_node("MagicButton"): 
		$MagicButton.pressed.connect(_on_magic_button_pressed)

	connect_category_buttons()

	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("refresh_wardrobe_ui")
	Globals.data_updated.connect(refresh_wardrobe_ui)

# ------------------------------------------------------------
# 🎩 SİHİRLİ BUTON (KOMBİN YAP) - YENİ FONKSİYONLAR
# ------------------------------------------------------------
func _on_magic_button_pressed():
	# 1. Dolabı al
	var wardrobe = Globals.cache.get("wardrobe", [])
	
	# 2. Yeterli eşya var mı?
	if wardrobe.size() < 2:
		OS.alert("You need at least 2 items in your wardrobe!")
		return
	
	# 🔥 YENİ: Yükleniyor ekranını aç
	show_loading_ui()
	print("🤖 Gemini'ye istek gönderiliyor...")
	
	# 3. HTTP İsteği Hazırla
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_outfit_generated.bind(http))
	
	var body = JSON.stringify({
		"wardrobe": wardrobe,
		"context": "daily casual style"
	})
	
	var headers = ["Content-Type: application/json"]
	if Globals.auth_token != "":
		headers.append("Authorization: Bearer " + Globals.auth_token)
		
	http.request(WORKER_URL_OUTFIT, headers, HTTPClient.METHOD_POST, body)

func _on_outfit_generated(_result, code, _headers, body, http_request):
	# 🔥 YENİ: Cevap geldi, yükleniyor ekranını kapat
	hide_loading_ui()
	
	http_request.queue_free() 
	
	if code != 200:
		print("❌ Kombin Hatası: ", code)
		OS.alert("Failed to generate outfit. Server error.")
		return
		
	var json = JSON.parse_string(body.get_string_from_utf8())
	if json == null:
		print("❌ JSON Parse Hatası")
		return
		
	var selected_ids = json.get("selected_ids", [])
	var explanation = json.get("explanation", "Here is your outfit!")
	
	var final_items = []
	var wardrobe = Globals.cache.get("wardrobe", [])
	
	for id in selected_ids:
		for item in wardrobe:
			if str(item.get("id")) == str(id):
				final_items.append(item)
				break
	
	if final_items.is_empty():
		OS.alert("Outfit generated but items not found in cache.\nPlease restart the game.")
		return

	# Popup'ı aç
	var popup_instance = outfit_popup_scene.instantiate()
	add_child(popup_instance)
	popup_instance.show_outfit(final_items, explanation)

# ------------------------------------------------------------
# BUTON VE TIKLAMA BAĞLANTILARI
# ------------------------------------------------------------
func connect_category_buttons():
	for category in ["outer", "dress", "upper", "lower", "shoes"]:
		var slot_path = get_slot_path(category)
		if not has_node(slot_path):
			continue

		var back_path = slot_path + "/HBoxContainer/Back"
		var next_path = slot_path + "/HBoxContainer/Next"
		var texture_path = slot_path + "/HBoxContainer/TextureRect"

		if has_node(back_path): get_node(back_path).pressed.connect(_on_back_pressed.bind(category))
		if has_node(next_path): get_node(next_path).pressed.connect(_on_next_pressed.bind(category))
			
		if has_node(texture_path):
			var tex_rect = get_node(texture_path)
			tex_rect.mouse_filter = Control.MOUSE_FILTER_STOP 
			if not tex_rect.gui_input.is_connected(_on_slot_gui_input):
				tex_rect.gui_input.connect(_on_slot_gui_input.bind(category))

# ------------------------------------------------------------
# 🖱️ SLOT TIKLAMA VE POPUP AÇMA
# ------------------------------------------------------------
func _on_slot_gui_input(event: InputEvent, category: String):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if popup and popup.has_method("open_category"):
			popup.open_category(category)
			popup.show()

# ✅ POPUP'TAN "SEÇ" GELDİ
func _on_popup_item_chosen(item_data):
	var cat = item_data.get("category", "")
	var items = get_items_in_category(cat)
	
	var found_idx = 0
	for i in range(items.size()):
		if items[i].get("image_url") == item_data.get("image_url"):
			found_idx = i
			break
	
	current_indices[cat] = found_idx
	update_category_display(cat)

# 🗑️ POPUP'TAN "SİL" GELDİ
func _on_popup_item_deleted(item_data):
	var list = Globals.cache.get("wardrobe", [])
	list.erase(item_data)
	Globals.cache["wardrobe"] = list
	Globals.save_cache()
	
	delete_from_server(item_data)
	refresh_wardrobe_ui()

# ✏️ POPUP'TAN "DÜZENLE" GELDİ
func _on_popup_item_edited(old_data, new_data):
	var list = Globals.cache.get("wardrobe", [])
	var index = -1
	for i in range(list.size()):
		if list[i].get("image_url") == old_data.get("image_url"):
			index = i
			break
	
	if index != -1:
		list[index] = new_data
		Globals.cache["wardrobe"] = list
		Globals.save_cache() 
		refresh_wardrobe_ui()
		
		var old_cat = old_data.get("category", "")
		var new_cat = new_data.get("category", "")
		if old_cat != new_cat:
			update_category_display(old_cat)
			update_category_display(new_cat)

# 🌐 SERVER SİLME İSTEĞİ
func delete_from_server(item_data):
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(r, c, h, b): http.queue_free())
	
	var body = JSON.stringify({ "image_url": item_data.get("image_url", "") })
	
	if Globals.auth_token == "": return
	
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + Globals.auth_token]
	http.request(WORKER_URL_DELETE, headers, HTTPClient.METHOD_POST, body)

# ------------------------------------------------------------
# NAVIGASYON
# ------------------------------------------------------------
func _on_back_pressed(category: String):
	if current_indices[category] > 0:
		current_indices[category] -= 1
		update_category_display(category)

func _on_next_pressed(category: String):
	var items = get_items_in_category(category)
	if current_indices[category] < items.size() - 1:
		current_indices[category] += 1
		update_category_display(category)

# ------------------------------------------------------------
# VERİ FİLTRELEME
# ------------------------------------------------------------
func get_items_in_category(category: String) -> Array:
	if not Globals.cache.has("wardrobe"): return []
	var filtered := []
	for item in Globals.cache["wardrobe"]:
		if item.get("category", "") == category and item.get("image_url", "") != "":
			filtered.append(item)
	filtered.sort_custom(func(a, b): return a.get("confidence", 1.0) > b.get("confidence", 1.0))
	return filtered

# ------------------------------------------------------------
# SLOT GÜNCELLEME
# ------------------------------------------------------------
func update_category_display(category: String):
	var items = get_items_in_category(category)
	var index = current_indices.get(category, 0)
	var slot_path = get_slot_path(category)
	if not has_node(slot_path): return

	var texture_rect = get_node(slot_path + "/HBoxContainer/TextureRect")
	var label = get_node(slot_path + "/HBoxContainer/Label") if has_node(slot_path + "/HBoxContainer/Label") else null
	var back_button = get_node(slot_path + "/HBoxContainer/Back")
	var next_button = get_node(slot_path + "/HBoxContainer/Next")

	if items.is_empty():
		texture_rect.texture = placeholder_texture
		if label: label.text = "Empty"
		back_button.disabled = true; next_button.disabled = true
		return

	index = clamp(index, 0, items.size() - 1)
	current_indices[category] = index

	var current_item = items[index]
	var image_url = current_item["image_url"]
	var item_name = current_item.get("item_name", "Item")
	var confidence = current_item.get("confidence", 1.0)

	if texture_cache.has(image_url):
		texture_rect.texture = texture_cache[image_url]
	else:
		texture_rect.texture = placeholder_texture
		var img := Image.new()
		var http := HTTPRequest.new()
		add_child(http)
		http.request_completed.connect(func(_r, code, _h, body):
			http.queue_free()
			if code == 200 and img.load_jpg_from_buffer(body) == OK:
				var tex = ImageTexture.create_from_image(img)
				texture_cache[image_url] = tex
				if current_indices[category] == index:
					texture_rect.texture = tex
		)
		http.request(image_url)

	if label:
		label.text = item_name
		if confidence < 0.7: label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		elif confidence < 0.9: label.add_theme_color_override("font_color", Color(1, 0.7, 0.2))
		else: label.add_theme_color_override("font_color", Color(1, 1, 1))

	back_button.disabled = (index == 0)
	next_button.disabled = (index == items.size() - 1)

func refresh_wardrobe_ui():
	for category in ["outer", "dress", "upper", "lower", "shoes"]:
		update_category_display(category)

# ------------------------------------------------------------
# ANDROID & RESİM SEÇME
# ------------------------------------------------------------
func _ensure_android_gallery_permission() -> bool:
	if OS.get_name() != "Android": return true
	var perms = OS.get_granted_permissions()
	if perms.has("android.permission.READ_MEDIA_IMAGES") or perms.has("android.permission.READ_EXTERNAL_STORAGE"): return true
	OS.request_permissions()
	return false

func _on_add_clothes_button_pressed():
	if not _ensure_android_gallery_permission(): return
	DisplayServer.file_dialog_show("Kıyafet Seç", "", "", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, ["*.jpg", "*.jpeg", "*.png"], _on_file_selected)

func _on_file_selected(status: bool, paths: PackedStringArray, _idx: int):
	if not status or paths.is_empty(): return
	var img := Image.new()
	if img.load(paths[0]) != OK:
		OS.alert("Resim yüklenemedi.")
		return
	if img.get_width() > 600:
		var scale = 600.0 / img.get_width()
		img.resize(int(600), int(img.get_height() * scale), Image.INTERPOLATE_LANCZOS)

	var buffer = img.save_jpg_to_buffer(0.75)
	var base64_str = "data:image/jpeg;base64," + Marshalls.raw_to_base64(buffer)

	current_classify_request = HTTPRequest.new()
	add_child(current_classify_request)
	current_classify_request.request_completed.connect(_on_classification_complete.bind(img, buffer))

	print("🤖 ViT modeline gönderiliyor...")
	current_classify_request.request(WORKER_URL, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify({ "image": base64_str }))

# ------------------------------------------------------------
# AI SONUÇ İŞLEME
# ------------------------------------------------------------
func _on_classification_complete(_r, code, _h, body, original_img: Image, image_buffer: PackedByteArray):
	if current_classify_request:
		current_classify_request.queue_free()
		current_classify_request = null

	if code == 503:
		var json = JSON.parse_string(body.get_string_from_utf8())
		OS.alert("Model yükleniyor: " + json.get("message", ""))
		return
	if code != 200:
		OS.alert("AI sunucusu yanıt vermedi. (Kod: " + str(code) + ")")
		return

	var json = JSON.parse_string(body.get_string_from_utf8())
	if json.has("error"):
		OS.alert("AI hatası: " + json.message)
		return
	if not json.get("is_valid", false):
		var reason = json.get("reason", "Kıyafet değil")
		OS.alert("Bu görsel kıyafet değil: " + reason)
		return

	var ai_item_name = json.get("item_name", "Item")
	var confidence = json.get("confidence", 1.0)
	var category = json.get("category", get_slot_from_item(ai_item_name))
	var color = detect_dominant_color(original_img)
	var final_item_name = color.capitalize() + " " + ai_item_name.capitalize()

	print("✅ AI onayladı: ", final_item_name)

	upload_to_supabase(image_buffer, {
		"category": category,
		"item_name": final_item_name,
		"color": color,
		"confidence": confidence,
		"is_favorite": false
	})

# ------------------------------------------------------------
# SUPABASE UPLOAD
# ------------------------------------------------------------
func upload_to_supabase(image_buffer: PackedByteArray, item_data: Dictionary):
	current_upload_request = HTTPRequest.new()
	add_child(current_upload_request)
	current_upload_request.request_completed.connect(_on_upload_completed.bind(item_data))

	var file_name = "item_" + str(Time.get_unix_time_from_system()) + ".jpg"
	var headers = ["Authorization: Bearer " + Globals.supabase_anon_key, "Content-Type: image/jpeg"]

	print("📤 Supabase'e yükleniyor...")
	current_upload_request.request_raw(SUPABASE_URL + file_name, headers, HTTPClient.METHOD_POST, image_buffer)

func _on_upload_completed(_r, code, _h, body, item_data):
	if current_upload_request:
		current_upload_request.queue_free()
		current_upload_request = null

	if code != 200 and code != 201:
		OS.alert("Yükleme başarısız. (Kod: " + str(code) + ")")
		return

	var json = JSON.parse_string(body.get_string_from_utf8())
	var key = json.get("Key", "")
	if key.is_empty():
		OS.alert("Dosya anahtarı alınamadı.")
		return

	item_data["image_url"] = PUBLIC_URL_BASE + key.replace("wardrobe/", "")

	if not Globals.cache.has("wardrobe"):
		Globals.cache["wardrobe"] = []
	Globals.cache["wardrobe"].append(item_data)

	Globals.mark_dirty()
	Globals.save_cache()
	refresh_wardrobe_ui()
	OS.alert("Eklendi: " + item_data["item_name"])

func _on_close_button_pressed():
	get_tree().paused = false
	if UI.has_node("UIRoot"): UI.get_node("UIRoot").show_full_ui()
	queue_free()
var loading_overlay: ColorRect = null

func show_loading_ui():
	# 1. Arka planı oluştur (Yarı saydam siyah)
	loading_overlay = ColorRect.new()
	loading_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_overlay.color = Color(0, 0, 0, 0.7) # %70 Siyahlık
	loading_overlay.z_index = 100 # En üstte görünsün
	
	# 2. Yazıyı oluştur
	var lbl = Label.new()
	lbl.text = "Please wait...\nCreating your outfit ✨" # İngilizce yazı
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# İstersen font rengini veya boyutunu buradan ayarlayabilirsin
	lbl.add_theme_color_override("font_color", Color.WHITE)
	
	# 3. Sahneye ekle
	loading_overlay.add_child(lbl)
	add_child(loading_overlay)

func hide_loading_ui():
	if loading_overlay != null:
		loading_overlay.queue_free()
		loading_overlay = null
