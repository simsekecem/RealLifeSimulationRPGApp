extends Control

# ------------------------------------------------------------
# TAB REFERANSLARI
# ------------------------------------------------------------
@onready var tab_container = $TabContainer

# DAILY
@onready var day_select = $TabContainer/Daily/HBoxContainer/DaySelect
@onready var month_select = $TabContainer/Daily/HBoxContainer/MonthSelect
@onready var year_select = $TabContainer/Daily/HBoxContainer/YearSelect
@onready var btn_today = $TabContainer/Daily/HBoxContainer/TodayButton
@onready var btn_tomorrow = $TabContainer/Daily/HBoxContainer/TomorrowButton
@onready var btn_add = $TabContainer/Daily/AddButton
@onready var btn_save = $TabContainer/Daily/SaveButton
@onready var daily_list_container = $TabContainer/Daily/ListArea/ScrollContainer/ContentList
@onready var back_button = $BackButton

# WEEKLY
@onready var weekly_rows = {
	1: $TabContainer/Weekly/VBoxContainer/MondayRow/ScrollContainer/ExercisesRow,
	2: $TabContainer/Weekly/VBoxContainer/TuesdayRow/ScrollContainer/ExercisesRow,
	3: $TabContainer/Weekly/VBoxContainer/WednesdayRow/ScrollContainer/ExercisesRow,
	4: $TabContainer/Weekly/VBoxContainer/ThursdayRow/ScrollContainer/ExercisesRow,
	5: $TabContainer/Weekly/VBoxContainer/FridayRow/ScrollContainer/ExercisesRow,
	6: $TabContainer/Weekly/VBoxContainer/SaturdayRow/ScrollContainer/ExercisesRow,
	7: $TabContainer/Weekly/VBoxContainer/SundayRow/ScrollContainer/ExercisesRow
}

@export var daily_row_scene: PackedScene
@export var weekly_row_scene: PackedScene

# ------------------------------------------------------------
# STATE
# ------------------------------------------------------------
var selected_date_dict: Dictionary = {}

# 👇 YENİ: Veritabanından silinecek olan ID'leri burada tutacağız
var pending_deletes = []

# ------------------------------------------------------------
# READY
# ------------------------------------------------------------
func _ready():
	UI.get_node("UIRoot").show_only_top_right_buttons()

	fill_years()
	fill_months()

	back_button.pressed.connect(func(): UI.get_node("UIRoot").return_to_town())
	btn_add.pressed.connect(add_empty_row)
	btn_save.pressed.connect(save_daily_data)
	btn_today.pressed.connect(go_to_today)
	btn_tomorrow.pressed.connect(go_to_tomorrow)

	day_select.item_selected.connect(func(_i): _on_date_changed())
	month_select.item_selected.connect(func(_i): _on_date_changed())
	year_select.item_selected.connect(func(_i): _on_date_changed())

	tab_container.tab_changed.connect(_on_tab_changed)
	
	# Veri güncellendi sinyali varsa dinle (Opsiyonel ama iyi olur)
	if Globals.has_signal("data_updated"):
		if not Globals.data_updated.is_connected(_on_global_data_updated):
			Globals.data_updated.connect(_on_global_data_updated)

	go_to_today()

# Veri güncellenirse ekranı yenile
func _on_global_data_updated():
	load_daily_list()
	if tab_container.current_tab == 1:
		refresh_weekly_view()

# ------------------------------------------------------------
# DATE LOGIC
# ------------------------------------------------------------
func go_to_today():
	selected_date_dict = Time.get_date_dict_from_system()
	update_ui_dropdowns()
	load_daily_list()

func go_to_tomorrow():
	var unix = Time.get_unix_time_from_datetime_dict(selected_date_dict) + 86400
	selected_date_dict = Time.get_date_dict_from_unix_time(unix)
	update_ui_dropdowns()
	load_daily_list()

func _on_date_changed():
	if day_select.item_count == 0:
		return

	selected_date_dict["day"] = int(day_select.get_item_text(day_select.selected))
	selected_date_dict["month"] = month_select.selected + 1
	selected_date_dict["year"] = int(year_select.get_item_text(year_select.selected))

	load_daily_list()

func update_ui_dropdowns():
	for i in range(year_select.item_count):
		if int(year_select.get_item_text(i)) == selected_date_dict.year:
			year_select.select(i)
			break

	month_select.select(selected_date_dict.month - 1)
	update_days_in_dropdown()

	var idx = selected_date_dict.day - 1
	if idx >= 0 and idx < day_select.item_count:
		day_select.select(idx)

