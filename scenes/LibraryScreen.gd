extends Control

@export var hour_row_scene: PackedScene = preload("res://scenes/prefabs/StudyHoursRow.tscn")

@onready var monday_button = $DaysPanel/MondayButton
@onready var hours_list = $HoursPanel/ScrollContainer/HoursList

func _ready():
	monday_button.toggled.connect(_on_monday_toggled)

func _on_monday_toggled(pressed: bool):
	if pressed:
		load_hours_for_day("Monday")  # aç
	else:
		clear_hours()  # kapat


func load_hours_for_day(_day: String):
	clear_hours()

	var start_hour = 9
	var end_hour = 24

	for h in range(start_hour, end_hour):
		var row = hour_row_scene.instantiate()
		var label = row.get_node("HBoxContainer/HourLabel")
		var textedit = row.get_node("HBoxContainer/TaskTextEdit")
		label.text = "\n %02d:00 - %02d:00" % [h, h+1]
		textedit.text = ""
		hours_list.add_child(row)


func clear_hours():
	for child in hours_list.get_children():
		child.queue_free()
