extends Panel

@onready var hbox = $HBoxContainer
@onready var hour_label = $HBoxContainer/HourLabel
@onready var task_textedit = $HBoxContainer/TaskTextEdit

func _ready():
	# Set root Panel fixed dimensions
	custom_minimum_size = Vector2(500, 70)
