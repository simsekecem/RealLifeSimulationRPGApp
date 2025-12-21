extends Control

# 🔵 PROJECT SETTINGS
const PROJECT_ID = "rzsndtstonztfuayodmg"
const SUPABASE_URL = "https://" + PROJECT_ID + ".supabase.co/storage/v1/object/wardrobe/"
const PUBLIC_URL_BASE = "https://" + PROJECT_ID + ".supabase.co/storage/v1/object/public/wardrobe/"

# 👇 Endpointler
const WORKER_URL = "https://life-sim-worker.life-simulation.workers.dev/api/classify_clothing_vit"
const WORKER_URL_DELETE = "https://life-sim-worker.life-simulation.workers.dev/api/delete_item"
const WORKER_URL_OUTFIT = "https://life-sim-worker.life-simulation.workers.dev/api/generate_outfit"

# 🔵 POPUP SCENES
var popup_scene := preload("res://scenes/WardrobeItemListPopup.tscn")
var outfit_popup_scene := preload("res://scenes/OutfitResultPopup.tscn")
var popup: Node

# Mevcut indeksler
var current_indices = { "outer": 0, "dress": 0, "upper": 0, "lower": 0, "shoes": 0 }

# Placeholder
var placeholder_texture: Texture2D = null

# --- 🔥 ARKA PLAN YÜKLEME SIRASI (QUEUE) ---
var download_queue: Array = [] 
var is_downloading: bool = false 

# Request Referansları
var current_classify_request: HTTPRequest = null
var current_upload_request: HTTPRequest = null

# ------------------------------------------------------------
# READY & BAŞLANGIÇ
# ------------------------------------------------------------
func _ready():
	print("🚀 [WARDROBE] Başlatıldı...")

	# Placeholder oluştur
	var ph_img = Image.create(200, 200, false, Image.FORMAT_RGBA8)
	ph_img.fill(Color(0, 0, 0, 0)) # R:0, G:0, B:0, Alpha:0 (Görünmez)
	placeholder_texture = ImageTexture.create_from_image(ph_img)

	# Popup Kurulumları
	popup = popup_scene.instantiate()
	add_child(popup)
	popup.hide()
	
	if popup.has_signal("item_chosen"): popup.item_chosen.connect(_on_popup_item_chosen)
	if popup.has_signal("item_deleted"): popup.item_deleted.connect(_on_popup_item_deleted)
	if popup.has_signal("item_edited"): popup.item_edited.connect(_on_popup_item_edited)

	# Buton Bağlantıları
	if has_node("CloseButton"): $CloseButton.pressed.connect(_on_close_button_pressed)
	if has_node("AddClothesButton"): $AddClothesButton.pressed.connect(_on_add_clothes_button_pressed)
	if has_node("MagicButton"): $MagicButton.pressed.connect(_on_magic_button_pressed)

	connect_category_buttons()

	# 🔥 1. Sahne değişimlerini dinle
	get_tree().node_added.connect(_on_scene_changed)

	# 🔥 2. Debug (Direkt evde başlarsa)
	if get_tree().current_scene and get_tree().current_scene.scene_file_path == "res://scenes/house.tscn":
		print("🏠 Oyun direkt Ev'de başladı! İndirme başlatılıyor...")
		_start_background_loading_v2()

	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("refresh_wardrobe_ui")
	Globals.data_updated.connect(refresh_wardrobe_ui)

# ------------------------------------------------------------
# 🔥 SAHNE KONTROLÜ
# ------------------------------------------------------------
func _on_scene_changed(node: Node):
	if node.scene_file_path.is_empty():
		return
	if node.scene_file_path == "res://scenes/house.tscn":
		print("🏠 Ev sahresine girildi! Dolap resimleri arka planda indiriliyor...")
		_start_background_loading_v2()

