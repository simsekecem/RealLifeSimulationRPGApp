extends PopupPanel

@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel
@onready var text_edit = $MarginContainer/VBoxContainer/TextEdit
@onready var exit_button = $MarginContainer/VBoxContainer/HBoxContainer/ExitBtn

var current_date

func _ready():
	self.set_exclusive(true)
	exit_button.pressed.connect(_on_exit_pressed)

func open_for_date(date):
	current_date = date
	title_label.text = "%d.%d.%d" % [date.day, date.month, date.year]
	text_edit.text = ""

	popup_centered()

	# 🔥 BURASI ZORUNLU
	await get_tree().process_frame
	text_edit.grab_focus()


func _on_exit_pressed():
	hide()
