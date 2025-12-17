extends "res://scripts/AuthBase.gd"

@onready var email_field = $NinePatchRect/Email_LineEdit
@onready var password_field = $NinePatchRect/Password_LineEdit
@onready var signup_button = $NinePatchRect/Signup_Button
@onready var back_button = $NinePatchRect/BackButton
@onready var http = $HTTPRequest

# 👇 YENİ: Başarılı mesajı etiketi (İsmi sahnendekiyle aynı olmalı)
@onready var email_send_label = $NinePatchRect/EmailSendLabel

func _ready():
	if UI.has_node("UIRoot"):
		UI.get_node("UIRoot").hide_all_ui()
	
	# 👇 YENİ: Başlangıçta gizle
	if email_send_label:
		email_send_label.visible = false
		
	signup_button.pressed.connect(_on_signup_pressed)
	back_button.pressed.connect(_on_back_pressed)
	http.request_completed.connect(_on_request_completed)

func _on_signup_pressed() -> void:
	# Yeni deneme yaparken eski mesajı gizle
	if email_send_label:
		email_send_label.visible = false
		
	var body = {
		"email": email_field.text,
		"password": password_field.text
	}
	send_request(http, "/api/signup", body)
	
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/auth_screen.tscn")

func _on_request_completed(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var data = JSON.parse_string(body.get_string_from_utf8())

	# Eğer etiket yoksa hata vermesin diye kontrol
	if email_send_label:
		email_send_label.visible = false

	if code == 200:
		print("✅ Signup successful.")
		
		if email_send_label:
			# --- BAŞARILI DURUM (YEŞİL) ---
			email_send_label.text = "You're almost there! We’ve sent you an email with a confirmation link.\nCheck your inbox (and spam folder just in case) to activate your account."
			email_send_label.visible = true
			
	else:
		print("❌ Signup failed:", data)
		
		var error_msg = "Signup failed."
		
		# 1. 👇 SENİN İSTEDİĞİN: Geçersiz Email Hatası
		if data.has("error_code") and data["error_code"] == "email_address_invalid":
			error_msg = "Please enter a valid email address."
			
		# 2. Şifre Çok Kısa Hatası (Supabase genelde 6 karakter ister)
		elif data.has("error_code") and data["error_code"] == "weak_password":
			error_msg = "Password should be at least 6 characters."

		# 3. Kullanıcı Zaten Varsa (User already registered)
		elif data.has("msg") and "already registered" in str(data["msg"]):
			error_msg = "This email is already registered."

		# 4. Diğer Hatalar
		elif data.has("msg"):
			error_msg = str(data["msg"])
		
		if email_send_label:
			# --- HATA DURUMU (KIRMIZI) ---
			email_send_label.text = error_msg
			email_send_label.visible = true
