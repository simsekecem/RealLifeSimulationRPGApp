extends "res://scripts/AuthBase.gd"

@onready var email_field = $EmailLineEdit
@onready var password_field = $PasswordLineEdit
@onready var login_button = $Login_Button
@onready var acc_button = $Acc_Button
@onready var http = $HTTPRequest

func _ready():
	login_button.pressed.connect(_on_login_pressed)
	acc_button.pressed.connect(_on_acc_pressed)
	http.request_completed.connect(_on_request_completed)

# 🔹 Giriş isteği
func _on_login_pressed() -> void:
	var url = SUPABASE_URL + "/auth/v1/token?grant_type=password"
	var body = {
		"email": email_field.text,
		"password": password_field.text
	}
	send_request(http, url, body)

# 🔹 Giriş cevabı
func _on_request_completed(result: int, code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var data = JSON.parse_string(body.get_string_from_utf8())
	if data == null:
		print("❌ Geçersiz yanıt")
		return

	if data.has("access_token"):
		Globals.auth_token = data["access_token"]
		Globals.user_id = data["user"]["id"]
		print("✅ Login başarılı:", Globals.user_id)
		get_tree().change_scene_to_file("res://scenes/Main.tscn")
	else:
		print("⚠️ Login başarısız:", data)

# 🔹 Kayıt ekranına geç
func _on_acc_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/authscreen_signup.tscn")
