extends "res://scripts/AuthBase.gd"

@onready var email_field = $NinePatchRect/EmailLineEdit
@onready var password_field = $NinePatchRect/PasswordLineEdit
@onready var login_button = $NinePatchRect/Login_Button
@onready var acc_button = $NinePatchRect/Acc_Button
@onready var forgot_label = $NinePatchRect/ForgotPasswordLabel
@onready var http = $HTTPRequest

func _ready():
	UI.get_node("UIRoot").hide_all_ui()
	login_button.pressed.connect(_on_login_pressed)
	acc_button.pressed.connect(_on_acc_pressed)
	http.request_completed.connect(_on_request_completed)

	forgot_label.gui_input.connect(_on_forgot_label_input)

func _on_login_pressed() -> void:
	var body = {
		"email": email_field.text,
		"password": password_field.text
	}
	send_request(http, "/api/login", body)

func _on_request_completed(_result: int, _code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var data = JSON.parse_string(body.get_string_from_utf8())
	if data == null:
		print("❌ Invalid JSON response")
		return

	if data.has("access_token"):
		Globals.auth_token = data["access_token"]
		Globals.user_id = data["user_id"]
		print("✅ Login başarılı:", Globals.user_id)
		get_tree().change_scene_to_file("res://scenes/Main.tscn")
	else:
		print("❌ Login failed:", data)


		
func _on_acc_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/authscreen_signup.tscn")

func _on_forgot_label_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		get_tree().change_scene_to_file("res://scenes/authscreen_forgotps.tscn")