# ------------------------------------------------------------
# 🔥 ARKA PLAN YÜKLEME SİSTEMİ (V2)
# ------------------------------------------------------------
func _start_background_loading_v2():
	var wardrobe = Globals.cache.get("wardrobe", [])
	for item in wardrobe:
		var url = item.get("image_url", "")
		if url != "" and not Globals.texture_cache.has(url):
			if not download_queue.has(url):
				download_queue.append(url)
	
	if not download_queue.is_empty() and not is_downloading:
		_process_next_download_v2()

func _process_next_download_v2():
	if download_queue.is_empty():
		is_downloading = false
		return
		
	is_downloading = true
	var url = download_queue.pop_front()
	
	if Globals.texture_cache.has(url):
		_process_next_download_v2()
		return
	
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, code, headers, body): 
		_on_single_image_downloaded(url, code, body, http)
	)
	http.request(url)

func _on_single_image_downloaded(url, code, body, http_node):
	http_node.queue_free()
	
	if code == 200:
		var img = Image.new()
		var err = img.load_jpg_from_buffer(body)
		if err != OK: err = img.load_png_from_buffer(body)
		
		if err == OK:
			var tex = ImageTexture.create_from_image(img)
			Globals.texture_cache[url] = tex 
			refresh_wardrobe_ui()
	
	get_tree().create_timer(0.05).timeout.connect(_process_next_download_v2)

# ------------------------------------------------------------
# GÖRÜNTÜLEME VE NAVİGASYON (Label ve Renkler SİLİNDİ)
# ------------------------------------------------------------
func update_category_display(category: String):
	var items = get_items_in_category(category)
	var index = current_indices.get(category, 0)
	var slot_path = get_slot_path(category)
	if not has_node(slot_path): return

	# ❌ Label node'unu aramayı sildik. Sadece Texture ve Butonlar var.
	var texture_rect = get_node(slot_path + "/HBoxContainer/TextureRect")
	var back_button = get_node(slot_path + "/HBoxContainer/Back")
	var next_button = get_node(slot_path + "/HBoxContainer/Next")

	if items.is_empty():
		texture_rect.texture = placeholder_texture
		back_button.disabled = true; next_button.disabled = true
		return

	index = clamp(index, 0, items.size() - 1)
	current_indices[category] = index

	var current_item = items[index]
	var image_url = current_item["image_url"]

	# 🔥 GLOBAL CACHE KONTROLÜ
	if Globals.texture_cache.has(image_url):
		texture_rect.texture = Globals.texture_cache[image_url]
	else:
		texture_rect.texture = placeholder_texture
		if not download_queue.has(image_url):
			download_queue.push_front(image_url) 
			if not is_downloading: _process_next_download_v2()

	# ❌ Buradaki Label text atama ve renk değiştirme kodlarının hepsi silindi.

	back_button.disabled = (index == 0)
	next_button.disabled = (index == items.size() - 1)

# ------------------------------------------------------------
# STANDART HELPERLAR
# ------------------------------------------------------------
func get_slot_path(category: String) -> String:
	var slot_name = "Slot" + category.capitalize()
	if category in ["outer", "dress"]: return "HBoxContainer/VBoxContainer2/" + slot_name
	else: return "HBoxContainer/VBoxContainer/" + slot_name

func get_items_in_category(category: String) -> Array:
	if not Globals.cache.has("wardrobe"): return []
	var filtered := []
	for item in Globals.cache["wardrobe"]:
		if item.get("category", "") == category and item.get("image_url", "") != "":
			filtered.append(item)
	# Confidence sıralaması kalabilir (arka planda çalışır, UI'a etkisi yok)
	filtered.sort_custom(func(a, b): return a.get("confidence", 1.0) > b.get("confidence", 1.0))
	return filtered

func connect_category_buttons():
	for category in ["outer", "dress", "upper", "lower", "shoes"]:
		var slot_path = get_slot_path(category)
		if not has_node(slot_path): continue
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

func _on_back_pressed(category: String):
	if current_indices[category] > 0:
		current_indices[category] -= 1
		update_category_display(category)

