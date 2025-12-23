extends Control

# =================================================
# NODE REFERANSLARI
# =================================================
# Not kutusunun olduğu yer (Sol taraf veya alt taraf)
@onready var notes_edit: TextEdit = $NinePatchRect/TextEdit

# Yemeklerin olduğu panel (Sağ taraf)
@onready var meal_panel: Control = $MealPanel 

# Yemek Giriş Kutuları
@onready var input_fields := {
	"breakfast": $MealPanel/ScrollContainer/MealList/Breakfast_Panel/TextEdit,
	"lunch":     $MealPanel/ScrollContainer/MealList/Lunch_Panel/TextEdit,
	"dinner":    $MealPanel/ScrollContainer/MealList/Dinner_Panel/TextEdit,
	"snacks":    $MealPanel/ScrollContainer/MealList/Snakcs_Panel/TextEdit 
}

# Gün Butonları
@onready var day_buttons := {
	"Monday":    $M_Button, "Tuesday":   $TU_Button, "Wednesday": $W_Button,
	"Thursday":  $T_Button, "Friday":    $F_Button, "Saturday":  $SA_Button,
	"Sunday":    $S_Button
}

@onready var back_button: BaseButton = $Back_Button 

# Şu an seçili olan tarih (String formatında: "2025-10-25")
var current_day: String = "" 

# 👇 GÜNLERİN SAYISAL DEĞERLERİ (Tarih hesaplama için)
var day_indices = {
	"Monday": 1, "Tuesday": 2, "Wednesday": 3,
	"Thursday": 4, "Friday": 5, "Saturday": 6,
	"Sunday": 7
}

# =================================================
# BAŞLANGIÇ
# =================================================
func _ready():
	# 1. BAŞLANGIÇTA HER ŞEYİ GİZLE
	if meal_panel: meal_panel.visible = false
	if notes_edit: notes_edit.visible = false # Direkt görünmez yapıyoruz
	
	if back_button: back_button.pressed.connect(_on_back_button_pressed)
	
	# Gün butonlarını bağla
	for day_name in day_buttons.keys():
		var btn = day_buttons[day_name]
		if btn:
			btn.toggle_mode = true
			# Butona basınca o günün ismini (Monday) fonksiyona yolla
			btn.pressed.connect(_on_day_button_pressed.bind(day_name))

	# Input alanlarını (Yemekler) bağla - Yazı değişince kaydetsin
	for field_key in input_fields.keys():
		var edit = input_fields[field_key]
		if edit:
			if not edit.text_changed.is_connected(_on_meal_text_changed.bind(field_key, edit)):
				edit.text_changed.connect(_on_meal_text_changed.bind(field_key, edit))

	# Not alanı bağlantısı
	if notes_edit and not notes_edit.text_changed.is_connected(_on_notes_changed):
		notes_edit.text_changed.connect(_on_notes_changed)

	# ❌ OTOMATİK SEÇİM YOK: Kullanıcı tıklayana kadar her şey gizli kalacak.


	
# =================================================
# GÜN SEÇİMİ (BURASI TARİHİ HESAPLAR VE AÇAR)
# =================================================
func _on_day_button_pressed(selected_day_name: String):
	# 👇 1. Adım: Buton ismini (Monday) gerçek tarihe (2025-12-15) çevir
	var real_date = get_date_string_for_day(selected_day_name)
	
	# Eğer zaten o gündeysek ve panel açıksa tekrar yükleme yapma
	if current_day == real_date and meal_panel.visible: return

	# 👇 2. Adım: Yeni tarihi ayarla
	current_day = real_date
	print("📅 Buton: ", selected_day_name, " -> Tarih: ", current_day)
	
	# 👇 3. Adım: PANELLERİ GÖRÜNÜR YAP
	if meal_panel: meal_panel.visible = true
	if notes_edit: 
		notes_edit.visible = true
		notes_edit.editable = true

	# Buton ışıklarını güncelle (Sadece basılan yansın)
	for d_name in day_buttons.keys():
		if day_buttons[d_name]:
			day_buttons[d_name].set_pressed_no_signal(d_name == selected_day_name)

	# 👇 4. Adım: Veritabanından o tarihe ait veriyi getir ve doldur
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
	var diff_days = target_weekday - current_weekday
	
	# 5. Farkı saniye olarak şu anki zamana ekle
	var target_unix = current_unix + (diff_days * 86400)
	
	# 6. Yeni tarihi string'e çevir (YYYY-MM-DD)
	var target_date_dict = Time.get_date_dict_from_unix_time(target_unix)
	return "%04d-%02d-%02d" % [target_date_dict.year, target_date_dict.month, target_date_dict.day]

