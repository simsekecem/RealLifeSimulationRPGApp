extends Control

@export var hour_row_scene: PackedScene = preload("res://scenes/prefabs/StudyHoursRow.tscn")

# ============================================================
#  NODE REFERENCES
# ============================================================

# --- LEFT PANEL (BOOK LIST) ---
@onready var input_reading = $Panel/BooksPanel/CurrentlyReading
@onready var input_completed = $Panel/BooksPanel/Finished
@onready var input_wishlist = $Panel/BooksPanel/Wishlist

# --- RIGHT PANEL (STUDY HOURS) ---
@onready var day_buttons = [
	$DaysPanel/MondayButton, $DaysPanel/TuesdayButton, $DaysPanel/WednesdayButton,
	$DaysPanel/ThursdayButton, $DaysPanel/FridayButton, $DaysPanel/SaturdayButton, $DaysPanel/SundayButton
]
@onready var hours_list = $HoursPanel/ScrollContainer/PanelContainer/HoursList
@onready var back_button = $BackButton

var current_selected_button: Button = null
var current_week_monday_unix: int = 0

# ============================================================
#  INITIALIZATION
# ============================================================
func _ready():
	# UI Settings
	back_button.pressed.connect(_on_back_button_pressed)
	if UI.has_node("UIRoot"): UI.get_node("UIRoot").show_only_top_right_buttons()
	
	# --- RIGHT PANEL (HOURS) ---
	calculate_current_week()
	for i in range(day_buttons.size()):
		var button = day_buttons[i]
		button.toggled.connect(_on_day_button_toggled.bind(button, i))

	# --- LEFT PANEL (BOOKS) ---
	# 1. Load saved data and populate input boxes
	load_books_to_ui()
	
	# 2. Save immediately if text changes
	if input_reading: input_reading.text_changed.connect(_on_book_list_changed)
	if input_completed: input_completed.text_changed.connect(_on_book_list_changed)
	if input_wishlist: input_wishlist.text_changed.connect(_on_book_list_changed)

# ============================================================
#  BOOK LIST MANAGEMENT (LEFT PANEL)
# ============================================================

func load_books_to_ui():
	var all_books = Globals.ensure_list(Globals.cache.get("library", []))
	
	var list_reading = []
	var list_completed = []
	var list_wishlist = []
	
	# Track seen books to prevent duplicate display
	var seen_books = [] 

	for book in all_books:
		var title = Globals.safe_str(book.get("title", ""))
		var status = Globals.safe_str(book.get("status", "reading"))
		
		# Generate fingerprint (Title + Status)
		var fingerprint = title + "|" + status
		
		# Skip if book in this category has already been processed
		if title != "" and fingerprint in seen_books:
			continue
		
		if title != "":
			seen_books.append(fingerprint)

		if status == "reading": list_reading.append(title)
		elif status == "completed": list_completed.append(title)
		elif status == "wishlist": list_wishlist.append(title)
	
	# Populate UI with clean deduplicated lists
	if input_reading: input_reading.text = "\n".join(list_reading)
	if input_completed: input_completed.text = "\n".join(list_completed)
	if input_wishlist: input_wishlist.text = "\n".join(list_wishlist)

# ============================================================
#  BOOK LIST MANAGEMENT (COLLISION-PROTECTED)
# ============================================================

func _on_book_list_changed():
	var new_library_list = []
	
	# Shared lookup of titles across all categories to prevent duplicate assignment
	var global_seen_titles = {} 
	
	# Process categories in priority order: Reading -> Completed -> Wishlist
	_parse_text_edit_to_list(input_reading, "reading", new_library_list, global_seen_titles)
	_parse_text_edit_to_list(input_completed, "completed", new_library_list, global_seen_titles)
	_parse_text_edit_to_list(input_wishlist, "wishlist", new_library_list, global_seen_titles)
	
	Globals.cache["library"] = new_library_list
	Globals.mark_dirty()
	# Trigger quest action when book list is updated
	if has_node("/root/QuestManager"):
		QuestManager.trigger_action("study_action")
		QuestManager.trigger_action("first_library")

