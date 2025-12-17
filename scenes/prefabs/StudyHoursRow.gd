extends Panel

@onready var hbox = $HBoxContainer
@onready var hour_label = $HBoxContainer/HourLabel
@onready var task_textedit = $HBoxContainer/TaskTextEdit

func _ready():
	# Sadece root Panel genişliği sabit
	custom_minimum_size = Vector2(500, 70)  # Width = 862, Height = 40