func _on_next_pressed(category: String):
	var items = get_items_in_category(category)
	if current_indices[category] < items.size() - 1:
		current_indices[category] += 1
		update_category_display(category)

func _on_slot_gui_input(event: InputEvent, category: String):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if popup and popup.has_method("open_category"):
			popup.open_category(category)
			popup.show()

# ------------------------------------------------------------
# POPUP OLAYLARI
# ------------------------------------------------------------
func _on_popup_item_chosen(item_data):
	var cat = item_data.get("category", "")
	var items = get_items_in_category(cat)
	var found_idx = 0
	for i in range(items.size()):
		if items[i].get("image_url") == item_data.get("image_url"):
			found_idx = i; break
	current_indices[cat] = found_idx
	update_category_display(cat)

func _on_popup_item_deleted(item_data):
	var list = Globals.cache.get("wardrobe", [])
	list.erase(item_data)
	Globals.cache["wardrobe"] = list
	Globals.save_cache()
	delete_from_server(item_data)
	refresh_wardrobe_ui()

func _on_popup_item_edited(old_data, new_data):
	var list = Globals.cache.get("wardrobe", [])
	var index = -1
	for i in range(list.size()):
		if list[i].get("image_url") == old_data.get("image_url"):
			index = i; break
	if index != -1:
		list[index] = new_data
		Globals.cache["wardrobe"] = list
		Globals.save_cache() 
		refresh_wardrobe_ui()
		var old_cat = old_data.get("category", ""); var new_cat = new_data.get("category", "")
		if old_cat != new_cat:
			update_category_display(old_cat); update_category_display(new_cat)

func delete_from_server(item_data):
	var http = HTTPRequest.new(); add_child(http)
	http.request_completed.connect(func(r, c, h, b): http.queue_free())
	var body = JSON.stringify({ "image_url": item_data.get("image_url", "") })
	if Globals.auth_token == "": return
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + Globals.auth_token]
	http.request(WORKER_URL_DELETE, headers, HTTPClient.METHOD_POST, body)

func refresh_wardrobe_ui():
	for category in ["outer", "dress", "upper", "lower", "shoes"]:
		update_category_display(category)

# ------------------------------------------------------------
# OUTFIT GENERATION
# ------------------------------------------------------------
func _on_magic_button_pressed():
	var wardrobe = Globals.cache.get("wardrobe", [])
	if wardrobe.size() < 2: OS.alert("You need at least 2 items!"); return
	show_loading_ui()
	var http = HTTPRequest.new(); add_child(http)
	http.request_completed.connect(_on_outfit_generated.bind(http))
	var body = JSON.stringify({ "wardrobe": wardrobe, "context": "daily casual style" })
	var headers = ["Content-Type: application/json"]
	if Globals.auth_token != "": headers.append("Authorization: Bearer " + Globals.auth_token)
	http.request(WORKER_URL_OUTFIT, headers, HTTPClient.METHOD_POST, body)

func _on_outfit_generated(_result, code, _headers, body, http_request):
	hide_loading_ui(); http_request.queue_free() 
	if code != 200: OS.alert("Failed to generate outfit."); return
	var json = JSON.parse_string(body.get_string_from_utf8())
	if json == null: return
	var selected_ids = json.get("selected_ids", [])
	var explanation = json.get("explanation", "Here is your outfit!")
	var final_items = []
	var wardrobe = Globals.cache.get("wardrobe", [])
	for id in selected_ids:
		for item in wardrobe:
			if str(item.get("id")) == str(id): final_items.append(item); break
	if final_items.is_empty(): OS.alert("Items not found."); return
	var popup_instance = outfit_popup_scene.instantiate()
	add_child(popup_instance)
	popup_instance.show_outfit(final_items, explanation)

