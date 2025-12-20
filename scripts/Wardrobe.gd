extends Control

# 🔵 PROJECT SETTINGS
const PROJECT_ID = "rzsndtstonztfuayodmg"
const SUPABASE_URL = "https://" + PROJECT_ID + ".supabase.co/storage/v1/object/wardrobe/"
const PUBLIC_URL_BASE = "https://" + PROJECT_ID + ".supabase.co/storage/v1/object/public/wardrobe/"

# 👇 Worker URL
const WORKER_URL = "https://life-sim-worker.life-simulation.workers.dev/api/classify_clothing"

# 🔵 POPUP SCENE
var popup_scene := preload("res://scenes/WardrobeItemListPopup.tscn")
var popup: Node

# Mevcut indeksler
var current_indices = {
	"outer": 0,
	"dress": 0,
	"upper": 0,
	"lower": 0,
	"shoes": 0
}

# Kategori isimleri
var category_en_map = {
	"outer": "Outerwear",
	"upper": "Top",
	"lower": "Bottoms",
	"shoes": "Shoes",
	"dress": "Dress"
}

# HTTPRequest referansları
var current_classify_request: HTTPRequest = null
var current_upload_request: HTTPRequest = null

# Texture cache
var texture_cache: Dictionary = {}
var placeholder_texture: Texture2D = null


# ------------------------------------------------------------
# SLOT PATH RESOLVER (TEK MERKEZ)
# ------------------------------------------------------------
func get_slot_path(category: String) -> String:
	var slot_name = "Slot" + category.capitalize()

	if category in ["outer", "dress"]:
		return "HBoxContainer/VBoxContainer2/" + slot_name
	else:
		return "HBoxContainer/VBoxContainer/" + slot_name


# ------------------------------------------------------------
# READY
# ------------------------------------------------------------
func _ready():
	print("🚀 [WARDROBE] Starting...")

	# Placeholder
	var ph_img = Image.create(200, 200, false, Image.FORMAT_RGB8)
	ph_img.fill(Color(0.4, 0.4, 0.4))
	placeholder_texture = ImageTexture.create_from_image(ph_img)

	if UI.has_node("UIRoot"):
		UI.get_node("UIRoot").show_only_top_right_buttons()

	popup = popup_scene.instantiate()
	add_child(popup)
	popup.hide()

	if has_node("CloseButton"):
		$CloseButton.pressed.connect(_on_close_button_pressed)

	if has_node("AddClothesButton"):
		$AddClothesButton.pressed.connect(_on_add_clothes_button_pressed)

	connect_category_buttons()

	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("refresh_wardrobe_ui")

	Globals.data_updated.connect(refresh_wardrobe_ui)


# ------------------------------------------------------------
# BACK / NEXT BUTTON CONNECT
# ------------------------------------------------------------
func connect_category_buttons():
	for category in ["outer", "dress", "upper", "lower", "shoes"]:
		var slot_path = get_slot_path(category)

		if not has_node(slot_path):
			print("⚠️ Slot bulunamadı: ", slot_path)
			continue

		var back_path = slot_path + "/HBoxContainer/Back"
		var next_path = slot_path + "/HBoxContainer/Next"

		if has_node(back_path):
			get_node(back_path).pressed.connect(_on_back_pressed.bind(category))
		else:
			print("❌ Back yok: ", back_path)

		if has_node(next_path):
			get_node(next_path).pressed.connect(_on_next_pressed.bind(category))
		else:
			print("❌ Next yok: ", next_path)


# ------------------------------------------------------------
# BACK / NEXT ACTIONS
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
# DATA FILTER
# ------------------------------------------------------------
func get_items_in_category(category: String) -> Array:
	if not Globals.cache.has("wardrobe"):
		return []

	var filtered := []
	for item in Globals.cache["wardrobe"]:
		if item.get("category", "") == category and item.get("image_url", "") != "":
			filtered.append(item)

	return filtered


# ------------------------------------------------------------
# SINGLE CATEGORY UPDATE
# ------------------------------------------------------------
func update_category_display(category: String):
	var items = get_items_in_category(category)
	var index = current_indices.get(category, 0)

	var slot_path = get_slot_path(category)
	if not has_node(slot_path):
		print("❌ Slot node yok: ", slot_path)
		return

	var texture_rect = get_node(slot_path + "/HBoxContainer/TextureRect")
	var back_button = get_node(slot_path + "/HBoxContainer/Back")
	var next_button = get_node(slot_path + "/HBoxContainer/Next")

	if items.is_empty():
		texture_rect.texture = placeholder_texture
		back_button.disabled = true
		next_button.disabled = true
		return

	index = clamp(index, 0, items.size() - 1)
	current_indices[category] = index

	var current_item = items[index]
	var image_url = current_item["image_url"]

	# CACHE
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

	back_button.disabled = (index == 0)
	next_button.disabled = (index == items.size() - 1)