func get_date_str(d: Dictionary) -> String:
	if not d.has("year") or not d.has("month") or not d.has("day"):
		return ""
	return "%04d-%02d-%02d" % [int(d.year), int(d.month), int(d.day)]

# ------------------------------------------------------------
# DAILY
# ------------------------------------------------------------
func load_daily_list():
	# Sayfa değiştiğinde silme kuyruğunu temizle (Karışıklık olmasın)
	pending_deletes.clear()

	# 1. Temizlik
	for child in daily_list_container.get_children():
		child.queue_free()

	var target_date := get_date_str(selected_date_dict)
	
	# 2. Veriyi al
	var logs = Globals.cache.get("gym_log")

	# ============================================================
	# 🛠️ DÜZELTME YAMASI: Tip 27 (Dictionary) ise Array'e çevir
	# ============================================================
	if typeof(logs) == TYPE_DICTIONARY:
		# print("⚠️ UYARI: gym_log Dictionary (Tip 27) olarak gelmiş. Düzeltiliyor...")
		
		# İhtimaller:
		# 1. Veri { "results": [..] } şeklindeyse:
		if logs.has("results") and typeof(logs["results"]) == TYPE_ARRAY:
			logs = logs["results"]
		
		# 2. Veri { "unique_id": {data}, "unique_id2": {data} } şeklindeyse:
		else:
			logs = logs.values() # Sadece içindeki değerleri alıp liste yap
		
		# Düzeltilmiş halini hafızaya geri yaz (Kalıcı çözüm olsun)
		Globals.cache["gym_log"] = logs
		Globals.mark_dirty() 
	
	if typeof(logs) != TYPE_ARRAY:
		logs = []
	# ============================================================

	print("📂 İncelenen Kayıt Sayısı: ", logs.size())

	# 3. Normal Döngü
	for entry in logs:
		if typeof(entry) != TYPE_DICTIONARY:
			continue

		var entry_date = str(entry.get("date", "")).strip_edges()
		
		# 👇 YENİ: Eğer ismi boşsa (daha önce silinmişse) yükleme
		var e_name = str(entry.get("exercise_name", "")).strip_edges()
		if e_name == "": continue

		if entry_date == target_date:
			var row = daily_row_scene.instantiate()
			daily_list_container.add_child(row)
			
			# --- YENİ: Silme sinyalini bağla ---
			row.delete_requested.connect(_on_row_delete_requested)
			
			if row.has_method("set_data"):
				row.set_data(entry)

func add_empty_row():
	var row = daily_row_scene.instantiate()
	daily_list_container.add_child(row)
	# --- YENİ: Yeni eklenen satır için de silme sinyalini bağla ---
	row.delete_requested.connect(_on_row_delete_requested)

# ------------------------------------------------------------
# 🗑️ SİLME YÖNETİMİ (GÜNCELLENDİ)
# ------------------------------------------------------------
func _on_row_delete_requested(row_node):
	# 1. Satırın verisini al
	if row_node.has_method("get_data"):
		var data = row_node.get_data()
		
		# 2. Eğer bu satır veritabanından geliyorsa (ID'si varsa)
		# Onu "silinecekler" listesine ekle.
		# Worker mantığı: ID var + İsim Boş = SİL
		if data.has("id") and data["id"] != null:
			print("🗑️ Silme kuyruğuna eklendi: ID ", data["id"])
			pending_deletes.append({
				"id": data["id"],
				"date": get_date_str(selected_date_dict),
				"exercise_name": "", # İSMİ BOŞ GÖNDERİYORUZ Kİ WORKER SİLSİN
				# Diğer alanlar boş olsa da olur, Worker sadece ID ve isme bakıyor
				"sets": 0, "reps": 0, "duration": 0, "rest": 0, "weight": 0, "region": "", "completed": false
			})

	# 3. Satırı UI'dan hemen sil
	daily_list_container.remove_child(row_node)
	row_node.queue_free()
	
	# 4. Godot'nun işlemi bitirmesi için 1 kare bekle ve KAYDET
	await get_tree().process_frame
	save_daily_data()

