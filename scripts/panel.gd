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
	print("\n📂 LOAD CATEGORY BAŞLADI: ", cat_name)
	active_category = cat_name
	
	for child in vbox.get_children():
		child.queue_free()
	
	var all_items = Globals.cache.get("market_items", [])
	
	# Veri Düzeltme
	if typeof(all_items) == TYPE_DICTIONARY:
		if all_items.has("results") and typeof(all_items["results"]) == TYPE_ARRAY:
			all_items = all_items["results"]
		else:
			all_items = all_items.values()
		Globals.cache["market_items"] = all_items
	
	if typeof(all_items) != TYPE_ARRAY: all_items = []
	
	for item in all_items:
		if typeof(item) != TYPE_DICTIONARY: continue
		
		# İsim kontrolü
		var i_name = str(item.get("item_name", "")).strip_edges()
		var i_id = item.get("id", "YOK")
		
		# LOG EKLEYELİM
		if i_name == "":
			print("🙈 LOAD: İsmi boş olan kayıt atlandı. ID: ", i_id)
			continue

		if item.get("category") == cat_name:
			# print("👁️ LOAD: Ekrana ekleniyor -> ", i_name, " | ID: ", i_id)
			add_item(false, item)
	
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
	print("\n💾 --- SAVE İŞLEMİ BAŞLIYOR: ", active_category, " ---")
	
	var new_list = []
	var all_items = Globals.cache.get("market_items", [])
	if typeof(all_items) != TYPE_ARRAY: all_items = []
	
	# 1. DİĞER KATEGORİLERİ KORU
	print("1️⃣ Diğer kategoriler korunuyor...")
	for item in all_items:
		if typeof(item) != TYPE_DICTIONARY: continue
		if item.get("category") != active_category:
			new_list.append(item)
	
	# 2. EKRANDAKİLERİ İŞLE
	print("2️⃣ Ekran taranıyor (VBox Child Sayısı: ", vbox.get_child_count(), ")")
	
	for child in vbox.get_children():
		if child.has_method("get_data"):
			var data = child.get_data() # Row'un logu burada çalışacak
			
			var name = str(data.get("item_name", "")).strip_edges()
			var has_id = data.has("id")
			var id_val = data.get("id", "YOK")
			
			print("   👉 İncelenen: '", name, "' | ID Var mı?: ", has_id, " (", id_val, ")")
			
			# SENARYO 1: İsim Boş AMA ID Var -> KAYDET (DB'yi boşaltmak için)
			if name == "" and has_id:
				print("      ✅ SENARYO 1: Eski kayıt silinmek üzere BOŞ olarak kaydediliyor.")
				data["category"] = active_category
				new_list.append(data)
				
			# SENARYO 2: İsim Boş VE ID Yok -> ATLA (Yeni açılmış boş satır)
			elif name == "" and not has_id:
				print("      ❌ SENARYO 2: Yeni boş satır, kaydedilmiyor.")
				continue
				
			# SENARYO 3: Normal Veri -> KAYDET
			else:
				# print("      ✅ SENARYO 3: Normal veri kaydedildi.")
				data["category"] = active_category
				new_list.append(data)
	
	# 3. KAYDET
	Globals.cache["market_items"] = new_list
	Globals.mark_dirty()
	Globals.save_cache()
	print("🏁 SAVE BİTTİ. Yeni Liste Boyutu: ", new_list.size())
	print("------------------------------------------\n")
