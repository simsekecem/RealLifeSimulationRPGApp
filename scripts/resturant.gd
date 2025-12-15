extends Control

# =================================================
# NODE REFERANSLARI
# =================================================
@onready var notes_edit: TextEdit = $NinePatchRect/TextEdit
@onready var meal_panel: Control = $MealPanel 

@onready var input_fields := {
	"breakfast": $MealPanel/ScrollContainer/MealList/Breakfast_Panel/TextEdit,
	"lunch":     $MealPanel/ScrollContainer/MealList/Lunch_Panel/TextEdit,
	"dinner":    $MealPanel/ScrollContainer/MealList/Dinner_Panel/TextEdit,
	"snacks":    $MealPanel/ScrollContainer/MealList/Snakcs_Panel/TextEdit 
}

@onready var day_buttons := {
	"Monday":    $M_Button, "Tuesday":   $TU_Button, "Wednesday": $W_Button,
	"Thursday":  $T_Button, "Friday":    $F_Button, "Saturday":  $SA_Button,
	"Sunday":    $S_Button
}

@onready var back_button: BaseButton = $Back_Button 

var current_day: String = "" 

# 👇 GÜNLERİN SAYISAL DEĞERLERİ (Hesaplama için şart)
var day_indices = {
	"Monday": 1, "Tuesday": 2, "Wednesday": 3,
	"Thursday": 4, "Friday": 5, "Saturday": 6,
	"Sunday": 7
}

# =================================================
# BAŞLANGIÇ
# =================================================
func _ready():
	if meal_panel: meal_panel.visible = false
	if notes_edit: notes_edit.editable = false
	
	if back_button: back_button.pressed.connect(_on_back_button_pressed)
	
	for day_name in day_buttons.keys():
		var btn = day_buttons[day_name]
		if btn:
			btn.toggle_mode = true
			# Butona basınca o günün ismini (Monday) fonksiyona yolla
			btn.pressed.connect(_on_day_button_pressed.bind(day_name))

	for field_key in input_fields.keys():
		var edit = input_fields[field_key]
		if edit:
			if not edit.text_changed.is_connected(_on_meal_text_changed.bind(field_key, edit)):
				edit.text_changed.connect(_on_meal_text_changed.bind(field_key, edit))

	if notes_edit and not notes_edit.text_changed.is_connected(_on_notes_changed):
		notes_edit.text_changed.connect(_on_notes_changed)

# =================================================
# GÜN SEÇİMİ (BURASI TARİHİ HESAPLAR)
# =================================================
func _on_day_button_pressed(selected_day_name: String):
	# 👇 1. Adım: Buton ismini (Monday) gerçek tarihe (2025-12-15) çevir
	var real_date = get_date_string_for_day(selected_day_name)
	
	# Eğer zaten o gündeysek işlem yapma
	if current_day == real_date and meal_panel.visible: return

	# 👇 2. Adım: Artık sistemde "Monday" değil "2025-12-15" olarak çalışacağız
	current_day = real_date
	print("📅 Buton: ", selected_day_name, " -> Hesaplanan Tarih: ", current_day)
	
	if meal_panel: meal_panel.visible = true
	if notes_edit: notes_edit.editable = true

	# Buton ışıklarını güncelle
	for d_name in day_buttons.keys():
		if day_buttons[d_name]:
			day_buttons[d_name].set_pressed_no_signal(d_name == selected_day_name)

	# 👇 3. Adım: Veritabanından o tarihe ait veriyi getir
	var day_data = _get_data_for_day(current_day)
	_set_inputs_quietly(day_data)


# =================================================
# TARİH HESAPLAMA MOTORU ⚙️
# =================================================
func get_date_string_for_day(day_name: String) -> String:
	# 1. Bugünün sistem saatini al
	var today_dict = Time.get_date_dict_from_system()
	var current_unix = Time.get_unix_time_from_datetime_dict(today_dict)
	
	# 2. Bugün haftanın kaçıncı günü? (Pzt=1 ... Paz=7 yapıyoruz)
	var current_weekday = today_dict.weekday
	if current_weekday == 0: current_weekday = 7 # Godot'da Pazar 0 ise 7 olsun
	
	# 3. Tıklanan buton haftanın kaçıncı günü? (Örn: Monday = 1)
	var target_weekday = day_indices.get(day_name, 1)
	
	# 4. Aradaki gün farkını bul
	# Örnek: Bugün Salı(2). Pazartesi(1) butonuna bastın.
	# Fark = 1 - 2 = -1 gün (Dün)
	var diff_days = target_weekday - current_weekday
	
	# 5. Farkı saniye olarak şu anki zamana ekle
	var target_unix = current_unix + (diff_days * 86400)
	
	# 6. Yeni tarihi string'e çevir (YYYY-MM-DD)
	var target_date_dict = Time.get_date_dict_from_unix_time(target_unix)
	return "%04d-%02d-%02d" % [target_date_dict.year, target_date_dict.month, target_date_dict.day]

# =================================================
# EKRANI DOLDURMA
# =================================================
func _set_inputs_quietly(data: Dictionary):
	for field in input_fields.keys():
		var edit = input_fields[field]
		if edit:
			edit.text = Globals.safe_str(data.get(field, ""))
	
	if notes_edit:
		notes_edit.text = Globals.safe_str(data.get("notes", ""))

# =================================================
# VERİ KAYIT (DB İŞLEMLERİ)
# =================================================
func _get_data_for_day(day: String) -> Dictionary:
	var list: Array = Globals.ensure_list(Globals.cache.get("restaurant", []))
	for entry in list:
		# Veritabanında tarih eşleşmesi arıyoruz
		if Globals.safe_str(entry.get("date", "")) == day: 
			return entry
	return {}

func _save_data(field: String, value: String):
	if current_day == "": return 

	var list: Array = Globals.ensure_list(Globals.cache.get("restaurant", []))
	Globals.cache["restaurant"] = list
	
	var found = false
	for i in range(list.size()):
		if typeof(list[i]) != TYPE_DICTIONARY: continue
		
		# Listede bu tarihi (2025-12-16) bulursan güncelle
		if Globals.safe_str(list[i].get("date", "")) == current_day:
			list[i][field] = value
			found = true
			break
	
	# Bulamazsan yeni ekle
	if not found:
		var new_entry = { 
			"date": current_day, # Buraya artık Monday değil tarih yazılıyor
			"breakfast": "", "lunch": "", "dinner": "", "snacks": "", "notes": "" 
		}
		new_entry[field] = value
		list.append(new_entry)
	
	Globals.mark_dirty()

# =================================================
# SİNYALLER
# =================================================
func _on_meal_text_changed(field_key: String, edit_node: TextEdit):
	if meal_panel.visible:
		_save_data(field_key, edit_node.text)

func _on_notes_changed():
	if meal_panel.visible:
		_save_data("notes", notes_edit.text)

func _on_back_button_pressed():
	Globals.save_cache()
	if UI.has_node("UIRoot"): UI.get_node("UIRoot").return_to_town()
