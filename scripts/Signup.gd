extends "res://scripts/AuthBase.gd"

@onready var email_field = $NinePatchRect/Email_LineEdit
@onready var password_field = $NinePatchRect/Password_LineEdit
@onready var signup_button = $NinePatchRect/Signup_Button
@onready var http = $HTTPRequest

func _ready():
	UI.get_node("UIRoot").hide_all_ui()
	signup_button.pressed.connect(_on_signup_pressed)
	http.request_completed.connect(_on_request_completed)

func _on_signup_pressed() -> void:
	var body = {
		"email": email_field.text,
		"password": password_field.text
	}
	send_request(http, "/api/signup", body)

func _on_request_completed(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var data = JSON.parse_string(body.get_string_from_utf8())

	if code == 200:
		print("✅ Signup successful. Check your email for confirmation.")
		get_tree().change_scene_to_file("res://scenes/authscreen_login.tscn")
	else:
		print("❌ Signup failed:", data)
