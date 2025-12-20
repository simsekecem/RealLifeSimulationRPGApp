extends Panel

const ROW_SCENE := preload("res://scenes/prefabs/item.tscn")

@onready var scroll: ScrollContainer = $ItemsScroll
@onready var vbox: VBoxContainer = $ItemsScroll/ItemsVBox

var active_category: String = ""

func _ready():
	pass 

# ------------------------------------------------------------
# LOAD (YÜKLEME)
# ------------------------------------------------------------
func load_category(cat_name: String):
	active_category = cat_name
	
	# 1. UI TEMİZLİĞİ: queue_free gecikmeli siler, remove_child anında temizler.
	for child in vbox.get_children():
		vbox.remove_child(child)
		child.queue_free()
	
	var all_items = Globals.cache.get("market_items", [])
	
	# 2. VERİ DÜZELTME (Sessizce yap, sinyal döngüsüne girmesin)
	if typeof(all_items) == TYPE_DICTIONARY:
		all_items = all_items.values() if not all_items.has("results") else all_items["results"]
		Globals.cache["market_items"] = all_items
		Globals.save_cache() # Sessiz kayıt
	
	if typeof(all_items) != TYPE_ARRAY: all_items = []
	
	# 3. PARMAK İZİ KONTROLÜ (Çift görünmeyi engelleyen kısım) ✨
	var seen_fingerprints = []
	
	for item in all_items:
		if typeof(item) != TYPE_DICTIONARY: continue
		
		var i_name = str(item.get("item_name", "")).strip_edges()
		var i_cat = str(item.get("category", ""))
		var i_date = str(item.get("date", ""))
		
		# İsim boşsa atla (Save fonksiyonun silme işlemini yapacak zaten)
		if i_name == "": continue

		# Sadece seçili kategorideysen işlem yap
		if i_cat == cat_name:
			# Parmak İzi: Aynı isim, aynı kategori ve aynı tarihli ürünü bir kez göster
			var fingerprint = i_name.to_lower() + "|" + i_cat + "|" + i_date
			
			if fingerprint in seen_fingerprints:
				continue # Bu zaten eklendi, atla!
			
			seen_fingerprints.append(fingerprint)
			add_item(false, item)
	
	# 4. En sona boş bir satır ekle (Yeni giriş için)
	add_item(false)

# ------------------------------------------------------------
# ADD ITEM
# ------------------------------------------------------------
func add_item(focus: bool = true, data: Dictionary = {}) -> Node:
	var row = ROW_SCENE.instantiate()
	row.connect("request_new_item", Callable(self, "_on_row_request_new_item"))
	vbox.add_child(row)
	
	if not data.is_empty():
		if row.has_method("set_data"):
			row.set_data(data)
	else:
		if "current_category" in row:
			row.current_category = active_category

	_call_scroll_bottom()
	if focus: _focus_lineedit(row.get_node("ItemEdit"))
	return row

func _on_row_request_new_item():
	add_item(true)
func _call_scroll_bottom(): await get_tree().process_frame; scroll.scroll_vertical = 99999
func _focus_lineedit(le): await get_tree().process_frame; if is_instance_valid(le): le.grab_focus()

# ------------------------------------------------------------
# SAVE (KAYDETME) - LOGLU VERSİYON 📝
# ------------------------------------------------------------
func save_items_to_cache():
	if active_category == "": return
	
	var new_list = []
	var all_items = Globals.cache.get("market_items", [])
	if typeof(all_items) != TYPE_ARRAY: all_items = []
	
	# 1. DİĞER KATEGORİLERİ KORU
	for item in all_items:
		if typeof(item) != TYPE_DICTIONARY: continue
		if item.get("category") != active_category:
			new_list.append(item)
	
	# 2. EKRANDAKİLERİ İŞLE
	# Kaydederken de çiftleşmeyi önlemek için local kontrol
	var saved_names = []
	
	for child in vbox.get_children():
		if child.has_method("get_data"):
			var data = child.get_data()
			var name = str(data.get("item_name", "")).strip_edges()
			
			# Çift girişi engelle (Boş değilse)
			if name != "":
				if name.to_lower() in saved_names: continue
				saved_names.append(name.to_lower())

			# Mantıksal Filtreleme
			if name == "" and not data.has("id"):
				continue # Yeni boş satır, kaydetme
			
			data["category"] = active_category
			new_list.append(data)
	
	# 3. KAYDET
	Globals.cache["market_items"] = new_list
	Globals.mark_dirty()
	Globals.save_cache()
	# 3. KAYDET
	Globals.cache["market_items"] = new_list
	Globals.mark_dirty()
	Globals.save_cache()
	print("🏁 SAVE BİTTİ. Yeni Liste Boyutu: ", new_list.size())
	print("------------------------------------------\n")
