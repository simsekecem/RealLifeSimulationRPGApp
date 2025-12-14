extends Control

@export var hour_row_scene: PackedScene = preload("res://scenes/prefabs/StudyHoursRow.tscn")

@onready var day_buttons = [
	$DaysPanel/MondayButton, $DaysPanel/TuesdayButton, $DaysPanel/WednesdayButton,
	$DaysPanel/ThursdayButton, $DaysPanel/FridayButton, $DaysPanel/SaturdayButton, $DaysPanel/SundayButton
]
@onready var hours_list = $HoursPanel/ScrollContainer/HoursList
@onready var back_button = $BackButton

var current_selected_button: Button = null
var current_week_monday_unix: int = 0

func _ready():
	back_button.pressed.connect(_on_back_button_pressed)
	if UI.has_node("UIRoot"): UI.get_node("UIRoot").show_only_top_right_buttons()
	
	calculate_current_week()

	for i in range(day_buttons.size()):
		var button = day_buttons[i]
		button.toggled.connect(_on_day_button_toggled.bind(button, i))

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

# ============================================================
#  GÜVENLİ VERİ KAYDETME (ARTIK GLOBALS HELPER KULLANIYOR)
# ============================================================
func save_study_data(date: String, hour: int, subject: String):
	
	# 1. Helper ile veriyi garanti temizle
	var log_list = Globals.ensure_list(Globals.cache["study_log"])
	
	# Globals'ı güncelle (Referansın kaybolmaması için)
	Globals.cache["study_log"] = log_list
	
	var found = false
	for i in range(log_list.size()):
		var entry = log_list[i]
		if typeof(entry) != TYPE_DICTIONARY: continue
		
		# Helper fonksiyonlarla karşılaştırma
		if Globals.safe_str(entry.get("date", "")) == date and Globals.safe_int(entry.get("start_time", -1)) == hour:
			Globals.cache["study_log"][i]["subject"] = subject
			found = true
			break
	
	if not found:
		Globals.cache["study_log"].append({ "date": date, "start_time": hour, "end_time": hour + 1, "subject": subject })
	
	Globals.mark_dirty()

# ============================================================
#  GÜVENLİ VERİ ÇEKME (ARTIK GLOBALS HELPER KULLANIYOR)
# ============================================================
func get_study_data(target_date: String, target_hour: int) -> String:
	
	# Helper ile veriyi temiz al
	var log_list = Globals.ensure_list(Globals.cache["study_log"])
	
	for entry in log_list:
		if typeof(entry) != TYPE_DICTIONARY: continue
		
		# Helper fonksiyonlarla güvenli karşılaştırma
		if Globals.safe_str(entry.get("date", "")) == target_date and Globals.safe_int(entry.get("start_time", -1)) == target_hour:
			return Globals.safe_str(entry.get("subject", ""))
			
	return ""

func _on_back_button_pressed():
	Globals.save_cache()
	if UI.has_node("UIRoot"): UI.get_node("UIRoot").return_to_town()
