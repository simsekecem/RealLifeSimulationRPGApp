extends Control

@export var hour_row_scene: PackedScene = preload("res://scenes/prefabs/StudyHoursRow.tscn")

# Gün butonları listesi (Sıralama ÇOK ÖNEMLİ: Pzt, Sal, Çar... Paz)
@onready var day_buttons = [
	$DaysPanel/MondayButton,    # Index 0 = Pazartesi
	$DaysPanel/TuesdayButton,   # Index 1 = Salı
	$DaysPanel/WednesdayButton,
	$DaysPanel/ThursdayButton,
	$DaysPanel/FridayButton,
	$DaysPanel/SaturdayButton,
	$DaysPanel/SundayButton     # Index 6 = Pazar
]

@onready var hours_list = $HoursPanel/ScrollContainer/HoursList
@onready var back_button = $BackButton

# Seçili butonu takip ediyoruz
var current_selected_button: Button = null

# Bu haftanın Pazartesi gününün "Sanal" Unix zamanı
var current_week_monday_unix: int = 0

func _ready():
	back_button.pressed.connect(_on_back_button_pressed)
	
	if UI.has_node("UIRoot"):
		UI.get_node("UIRoot").show_only_top_right_buttons()
	
	# 1. BU HAFTANIN TARİHLERİNİ HESAPLA
	calculate_current_week()

	# --- DEBUG: Konsola Cache durumunu yazdıralım (Kontrol için) ---
	var today_str = get_date_string_for_index(0) 
	print("📅 DEBUG: Bu haftanın Pazartesi tarihi: ", today_str)
	print("📂 CACHE DURUMU (Ham Veri): ", Globals.cache["study_log"])
	# -------------------------------------------------------------------

	# 2. BUTONLARI BAĞLA
	for i in range(day_buttons.size()):
		var button = day_buttons[i]
		button.toggled.connect(_on_day_button_toggled.bind(button, i))

# ============================================================
#  TARİH HESAPLAMA MOTORU
# ============================================================
func calculate_current_week():
	var date_dict = Time.get_datetime_dict_from_system()
	var now_unix = Time.get_unix_time_from_datetime_dict(date_dict)
	var current_weekday = date_dict.weekday 
	
	# Pazartesi'ye (1) dönmek için kaç gün çıkarmalıyız?
	var days_to_subtract = current_weekday - 1
	
	current_week_monday_unix = now_unix - (days_to_subtract * 86400)

func get_date_string_for_index(day_index: int) -> String:
	var target_day_unix = current_week_monday_unix + (day_index * 86400)
	return Time.get_date_string_from_unix_time(target_day_unix)

# ============================================================
#  BUTON İŞLEMLERİ
# ============================================================
func _on_day_button_toggled(pressed: bool, clicked_button: Button, day_index: int):
	if pressed:
		if current_selected_button != null and current_selected_button != clicked_button:
			current_selected_button.button_pressed = false
		
		current_selected_button = clicked_button
		
		var date_string = get_date_string_for_index(day_index)
		print("📅 Seçilen Tarih: ", date_string)
		load_hours_for_day(date_string)
		
	else:
		if clicked_button == current_selected_button:
			current_selected_button = null
		clear_hours()

# ============================================================
#  VERİ YÜKLEME VE OLUŞTURMA
# ============================================================
func load_hours_for_day(date_string: String):
	clear_hours()

	var start_hour = 9
	var end_hour = 24

	for h in range(start_hour, end_hour):
		var row = hour_row_scene.instantiate()
		var label = row.get_node("HBoxContainer/HourLabel")
		var text_edit = row.get_node("HBoxContainer/TaskTextEdit") 
		
		label.text = "\n %02d:00 - %02d:00" % [h, h+1]
		
		# Veritabanından veriyi çek
		var saved_text = get_study_data(date_string, h)
		text_edit.text = saved_text
		
		if text_edit.has_signal("text_changed"):
			text_edit.text_changed.connect(_on_task_text_changed.bind(text_edit, date_string, h))
			
		hours_list.add_child(row)

func clear_hours():
	for child in hours_list.get_children():
		child.queue_free()

# ============================================================
#  SİNYAL YAKALAMA
# ============================================================
func _on_task_text_changed(text_node, date_string, hour):
	save_study_data(date_string, hour, text_node.text)

# ============================================================
#  GÜVENLİ VERİ KAYDETME (AUTO-FIX WRAPPER)
# ============================================================
func save_study_data(date: String, hour: int, subject: String):
	
	var raw_data = Globals.cache["study_log"]
	var log_list = []
	
	# --- 1. KUTU (WRAPPER) VARSA AÇ VE DÜZELT ---
	if typeof(raw_data) == TYPE_DICTIONARY and raw_data.has("results"):
		log_list = raw_data["results"]
		# Globals'ı kalıcı olarak düzelt (Overwrite)
		Globals.cache["study_log"] = log_list
	elif typeof(raw_data) == TYPE_ARRAY:
		log_list = raw_data
	else:
		log_list = []
		Globals.cache["study_log"] = log_list

	var found = false
	
	# --- 2. LİSTEYİ GÜNCELLE ---
	for i in range(log_list.size()):
		var entry = log_list[i]
		if typeof(entry) != TYPE_DICTIONARY: continue
			
		# Tip Dönüşümü (Güvenli)
		var entry_hour = int(float(str(entry.get("start_time", -1))))
		var entry_date = str(entry.get("date", "")).strip_edges()
		
		if entry_date == date and entry_hour == hour:
			Globals.cache["study_log"][i]["subject"] = subject
			found = true
			break
	
	# --- 3. YENİ KAYIT ---
	if not found:
		var new_entry = {
			"date": date,
			"start_time": hour,
			"end_time": hour + 1,
			"subject": subject
		}
		Globals.cache["study_log"].append(new_entry)
	
	Globals.mark_dirty()

# ============================================================
#  GÜVENLİ VERİ ÇEKME (WRAPPER ÇÖZÜCÜ + TİP ZORLAYICI)
# ============================================================
func get_study_data(target_date: String, target_hour: int) -> String:
	var raw_data = Globals.cache["study_log"]
	var log_list = []

	# --- 1. KUTU KONTROLÜ (WRAPPER CHECK) ---
	if typeof(raw_data) == TYPE_DICTIONARY and raw_data.has("results"):
		log_list = raw_data["results"]
	elif typeof(raw_data) == TYPE_ARRAY:
		log_list = raw_data
	else:
		return ""

	# --- 2. LİSTEYİ TARA ---
	for entry in log_list:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
			
		# --- 3. TİP ZORLAMA (STRING "9.0" -> INT 9) ---
		var raw_start = entry.get("start_time", -1)
		
		# String -> Float -> Int dönüşümü yapıyoruz (En garantisi)
		var entry_hour = int(float(str(raw_start)))
		
		# Tarihteki boşlukları temizle
		var entry_date = str(entry.get("date", "")).strip_edges()
		
		if entry_date == target_date and entry_hour == target_hour:
			return str(entry.get("subject", ""))
			
	return ""

func _on_back_button_pressed():
	# Önce yerel kaydet
	Globals.save_cache()
	
	if UI.has_node("UIRoot"):
		UI.get_node("UIRoot").return_to_town()
