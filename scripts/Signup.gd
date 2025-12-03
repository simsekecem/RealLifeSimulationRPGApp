extends "res://scripts/AuthBase.gd"

@onready var email_field = $NinePatchRect/Email_LineEdit
@onready var password_field = $NinePatchRect/Password_LineEdit
@onready var signup_button = $NinePatchRect/Signup_Button
@onready var http = $HTTPRequest

func _ready():
	UI.get_node("UIRoot").hide_all_ui()
	signup_button.pressed.connect(_on_signup_pressed)
	http.request_completed.connect(_on_request_completed)

# 🔹 Kayıt isteği
func _on_signup_pressed() -> void:
	var url = SUPABASE_URL + "/auth/v1/signup"
	var body = {
		"email": email_field.text,
		"password": password_field.text
	}
	send_request(http, url, body)

# 🔹 Kayıt cevabı
func _on_request_completed(result: int, code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var data = JSON.parse_string(body.get_string_from_utf8())
	if data == null:
		print("❌ Geçersiz yanıt")
		return

	if data.has("user"):
		print("✅ Kayıt başarılı! E-postanı kontrol et, onay maili gönderildi.")
		get_tree().change_scene_to_file("res://scenes/authscreen_login.tscn")
	else:
		print("⚠️ Kayıt başarısız:", data)
