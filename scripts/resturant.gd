extends Control

# =================================================
# NODE REFERENCES
# =================================================
# Notes edit box (left/bottom)
@onready var notes_edit: TextEdit = $NinePatchRect/TextEdit

# Meals panel (right side)
@onready var meal_panel: Control = $MealPanel 

# Meal input fields
@onready var input_fields := {
	"breakfast": $MealPanel/ScrollContainer/MealList/Breakfast_Panel/TextEdit,
	"lunch":     $MealPanel/ScrollContainer/MealList/Lunch_Panel/TextEdit,
	"dinner":    $MealPanel/ScrollContainer/MealList/Dinner_Panel/TextEdit,
	"snacks":    $MealPanel/ScrollContainer/MealList/Snakcs_Panel/TextEdit 
}

# Day buttons
@onready var day_buttons := {
	"Monday":    $M_Button, "Tuesday":   $TU_Button, "Wednesday": $W_Button,
	"Thursday":  $T_Button, "Friday":    $F_Button, "Saturday":  $SA_Button,
	"Sunday":    $S_Button
}

@onready var back_button: BaseButton = $Back_Button 

# Currently selected date (String format: "YYYY-MM-DD")
var current_day: String = "" 

# Numerical values of days for date calculation
var day_indices = {
	"Monday": 1, "Tuesday": 2, "Wednesday": 3,
	"Thursday": 4, "Friday": 5, "Saturday": 6,
	"Sunday": 7
}

# =================================================
# INITIALIZATION
# =================================================
func _ready():
	# 1. Hide everything initially
	if meal_panel: meal_panel.visible = false
	if notes_edit: notes_edit.visible = false
	
	if back_button: back_button.pressed.connect(_on_back_button_pressed)
	
	# Connect day buttons
	for day_name in day_buttons.keys():
		var btn = day_buttons[day_name]
		if btn:
			btn.toggle_mode = true
			# Send day name (e.g. "Monday") on click
			btn.pressed.connect(_on_day_button_pressed.bind(day_name))

	# Connect meal inputs - save on text change
	for field_key in input_fields.keys():
		var edit = input_fields[field_key]
		if edit:
			if not edit.text_changed.is_connected(_on_meal_text_changed.bind(field_key, edit)):
				edit.text_changed.connect(_on_meal_text_changed.bind(field_key, edit))

	# Connect notes input
	if notes_edit and not notes_edit.text_changed.is_connected(_on_notes_changed):
		notes_edit.text_changed.connect(_on_notes_changed)

# =================================================
# DAY SELECTION
# =================================================
func _on_day_button_pressed(selected_day_name: String):
	# 1. Convert button day name ("Monday") to concrete date ("YYYY-MM-DD")
	var real_date = get_date_string_for_day(selected_day_name)
	
	# Skip reloading if already viewing that day and panel is open
	if current_day == real_date and meal_panel.visible: return

	# 2. Update current date
	current_day = real_date
	print("📅 Day button: ", selected_day_name, " -> Date: ", current_day)
	
	# 3. Make panels visible
	if meal_panel: meal_panel.visible = true
	if notes_edit: 
		notes_edit.visible = true
		notes_edit.editable = true

	# Update button toggle states (only active day pressed)
	for d_name in day_buttons.keys():
		if day_buttons[d_name]:
			day_buttons[d_name].set_pressed_no_signal(d_name == selected_day_name)

	# 4. Load data from cache and populate inputs
	var day_data = _get_data_for_day(current_day)
	_set_inputs_quietly(day_data)
	

# =================================================
# DATE CALCULATION
# =================================================
func get_date_string_for_day(day_name: String) -> String:
	# 1. Get system date
	var today_dict = Time.get_date_dict_from_system()
	var current_unix = Time.get_unix_time_from_datetime_dict(today_dict)
	
	# 2. Weekday of today (Mon=1 ... Sun=7)
	var current_weekday = today_dict.weekday
	if current_weekday == 0: current_weekday = 7
	
	# 3. Target weekday index (e.g. Monday = 1)
	var target_weekday = day_indices.get(day_name, 1)
	
	# 4. Calculate day difference
	var diff_days = target_weekday - current_weekday
	
	# 5. Add difference in seconds to unix timestamp
	var target_unix = current_unix + (diff_days * 86400)
	
	# 6. Format new date to string (YYYY-MM-DD)
	var target_date_dict = Time.get_date_dict_from_unix_time(target_unix)
	return "%04d-%02d-%02d" % [target_date_dict.year, target_date_dict.month, target_date_dict.day]

# =================================================
# POPULATE UI (SILENT)
# =================================================
func _set_inputs_quietly(data: Dictionary):
	# Fill meals
	for field in input_fields.keys():
		var edit = input_fields[field]
		if edit:
			edit.text = Globals.safe_str(data.get(field, ""))
	
	# Fill notes
	if notes_edit:
		notes_edit.text = Globals.safe_str(data.get("notes", ""))

# =================================================
# DATA PERSISTENCE
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
			# Update field in existing record
			list[i][field] = value
			found = true
			break
	
	if not found:
		# Create a new record for this date if none exists
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
	# Trigger quest action when non-empty value is provided
	if value.strip_edges() != "" and has_node("/root/QuestManager"):
		QuestManager.trigger_action("eat_action")
		QuestManager.trigger_action("first_restaurant")

# =================================================
# SIGNALS
# =================================================
func _on_meal_text_changed(field_key: String, edit_node: TextEdit):
	if meal_panel.visible:
		_save_data(field_key, edit_node.text)

func _on_notes_changed():
	if meal_panel.visible: 
		_save_data("notes", notes_edit.text)

func _on_back_button_pressed():
	Globals.save_cache()
	# Trigger quest action if restaurant list contains data
	if has_node("/root/QuestManager"):
		var rest_list = Globals.cache.get("restaurant", [])
		if rest_list.size() > 0:
			QuestManager.trigger_action("eat_action")
			QuestManager.trigger_action("first_restaurant")
	if UI.has_node("UIRoot"): UI.get_node("UIRoot").return_to_town()

func _on_texture_button_pressed() -> void:
	$ChatPopup_R.visible = true
	$ChatPopup_R/MainWindow/InputField.grab_focus()