# ------------------------------------------------------------
# REFRESH ALL
# ------------------------------------------------------------
func refresh_wardrobe_ui():
	for category in ["outer", "dress", "upper", "lower", "shoes"]:
		update_category_display(category)


# ------------------------------------------------------------
# ANDROID & IMAGE PICK
# ------------------------------------------------------------
func _ensure_android_gallery_permission() -> bool:
	if OS.get_name() != "Android":
		return true

	var perms = OS.get_granted_permissions()
	if perms.has("android.permission.READ_MEDIA_IMAGES") \
	or perms.has("android.permission.READ_EXTERNAL_STORAGE"):
		return true

	OS.request_permissions()
	return false


func _on_add_clothes_button_pressed():
	if not _ensure_android_gallery_permission():
		return

	DisplayServer.file_dialog_show(
		"Kıyafet Seç",
		"",
		"",
		false,
		DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,
		["*.jpg", "*.jpeg", "*.png"],
		_on_file_selected
	)


func _on_file_selected(status: bool, paths: PackedStringArray, _idx: int):
	if not status or paths.is_empty():
		return

	var img := Image.new()
	if img.load(paths[0]) != OK:
		return

	if img.get_width() > 400:
		var s = 400.0 / img.get_width()
		img.resize(400, int(img.get_height() * s), Image.INTERPOLATE_LANCZOS)

	ask_gemini_classification(img.save_jpg_to_buffer(0.7))


# ------------------------------------------------------------
# GEMINI
# ------------------------------------------------------------
func ask_gemini_classification(image_buffer: PackedByteArray):
	var body = JSON.stringify({
		"image": "data:image/jpeg;base64," + Marshalls.raw_to_base64(image_buffer)
	})

	current_classify_request = HTTPRequest.new()
	add_child(current_classify_request)
	current_classify_request.request_completed.connect(
		_on_gemini_response_received.bind(image_buffer)
	)

	current_classify_request.request(
		WORKER_URL,
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		body
	)


func _on_gemini_response_received(_r, code, _h, body, image_buffer):
	if current_classify_request:
		current_classify_request.queue_free()
		current_classify_request = null

	if code != 200:
		return

	var json = JSON.parse_string(body.get_string_from_utf8())
	if not json.get("is_valid", false):
		return

	var category = json.get("category", "upper")
	var color = json.get("color", "Unknown")
	var name = color + " " + category_en_map.get(category, "Clothing")

	upload_to_supabase(image_buffer, {
		"category": category,
		"item_name": name,
		"color": color,
		"is_favorite": false
	})


# ------------------------------------------------------------
# SUPABASE UPLOAD
# ------------------------------------------------------------
func upload_to_supabase(image_buffer: PackedByteArray, item_data: Dictionary):
	current_upload_request = HTTPRequest.new()
	add_child(current_upload_request)
	current_upload_request.request_completed.connect(
		_on_upload_completed.bind(item_data)
	)

	var file_name = "item_" + str(Time.get_unix_time_from_system()) + ".jpg"
	var headers = [
		"Authorization: Bearer " + Globals.supabase_anon_key,
		"Content-Type: image/jpeg"
	]

	current_upload_request.request_raw(
		SUPABASE_URL + file_name,
		headers,
		HTTPClient.METHOD_POST,
		image_buffer
	)


func _on_upload_completed(_r, code, _h, body, item_data):
	if current_upload_request:
		current_upload_request.queue_free()
		current_upload_request = null

	if code != 200 and code != 201:
		return

	var json = JSON.parse_string(body.get_string_from_utf8())
	var key = json.get("Key", "")
	if key.is_empty():
		return

	item_data["image_url"] = PUBLIC_URL_BASE + key.replace("wardrobe/", "")
	Globals.cache["wardrobe"].append(item_data)
	Globals.mark_dirty()
	refresh_wardrobe_ui()


# ------------------------------------------------------------
# CLOSE
# ------------------------------------------------------------
func _on_close_button_pressed():
	get_tree().paused = false
	if UI.has_node("UIRoot"):
		UI.get_node("UIRoot").show_full_ui()
	queue_free()