func _parse_text_edit_to_list(text_edit: TextEdit, status: String, target_list: Array, seen_map: Dictionary):
	if not text_edit: return
	
	var lines = text_edit.text.split("\n")

	# Map existing IDs to preserve them
	var existing_ids = {}
	var old_library = Globals.cache.get("library", [])
	for item in old_library:
		if item.has("title") and item.has("id"):
			existing_ids[item["title"]] = item["id"]

	for line in lines:
		var clean_line = line.strip_edges()
		
		if clean_line != "":
			# Skip if title already added in another category
			if seen_map.has(clean_line):
				continue
			
			seen_map[clean_line] = true
			
			var book_data = { 
				"title": clean_line, 
				"status": status 
			}
			
			# Preserve existing ID if present
			if existing_ids.has(clean_line):
				book_data["id"] = existing_ids[clean_line]
			
			target_list.append(book_data)
# ============================================================
#  STUDY HOURS (RIGHT PANEL)
# ============================================================

func calculate_current_week():
	var date_dict = Time.get_datetime_dict_from_system()
	var now_unix = Time.get_unix_time_from_datetime_dict(date_dict)
	var days_to_subtract = date_dict.weekday - 1
	current_week_monday_unix = now_unix - (days_to_subtract * 86400)

func get_date_string_for_index(day_index: int) -> String:
	return Time.get_date_string_from_unix_time(current_week_monday_unix + (day_index * 86400))

func _on_day_button_toggled(pressed: bool, clicked_button: Button, day_index: int):
	if pressed:
		if current_selected_button != null and current_selected_button != clicked_button:
			current_selected_button.button_pressed = false
		current_selected_button = clicked_button
		load_hours_for_day(get_date_string_for_index(day_index))
	else:
		if clicked_button == current_selected_button: current_selected_button = null
		clear_hours()

func load_hours_for_day(date_string: String):
	clear_hours()
	for h in range(9, 24):
		var row = hour_row_scene.instantiate()
		row.get_node("HBoxContainer/HourLabel").text = "\n %02d:00 - %02d:00" % [h, h+1]
		
		var text_edit = row.get_node("HBoxContainer/TaskTextEdit")
		text_edit.text = get_study_data(date_string, h)
		
		if text_edit.has_signal("text_changed"):
			text_edit.text_changed.connect(_on_task_text_changed.bind(text_edit, date_string, h))
			
		hours_list.add_child(row)

func clear_hours():
	for child in hours_list.get_children(): child.queue_free()

func _on_task_text_changed(text_node, date_string, hour):
	save_study_data(date_string, hour, text_node.text)

func save_study_data(date: String, hour: int, subject: String):
	var log_list = Globals.ensure_list(Globals.cache.get("study_log", []))
	Globals.cache["study_log"] = log_list
	
	var found = false
	for i in range(log_list.size()):
		var entry = log_list[i]
		if typeof(entry) != TYPE_DICTIONARY: continue
		if Globals.safe_str(entry.get("date", "")) == date and Globals.safe_int(entry.get("start_time", -1)) == hour:
			Globals.cache["study_log"][i]["subject"] = subject
			found = true
			break
	
	if not found:
		Globals.cache["study_log"].append({ "date": date, "start_time": hour, "end_time": hour + 1, "subject": subject })
	
	Globals.mark_dirty()
	# Trigger quest action whenever a study subject is written
	if subject.strip_edges() != "" and has_node("/root/QuestManager"):
		QuestManager.trigger_action("study_action")
		QuestManager.trigger_action("first_library")

func get_study_data(target_date: String, target_hour: int) -> String:
	var log_list = Globals.ensure_list(Globals.cache.get("study_log", []))
	for entry in log_list:
		if typeof(entry) != TYPE_DICTIONARY: continue
		if Globals.safe_str(entry.get("date", "")) == target_date and Globals.safe_int(entry.get("start_time", -1)) == target_hour:
			return Globals.safe_str(entry.get("subject", ""))
	return ""

func _on_back_button_pressed():
	Globals.save_cache()
	# Trigger quest action on exit if data exists
	if has_node("/root/QuestManager"):
		var lib_size = Globals.cache.get("library", []).size()
		var study_size = Globals.cache.get("study_log", []).size()
		if lib_size > 0 or study_size > 0:
			QuestManager.trigger_action("study_action")
			QuestManager.trigger_action("first_library")
	if UI.has_node("UIRoot"): UI.get_node("UIRoot").return_to_town()


func _on_texture_button_pressed() -> void:
	$ChatPopup_L.visible = true
	$ChatPopup_L/MainWindow/InputField.grab_focus()
