extends Control

# Tarih seçiciler
@onready var year_select: OptionButton = $TabContainer/Daily/HBoxContainer/YearSelect 
@onready var month_select: OptionButton = $TabContainer/Daily/HBoxContainer/MonthSelect
@onready var day_select: OptionButton = $TabContainer/Daily/HBoxContainer/DaySelect

# Gym alanı
@onready var add_button: Button = $TabContainer/Daily/AddButton
@onready var exercise_list: VBoxContainer = $TabContainer/Daily/ListArea/ScrollContainer/ContentList
@export var exercise_row_scene: PackedScene = preload("res://scenes/prefabs/DailyExerciseRow.tscn")

@export var weekly_exercise_row_scene: PackedScene = preload("res://scenes/prefabs/WeeklyExerciseRow.tscn")
@onready var monday_exercises_list: HBoxContainer = $TabContainer/Weekly/VBoxContainer/MondayRow/ScrollContainer/ExercisesRow

var weekly_data = {
	"Monday": [
		{"name":"Push Ups", "duration":"10 min"},
		{"name":"Squats", "duration":"15 min"},
		{"name":"Plank", "duration":"5 min"}
	]
}


func _ready():
	fill_years()
	fill_months()
	update_days()
	load_weekly_day("Monday")

	month_select.item_selected.connect(_on_month_changed)
	year_select.item_selected.connect(_on_year_changed)

	add_button.pressed.connect(_on_add_button_pressed)


# --------------------------
# GYM – Satır Ekleme
# --------------------------
func _on_add_button_pressed():
	var row = exercise_row_scene.instantiate()

	# Delete button bağlama
	row.get_node("DeleteButton").pressed.connect(
		func():
			row.queue_free()
	)

	exercise_list.add_child(row)



# --------------------------
# Tarih Kodların (Senin Kodun)
# --------------------------

func fill_years():
	year_select.clear()

	var current_year = Time.get_datetime_dict_from_system().year
	for y in range(current_year - 5, current_year + 6):
		year_select.add_item(str(y))
	
	year_select.select(5)


func fill_months():
	month_select.clear()

	var months = [
		"January", "February", "March", "April",
		"May", "June", "July", "August",
		"September", "October", "November", "December"
	]

	for m in months:
		month_select.add_item(m)


func _on_month_changed(index: int):
	update_days()

func _on_year_changed(index: int):
	update_days()


func update_days():
	if month_select.get_item_count() == 0 or year_select.get_item_count() == 0:
		return

	day_select.clear()

	var month = month_select.get_selected_id() + 1
	var year = int(year_select.get_item_text(year_select.get_selected_id()))

	var days_in_month = get_days_in_month(month, year)

	for d in range(1, days_in_month + 1):
		day_select.add_item(str(d))


func get_days_in_month(month: int, year: int) -> int:
	match month:
		1, 3, 5, 7, 8, 10, 12:
			return 31
		4, 6, 9, 11:
			return 30
		2:
			return 29 if is_leap_year(year) else 28
	return 30


func is_leap_year(year: int) -> bool:
	return (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)
func load_weekly_day(day_name: String):
	var list_container: HBoxContainer = monday_exercises_list  # veya match ile diğer günleri seç
	# Önce eski satırları temizle
	for child in list_container.get_children():
		child.queue_free()
	# Yeni satırları ekle
	if weekly_data.has(day_name):
		for ex in weekly_data[day_name]:
			var row = weekly_exercise_row_scene.instantiate()
			row.get_node("ExerciseName").text = ex["name"]
			row.get_node("Duration").text = ex["duration"]
			list_container.add_child(row)
