extends HBoxContainer
class_name DailyExerciseRow

signal delete_requested(row_node)

@onready var checkbox_completed = $BoxContainer/Completed
@onready var input_name = $ExerciseName
@onready var input_sets = $Sets
@onready var input_reps = $Reps
@onready var input_duration = $Duration
@onready var input_rest = $Rest
@onready var input_weight = $Weight
@onready var input_region = $Region
@onready var btn_delete = $DeleteButton

var regions_list = [
	"Chest","Back","Legs","Arms","Shoulders",
	"Abs","Cardio","Full Body","Stretching"
]

# 👇 YENİ: ID değişkeni
var record_id = null

func _ready():
	btn_delete.pressed.connect(_on_delete_pressed)
	fill_regions()

func _on_delete_pressed():
	emit_signal("delete_requested", self)

func fill_regions():
	input_region.clear()
	for r in regions_list:
		input_region.add_item(r)

# ---------------- LOAD ----------------
func set_data(data: Dictionary):
	# 👇 YENİ: ID'yi hafızaya al
	if data.has("id"):
		record_id = data["id"]
	
	if data.has("completed"): checkbox_completed.button_pressed = data.completed
	if data.has("exercise_name"): input_name.text = str(data.exercise_name)
	if data.has("sets"): input_sets.value = float(data.sets)
	if data.has("reps"): input_reps.value = float(data.reps)
	if data.has("duration"): input_duration.value = float(data.duration)
	if data.has("rest"): input_rest.value = float(data.rest)
	if data.has("weight"): input_weight.value = float(data.weight)

	if data.has("region"):
		for i in range(input_region.item_count):
			if input_region.get_item_text(i) == str(data.region):
				input_region.select(i)
				break

# ---------------- SAVE ----------------
func get_data() -> Dictionary:
	var region_val := ""
	if input_region.selected >= 0:
		region_val = input_region.get_item_text(input_region.selected)
		if region_val == "Select Region":
			region_val = ""

	var data = {
		"completed": checkbox_completed.button_pressed,
		"exercise_name": input_name.text,
		"sets": input_sets.value,
		"reps": input_reps.value,
		"duration": input_duration.value,
		"rest": input_rest.value,
		"weight": input_weight.value,
		"region": region_val
	}
	
	# 👇 YENİ: ID varsa pakete koy
	if record_id != null:
		data["id"] = record_id
		
	return data
