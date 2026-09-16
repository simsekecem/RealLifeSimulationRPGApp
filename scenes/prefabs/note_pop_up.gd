extends PopupPanel

@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel
@onready var text_edit = $MarginContainer/VBoxContainer/TextEdit
@onready var exit_button = $MarginContainer/VBoxContainer/HBoxContainer/ExitBtn

# Currently edited date
var current_date_str: String = ""

func _ready():
	self.set_exclusive(true)
	exit_button.pressed.connect(_on_exit_pressed)

func open_for_date(date):
	# Convert date to DB format (YYYY-MM-DD)
	current_date_str = "%04d-%02d-%02d" % [date.year, date.month, date.day]
	
	# Update title (DD.MM.YYYY)
	title_label.text = "%02d.%02d.%04d" % [date.day, date.month, date.year]
	
	# Load existing note from cache
	text_edit.text = _get_note_from_cache(current_date_str)

	popup_centered()
	# Calendar quest trigger
	var q_manager = get_node_or_null("/root/QuestManager")
	if q_manager:
		q_manager.trigger_action("first_calendar")
	# Wait a frame to grab focus
	await get_tree().process_frame
	text_edit.grab_focus()

func _on_exit_pressed():
	_save_note_to_cache()
	hide()

# Optional: Realtime save
func _on_text_changed():
	_save_note_to_cache()

# ============================================================
#  DATA PERSISTENCE
# ============================================================

func _get_note_from_cache(date_key: String) -> String:
	var notes_list = Globals.ensure_list(Globals.cache.get("calendar_notes", []))
	for entry in notes_list:
		if typeof(entry) == TYPE_DICTIONARY and Globals.safe_str(entry.get("date", "")) == date_key:
			return Globals.safe_str(entry.get("note", ""))
	return ""

func _save_note_to_cache():
	if current_date_str == "": return 
	
	# Retrieve text including empty string
	var new_note = text_edit.text 
	
	var notes_list = Globals.ensure_list(Globals.cache.get("calendar_notes", []))
	Globals.cache["calendar_notes"] = notes_list
	
	var found = false
	for i in range(notes_list.size()):
		var entry = notes_list[i]
		if typeof(entry) == TYPE_DICTIONARY and Globals.safe_str(entry.get("date", "")) == current_date_str:
			notes_list[i]["note"] = new_note
			found = true
			break
	
	# Append if not found
	if not found:
		notes_list.append({ "date": current_date_str, "note": new_note })
	
	# Mark cache as dirty for synchronization
	Globals.mark_dirty()
