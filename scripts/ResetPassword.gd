extends "res://scripts/AuthBase.gd"

@onready var email_field = $NinePatchRect/LineEdit
@onready var reset_button = $NinePatchRect/Reset_Button
@onready var back_button = $NinePatchRect/BackButton
@onready var message_label = $NinePatchRect/ResetMessageLabel
@onready var http = $HTTPRequest

func _ready():
	UI.get_node("UIRoot").hide_all_ui()
	reset_button.pressed.connect(_on_reset_pressed)
	back_button.pressed.connect(_on_back_pressed)
	http.request_completed.connect(_on_request_completed)
	message_label.visible = false

func _on_reset_pressed() -> void:
	var body = { "email": email_field.text }
	send_request(http, "/api/password-recover", body)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/auth_screen.tscn")

func _on_request_completed(_result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if code == 200:
		message_label.visible = true
	else:
		message_label.visible = false
		