func save_daily_data():
	var target_date := get_date_str(selected_date_dict)
	if target_date == "":
		return

	var new_log_list: Array = []

	# 1. BAŞKA GÜNLERİN VERİSİNİ KORU
	for entry in Globals.cache.get("gym_log", []):
		if typeof(entry) == TYPE_DICTIONARY and entry.get("date") != target_date:
			new_log_list.append(entry)

	# 2. SİLİNECEK OLANLARI (ID'li ama ismi boşaltılmış) LİSTEYE EKLE
	# Bunlar sunucuya gidince "DELETE" komutunu tetikleyecek.
	for del_item in pending_deletes:
		new_log_list.append(del_item)

	# 3. EKRANDAKİ MEVCUT SATIRLARI EKLE
	for child in daily_list_container.get_children():
		if not child.has_method("get_data"):
			continue

		var data = child.get_data()
		if data.is_empty():
			continue

		var name = data.get("exercise_name", "").strip_edges()
		
		# İsim boşsa ve ID yoksa kaydetme (Yeni açılmış boş satır)
		if name == "" and (not data.has("id") or data["id"] == null):
			continue

		data["date"] = target_date
		new_log_list.append(data)

	# 4. KAYDET
	Globals.cache["gym_log"] = new_log_list
	Globals.mark_dirty()
	Globals.save_cache()
	
	# Kuyruğu temizle (Artık listeye girdiler)
	pending_deletes.clear()
	print("✅ Günlük plan kaydedildi ve silme emirleri işlendi.")

# ------------------------------------------------------------
# WEEKLY
# ------------------------------------------------------------
func _on_tab_changed(tab_idx):
	if tab_container.get_child(tab_idx).name == "Weekly":
		refresh_weekly_view()

func refresh_weekly_view():
	# print("\n📅 --- HAFTALIK GÖRÜNÜM HESAPLANIYOR (DEBUG MOD) ---")

	var today_dict = Time.get_date_dict_from_system()
	today_dict["hour"] = 12 
	today_dict["minute"] = 0
	today_dict["second"] = 0
	
	var today_str = get_date_str(today_dict)
	
	var current_unix = Time.get_unix_time_from_datetime_dict(today_dict)
	var weekday = today_dict.weekday
	var days_from_monday = weekday - 1
	if weekday == 0:
		days_from_monday = 6

	var monday_unix = current_unix - (days_from_monday * 86400)
	
	# --- VERİ ALMA VE DÜZELTME ---
	var logs = Globals.cache.get("gym_log")
	if typeof(logs) == TYPE_DICTIONARY:
		if logs.has("results") and typeof(logs["results"]) == TYPE_ARRAY:
			logs = logs["results"]
		else:
			logs = logs.values()
	if typeof(logs) != TYPE_ARRAY:
		logs = []
	# -----------------------------

	for i in range(1, 8):
		var loop_unix = monday_unix + ((i - 1) * 86400)
		var loop_date_dict = Time.get_date_dict_from_unix_time(loop_unix)
		var loop_date_str = get_date_str(loop_date_dict)

		var container = weekly_rows.get(i)
		if not container:
			continue

		for child in container.get_children():
			child.queue_free()

		for entry in logs:
			if typeof(entry) != TYPE_DICTIONARY: continue
			
			var entry_date = str(entry.get("date", "")).strip_edges()
			
			# İsim kontrolü (Boş olanları gösterme)
			var e_name = str(entry.get("exercise_name", "")).strip_edges()
			if e_name == "": continue

			if entry_date == loop_date_str:
				var row = weekly_row_scene.instantiate()
				container.add_child(row)
				
				row.custom_minimum_size.y = 40
				
				var duration_text := ""
				if entry.has("duration"): duration_text = "%d dk" % int(entry.duration)
				var is_done = entry.get("completed", false)
				var is_past = loop_date_str < today_str

				if row.has_method("setup_row"):
					row.setup_row(entry.get("exercise_name", ""), duration_text, is_done, is_past and not is_done)

	# print("🏁 Haftalık döngü bitti.")

# ------------------------------------------------------------
# DROPDOWNS
# ------------------------------------------------------------
func fill_years():
	year_select.clear()
	var current = Time.get_date_dict_from_system().year
	for y in range(current - 2, current + 5):
		year_select.add_item(str(y))

func fill_months():
	month_select.clear()
	var months = [
		"January","February","March","April","May","June",
		"July","August","September","October","November","December"
	]
	for m in months:
		month_select.add_item(m)

func update_days_in_dropdown():
	day_select.clear()
	var m = month_select.selected + 1
	var y = int(year_select.get_item_text(year_select.selected))
	var limit = 31

	if m in [4, 6, 9, 11]:
		limit = 30
	elif m == 2:
		limit = 29 if y % 4 == 0 else 28

	for d in range(1, limit + 1):
		day_select.add_item(str(d))

func _on_texture_button_pressed() -> void:
	# Bu satırın başında 1 tane TAB tuşuna bas
	$ChatPopup.visible = true
	
	# Bu satırın başında da 1 tane TAB tuşuna bas
	$ChatPopup/MainWindow/InputField.grab_focus()
