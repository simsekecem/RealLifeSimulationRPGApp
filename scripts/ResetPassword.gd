extends "res://scripts/AuthBase.gd"

@onready var email_field = $NinePatchRect/LineEdit
@onready var reset_button = $NinePatchRect/Reset_Button
@onready var back_button = $NinePatchRect/BackButton
@onready var message_label = $NinePatchRect/ResetMessageLabel
@onready var http = $HTTPRequest

func _ready():
	if UI.has_node("UIRoot"):
		UI.get_node("UIRoot").hide_all_ui()
		
	reset_button.pressed.connect(_on_reset_pressed)
	back_button.pressed.connect(_on_back_pressed)
	http.request_completed.connect(_on_request_completed)
	
	# Hide initially
	message_label.visible = false

func _on_reset_pressed() -> void:
	# Hide previous message on new attempt
	message_label.visible = false
	
	var body = { "email": email_field.text }
	send_request(http, "/api/password-recover", body)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/auth_screen.tscn")

func _on_request_completed(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	# Parse JSON response from server
	var json = JSON.parse_string(body.get_string_from_utf8())

	if code == 200:
		# --- SUCCESS STATE ---
		print("Password reset email sent.")
		message_label.text = "If an account with that email exists,\nwe've sent password reset instructions."
		message_label.visible = true
		
	else:
		# --- ERROR STATE ---
		print("Reset failed:", json)
		
		var error_msg = "An error occurred."
		
		# Handle error codes
		if json:
			# 1. Rate limited
			if code == 429:
				error_msg = "Too many requests. Please wait a bit."
				
			# 2. Invalid email format
			elif json.has("error_code") and (json["error_code"] == "email_address_invalid" or json["error_code"] == "validation_failed"):
				error_msg = "Please enter a valid email address."
				
			# 3. User not found
			elif json.has("error_code") and json["error_code"] == "user_not_found":
				error_msg = "User not found."
				
			# 4. General error message
			elif json.has("msg"):
				error_msg = str(json["msg"])
			elif json.has("error_description"):
				error_msg = str(json["error_description"])
		
		# Display message on UI
		message_label.text = error_msg
		message_label.visible = true