# =================================================
# EKRANI DOLDURMA (SESSİZCE)
# =================================================
func _set_inputs_quietly(data: Dictionary):
	# Yemekleri doldur
	for field in input_fields.keys():
		var edit = input_fields[field]
		if edit:
			# Signal tetiklemeden metni değiştir (TextEdit için direkt atama yeterli genelde)
			edit.text = Globals.safe_str(data.get(field, ""))
	
	# Notları doldur
	if notes_edit:
		notes_edit.text = Globals.safe_str(data.get("notes", ""))

# =================================================
# VERİ KAYIT (DB İŞLEMLERİ)
# =================================================
func _get_data_for_day(day: String) -> Dictionary:
	var list: Array = Globals.ensure_list(Globals.cache.get("restaurant", []))
	for entry in list:
		if Globals.safe_str(entry.get("date", "")) == day: 
			return entry
	return {}

func _save_data(field: String, value: String):
	if current_day == "": return 

	var list: Array = Globals.ensure_list(Globals.cache.get("restaurant", []))
	var found = false
	
	for i in range(list.size()):
		if typeof(list[i]) != TYPE_DICTIONARY: continue
		
		if Globals.safe_str(list[i].get("date", "")) == current_day:
			# Mevcut kaydı bulduk, sadece ilgili alanı (not veya yemek) güncelle
			list[i][field] = value
			found = true
			break
	
	if not found:
		# 🌟 BURASI KRİTİK: Eğer o güne ait hiç kayıt yoksa, 
		# tüm alanları boş ("") olan ama tarihi ve senin yazdığın notu içeren yeni bir kayıt oluştur.
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
	
	Globals.cache["restaurant"] = list
	Globals.mark_dirty()
# 👇 BURAYA EKLE: Kullanıcı boş olmayan bir değer girdiğinde görevi tetikle
	if value.strip_edges() != "" and has_node("/root/QuestManager"):
		QuestManager.trigger_action("eat_action")      # Worker'daki günlük görev hedefi
		QuestManager.trigger_action("first_restaurant") # Statik giriş görevi
# =================================================
# SİNYALLER
# =================================================
func _on_meal_text_changed(field_key: String, edit_node: TextEdit):
	# Sadece panel görünürse kaydet (Hata önlemek için)
	if meal_panel.visible:
		_save_data(field_key, edit_node.text)

func _on_notes_changed():
	# Sadece panel görünürse kaydet (notes_edit de meal_panel mantığıyla hareket ediyor)
	if meal_panel.visible: 
		_save_data("notes", notes_edit.text)

func _on_back_button_pressed():
	Globals.save_cache()
# 👇 BURAYA EKLE: Eğer restaurant listesinde veri varsa çıkarken de tetikle
	if has_node("/root/QuestManager"):
		var rest_list = Globals.cache.get("restaurant", [])
		if rest_list.size() > 0:
			QuestManager.trigger_action("eat_action")
			QuestManager.trigger_action("first_restaurant")
	if UI.has_node("UIRoot"): UI.get_node("UIRoot").return_to_town()

# TextureButton'ın 'pressed' sinyaline bağla
func _on_texture_button_pressed() -> void:
	# Eğer ChatPopup_R sahneye gömülü ise (Görüntü 8fe72d'deki gibi):
	$ChatPopup_R.visible = true
	# Pencere açıldığında inputa odaklanmasını sağlar
	$ChatPopup_R/MainWindow/InputField.grab_focus()
