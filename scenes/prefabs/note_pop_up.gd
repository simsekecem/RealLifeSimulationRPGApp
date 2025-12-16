extends PopupPanel

@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel
@onready var text_edit = $MarginContainer/VBoxContainer/TextEdit
@onready var exit_button = $MarginContainer/VBoxContainer/HBoxContainer/ExitBtn

# Şu an hangi tarihi düzenliyoruz?
var current_date_str: String = ""

func _ready():
	self.set_exclusive(true)
	exit_button.pressed.connect(_on_exit_pressed)
	# Yazarken anlık kaydetmek istersen bunu açabilirsin:
	# text_edit.text_changed.connect(_on_text_changed)

func open_for_date(date):
	# Tarihi veritabanı formatına (YYYY-MM-DD) çevir
	current_date_str = "%04d-%02d-%02d" % [date.year, date.month, date.day]
	
	# Başlığı güncelle (GG.AA.YYYY)
	title_label.text = "%02d.%02d.%04d" % [date.day, date.month, date.year]
	
	# Eski notu yükle (Yoksa boş gelir)
	text_edit.text = _get_note_from_cache(current_date_str)

	popup_centered()
	
	# Klavyeyi açması için bir kare bekle
	await get_tree().process_frame
	text_edit.grab_focus()

func _on_exit_pressed():
	_save_note_to_cache()
	hide()

# İsteğe bağlı: Anlık kayıt
func _on_text_changed():
	_save_note_to_cache()

# ============================================================
#  VERİ İŞLEMLERİ
# ============================================================

func _get_note_from_cache(date_key: String) -> String:
	var notes_list = Globals.ensure_list(Globals.cache.get("calendar_notes", []))
	for entry in notes_list:
		if typeof(entry) == TYPE_DICTIONARY and Globals.safe_str(entry.get("date", "")) == date_key:
			return Globals.safe_str(entry.get("note", ""))
	return ""

func _save_note_to_cache():
	if current_date_str == "": return
	
	# 👇 ÖNEMLİ: Boş olsa bile alıyoruz ("")
	var new_note = text_edit.text 
	
	var notes_list = Globals.ensure_list(Globals.cache.get("calendar_notes", []))
	Globals.cache["calendar_notes"] = notes_list
	
	var found = false
	for i in range(notes_list.size()):
		var entry = notes_list[i]
		if typeof(entry) == TYPE_DICTIONARY and Globals.safe_str(entry.get("date", "")) == current_date_str:
			# Varsa güncelle (Boş string olsa bile günceller)
			notes_list[i]["note"] = new_note
			found = true
			break
	
	# Yoksa yeni ekle
	if not found:
		notes_list.append({ "date": current_date_str, "note": new_note })
	
	# Değişikliği bildir
	Globals.mark_dirty()
