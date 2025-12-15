extends Control

# =================================================
# NODE REFERANSLARI
# =================================================
@onready var notes_edit: TextEdit = $NinePatchRect/TextEdit
@onready var meal_panel: Control = $MealPanel 

# UYARI: "Snakcs_Panel" yazım hatasına sadık kalındı.
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

# =================================================
# BAŞLANGIÇ (READY)
# =================================================
func _ready():
	if meal_panel: meal_panel.visible = false
	if notes_edit: notes_edit.editable = false
	
	if back_button: back_button.pressed.connect(_on_back_button_pressed)
	
	for day_name in day_buttons.keys():
		var btn = day_buttons[day_name]
		if btn:
			btn.toggle_mode = true
			btn.pressed.connect(_on_day_button_pressed.bind(day_name))

	for field_key in input_fields.keys():
		var edit = input_fields[field_key]
		if edit:
			if not edit.text_changed.is_connected(_on_meal_text_changed.bind(field_key, edit)):
				edit.text_changed.connect(_on_meal_text_changed.bind(field_key, edit))

	if notes_edit and not notes_edit.text_changed.is_connected(_on_notes_changed):
		notes_edit.text_changed.connect(_on_notes_changed)

# =================================================
# GÜN SEÇİMİ VE GÖRSEL GÜNCELLEME
# =================================================
func _on_day_button_pressed(selected_day: String):
	if current_day == selected_day and meal_panel.visible: return

	current_day = selected_day
	
	if meal_panel: meal_panel.visible = true
	if notes_edit: notes_edit.editable = true

	for d_name in day_buttons.keys():
		if day_buttons[d_name]:
			day_buttons[d_name].set_pressed_no_signal(d_name == selected_day)

	var day_data = _get_data_for_day(selected_day)
	_set_inputs_quietly(day_data)


func _set_inputs_quietly(data: Dictionary):
	for field in input_fields.keys():
		var edit = input_fields[field]
		if edit:
			edit.text = Globals.safe_str(data.get(field, ""))
	
	if notes_edit:
		notes_edit.text = Globals.safe_str(data.get("notes", ""))

# =================================================
# VERİ KAYIT/GÜNCELLEME (DEFENSIVE + DB UYUMU)
# =================================================

func _get_data_for_day(day: String) -> Dictionary:
	# Listeyi alır ve tipinin Array olduğundan emin olur
	var list: Array = Globals.ensure_list(Globals.cache.get("restaurant", []))
	
	for entry in list:
		# DB UYUMU: 'date' anahtarı ile karşılaştırma (study_log mantığı)
		if Globals.safe_str(entry.get("date", "")) == day: 
			return entry
	return {}

func _save_data(field: String, value: String):
	if current_day == "": return 

	# Globals cache'den listeyi çek ve üzerinde çalış
	# Bunu garanti altına almak için listeyi çekip hemen Globals'a geri atıyoruz.
	var list: Array = Globals.ensure_list(Globals.cache.get("restaurant", []))
	Globals.cache["restaurant"] = list
	
	var found = false
	for i in range(list.size()):
		if typeof(list[i]) != TYPE_DICTIONARY: continue
		
		# Benzersiz anahtar kontrolü: 'date'
		if Globals.safe_str(list[i].get("date", "")) == current_day:
			
			# Var olan kaydı güncelle
			list[i][field] = value
			found = true
			break
	
	if not found:
		# Yeni bir kayıt oluştur
		var new_entry = { 
			"date": current_day, 
			"breakfast": "", 
			"lunch": "", 
			"dinner": "", 
			"snacks": "", 
			"notes": "" 
		}
		new_entry[field] = value
		list.append(new_entry)
	
	# Değişiklik yapıldıktan sonra Globals'i kirli olarak işaretle
	Globals.mark_dirty()
	
	# 🔴 DEBUG KONTROLÜ: Verinin cache'e kaydedildiğini konsolda gösterir.
	# Eğer bu çıktı doğruysa, sorun Godot'ta değil, Cloudflare'dadır.
	print("✅ RESTAURANT SAVE: Güncellenen Cache İçeriği: ", JSON.stringify(Globals.cache["restaurant"]))

# =================================================
# SİNYALLER
# =================================================
func _on_meal_text_changed(field_key: String, edit_node: TextEdit):
	if meal_panel.visible:
		_save_data(field_key, edit_node.text)

func _on_notes_changed():
	if meal_panel.visible:
		_save_data("notes", notes_edit.text)

# =================================================
# ÇIKIŞ (CRITICAL DEBUG POINT)
# =================================================
func _on_back_button_pressed():
	# Çıkıştan hemen önce son durumu kontrol et
	print("🚨 ÇIKIŞ KONTROLÜ: Global Cache'deki RESTAURANT verisi:")
	print(JSON.stringify(Globals.cache.get("restaurant", "VERİ YOK")))
	
	# Güvenli sahne geçişi (Bu, aynı zamanda kaydı tetikler)
	Globals.change_scene_with_loading("res://scenes/town.tscn")
