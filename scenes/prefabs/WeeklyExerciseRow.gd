extends VBoxContainer
class_name WeeklyExerciseRow

const GREEN = Color("26a35b")
const RED = Color("cf2f1d")
const NORMAL = Color("5c586b")



@onready var label_name = $ExerciseName
@onready var label_duration = $Duration



func setup_row(ex_name: String, duration: String, is_completed: bool, is_past_date: bool):
	label_name.text = ex_name
	label_duration.text = duration

	var color := NORMAL

	if is_completed:
		color = GREEN
	elif is_past_date:
		color = RED

	label_name.add_theme_color_override("font_color", color)
	label_duration.add_theme_color_override("font_color", color)
