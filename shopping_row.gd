extends HBoxContainer

signal request_new_item

@onready var name_field: LineEdit = $ItemEdit
@onready var checkbox: CheckBox = $ItemCheck

func _ready():
	name_field.connect("text_submitted", Callable(self, "_on_submit"))
	checkbox.connect("toggled", Callable(self, "_on_check_toggled"))

func _on_submit(text: String) -> void:
	emit_signal("request_new_item")

func _on_check_toggled(checked: bool) -> void:
	if checked:
		# CHECK → yazı rengi 496580
		name_field.set("theme_override_colors/font_color", Color("#496580"))
	else:
		# UNCHECK → beyaz
		name_field.set("theme_override_colors/font_color", Color.WHITE)