# ------------------------------------------------------------
# LOADING UI & UPLOAD
# ------------------------------------------------------------
var loading_overlay: ColorRect = null
func show_loading_ui():
	loading_overlay = ColorRect.new()
	loading_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_overlay.color = Color(0, 0, 0, 0.7); loading_overlay.z_index = 100
	var lbl = Label.new()
	lbl.text = "Please wait...\nCreating your outfit ✨"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.add_theme_font_size_override("font_size", 32)
	loading_overlay.add_child(lbl)
	add_child(loading_overlay)

func hide_loading_ui():
	if loading_overlay != null: loading_overlay.queue_free(); loading_overlay = null

func _on_close_button_pressed():
	get_tree().paused = false
	if UI.has_node("UIRoot"): UI.get_node("UIRoot").show_full_ui()
	queue_free()

# ------------------------------------------------------------
# ANDROID & RESİM YÜKLEME
# ------------------------------------------------------------
func _on_add_clothes_button_pressed():
	if OS.get_name() == "Android":
		var perms = OS.get_granted_permissions()
		if not perms.has("android.permission.READ_MEDIA_IMAGES") and not perms.has("android.permission.READ_EXTERNAL_STORAGE"):
			OS.request_permissions(); return
	DisplayServer.file_dialog_show("Kıyafet Seç", "", "", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, ["*.jpg", "*.jpeg", "*.png"], _on_file_selected)

func _on_file_selected(status: bool, paths: PackedStringArray, _idx: int):
	if not status or paths.is_empty(): return
	var img := Image.new()
	if img.load(paths[0]) != OK: OS.alert("Resim yüklenemedi."); return
	if img.get_width() > 600:
		var scale = 600.0 / img.get_width()
		img.resize(int(600), int(img.get_height() * scale), Image.INTERPOLATE_LANCZOS)
	var buffer = img.save_jpg_to_buffer(0.75)
	var base64_str = "data:image/jpeg;base64," + Marshalls.raw_to_base64(buffer)
	
	current_classify_request = HTTPRequest.new(); add_child(current_classify_request)
	current_classify_request.request_completed.connect(_on_classification_complete.bind(img, buffer))
	current_classify_request.request(WORKER_URL, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify({ "image": base64_str }))

func _on_classification_complete(_r, code, _h, body, original_img: Image, image_buffer: PackedByteArray):
	if current_classify_request: current_classify_request.queue_free()
	if code != 200: OS.alert("AI Error."); return
	var json = JSON.parse_string(body.get_string_from_utf8())
	if not json.get("is_valid", false): OS.alert("Not a clothing item."); return
	
	var item_data = {
		"category": json.get("category", "upper"),
		"item_name": json.get("item_name", "Item"),
		"confidence": json.get("confidence", 1.0),
		"is_favorite": false
	}
	upload_to_supabase(image_buffer, item_data)

func upload_to_supabase(image_buffer: PackedByteArray, item_data: Dictionary):
	current_upload_request = HTTPRequest.new(); add_child(current_upload_request)
	current_upload_request.request_completed.connect(_on_upload_completed.bind(item_data))
	var file_name = "item_" + str(Time.get_unix_time_from_system()) + ".jpg"
	var headers = ["Authorization: Bearer " + Globals.supabase_anon_key, "Content-Type: image/jpeg"]
	current_upload_request.request_raw(SUPABASE_URL + file_name, headers, HTTPClient.METHOD_POST, image_buffer)

func _on_upload_completed(_r, code, _h, body, item_data):
	if current_upload_request: current_upload_request.queue_free()
	if code != 200 and code != 201: OS.alert("Upload Failed."); return
	var json = JSON.parse_string(body.get_string_from_utf8())
	var key = json.get("Key", "")
	item_data["image_url"] = PUBLIC_URL_BASE + key.replace("wardrobe/", "")
	
	if not Globals.cache.has("wardrobe"): Globals.cache["wardrobe"] = []
	Globals.cache["wardrobe"].append(item_data)
	Globals.mark_dirty(); Globals.save_cache()
	refresh_wardrobe_ui()
