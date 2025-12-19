extends Control

# =================================================
# NODE REFERANSLARI
# =================================================

# --- Ana Ekran (Görüntüleme) ---
@onready var close_button_main = $CloseButton 
@onready var edit_button = $EditButton

# Görüntüleme Etiketleri
@onready var label_name_display = $Name
@onready var label_level_display = $Level
@onready var label_xp_display = $XP
@onready var label_birth_display = $Birthday

# Karakter Önizleme (Hareketli Sprite)
@onready var preview_sprite = $Background/CharacterPreviewHolder/PreviewSprite

# --- Edit Penceresi (Düzenleme) ---
@onready var edit_window = $EditWindow
@onready var close_button_edit = $EditWindow/Background/CloseButton
@onready var save_button = $EditWindow/SaveButton
@onready var input_name = $EditWindow/NewNameLE

# Karakter Değiştirme Butonları (Hiyerarşine göre düzeltildi)
@onready var btn_next = $BtnNext
@onready var btn_prev = $BtnPrev 

# Tarih Seçiciler
@onready var opt_day = $EditWindow/BirthdayContainer/Day
@onready var opt_month = $EditWindow/BirthdayContainer/Month 
@onready var opt_year = $EditWindow/BirthdayContainer/Year

# -----------------------------------------------
# DEĞİŞKENLER
# -----------------------------------------------
var temp_char_id: int = 1
var max_character_count: int = 2

# =================================================
# BAŞLANGIÇ
# =================================================
func _ready():
	# Ana buton bağlantıları
	close_button_main.pressed.connect(hide_avatar_window)
	edit_button.pressed.connect(show_edit_window)
	close_button_edit.pressed.connect(hide_edit_window)
	
	if save_button:
		save_button.pressed.connect(_on_save_pressed)
	
	# Karakter değiştirme butonlarını bağla
	if btn_next: 
		btn_next.pressed.connect(_change_character.bind(1))
	if btn_prev: 
		btn_prev.pressed.connect(_change_character.bind(-1))
		print("✅ Karakter değiştirme butonları bağlandı.")
	
	_setup_date_dropdowns()
	edit_window.visible = false
	update_ui_from_cache()

# =================================================
# UI GÜNCELLEME (LOAD)
# =================================================
func update_ui_from_cache():
	var user_data = Globals.cache.get("user", {})
	
	# Ana Ekranı Doldur
	if label_name_display: label_name_display.text = str(user_data.get("name", "Player"))
	
	if label_level_display: 
		var lvl = int(user_data.get("level", 1))
		label_level_display.text = str(lvl)
		
	if label_xp_display: 
		var xp = int(user_data.get("experience", 0))
		label_xp_display.text = str(xp)
	
	var birth_str = str(user_data.get("birthdate", "2000-01-01"))
	if label_birth_display: label_birth_display.text = birth_str
	
	# Edit Penceresini Doldur
	if input_name: input_name.text = str(user_data.get("name", ""))
	_set_date_selectors(birth_str)
	
	# Mevcut Karakteri Yükle
	temp_char_id = int(user_data.get("character_id", 1))
	_update_character_visual(temp_char_id)

# =================================================
# KARAKTER GÖRSEL YÖNETİMİ
# =================================================
func _update_character_visual(id: int):
	if id < 1: id = 1
	var path = "res://assets/characters/resources/char_%d.tres" % id
	
	if ResourceLoader.exists(path) and preview_sprite:
		preview_sprite.sprite_frames = load(path)
		preview_sprite.play("idle_down") 
		preview_sprite.scale = Vector2(4, 4) 
		preview_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	else:
		print("⚠️ Karakter animasyonu bulunamadı: ", path)

func _change_character(direction: int):
	print("🔘 Ok basıldı! Eski ID: ", temp_char_id)
	temp_char_id += direction
	if temp_char_id > max_character_count: temp_char_id = 1
	elif temp_char_id < 1: temp_char_id = max_character_count
	print("🆔 Yeni Geçici ID: ", temp_char_id)
	_update_character_visual(temp_char_id)

# =================================================
# KAYDETME (SAVE)
# =================================================
func _on_save_pressed():
	# Sadece isim ve doğum günü değişikliklerini kaydet
	var new_name = input_name.text.strip_edges()
	var new_birth_date = _get_date_string_from_selectors()
	
	if not Globals.cache.has("user"): Globals.cache["user"] = {}
	Globals.cache["user"]["name"] = new_name
	Globals.cache["user"]["birthdate"] = new_birth_date
	
	Globals.mark_dirty()
	Globals.save_cache()
	print("✅ Profil (İsim/Tarih) güncellendi.")
	
	update_ui_from_cache()
	hide_edit_window()

# =================================================
# PENCERE YÖNETİMİ VE ANA KAYIT 💾
# =================================================
func hide_avatar_window():
	# 🔴 KRİTİK EKLEME: Pencere kapanırken karakteri kaydet
	if not Globals.cache.has("user"): 
		Globals.cache["user"] = {}
	
	# Geçici olarak seçilen ID'yi asıl kayıt yerine yazıyoruz
	Globals.cache["user"]["character_id"] = temp_char_id
	
	# Verileri kalıcı yap
	Globals.mark_dirty()
	Globals.save_cache()
	
	print("💾 [AVATAR] Karakter kalıcı olarak seçildi: ", temp_char_id)
	
	# Diğer UI elemanlarını (Sol üst ikon vb.) uyar
	if Globals.has_signal("data_updated"):
		Globals.emit_signal("data_updated")
	
	# Sol üst köşedeki ikonu anında güncellemek için hiyerarşiyi tara
	_trigger_main_ui_update()
	
	self.visible = false

func _trigger_main_ui_update():
	var p = get_parent()
	while p:
		if p.has_method("update_top_left_ui"):
			p.update_top_left_ui()
			break
		p = p.get_parent()

func show_edit_window():
	update_ui_from_cache()
	edit_window.visible = true

func hide_edit_window():
	edit_window.visible = false

# =================================================
# TARİH YARDIMCILARI (Aynı kalıyor)
# =================================================
func _setup_date_dropdowns():
	if opt_day:
		opt_day.clear()
		for i in range(1, 32): opt_day.add_item(str(i))
	if opt_month:
		opt_month.clear()
		var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
		for m in months: opt_month.add_item(m)
	if opt_year:
		opt_year.clear()
		for i in range(1950, 2026): opt_year.add_item(str(i))

func _get_date_string_from_selectors() -> String:
	var d = "01"
	if opt_day: d = opt_day.get_item_text(opt_day.selected).pad_zeros(2)
	var m = "01"
	if opt_month: m = str(opt_month.selected + 1).pad_zeros(2)
	var y = "2000"
	if opt_year: y = opt_year.get_item_text(opt_year.selected)
	return "%s-%s-%s" % [y, m, d]

func _set_date_selectors(date_str: String):
	var parts = date_str.split("-")
	if parts.size() == 3:
		var y = int(parts[0]); var m = int(parts[1]); var d = int(parts[2])
		if opt_year:
			for i in range(opt_year.item_count):
				if int(opt_year.get_item_text(i)) == y: opt_year.select(i); break
		if opt_month: opt_month.select(m - 1)
		if opt_day: opt_day.select(d - 1)
