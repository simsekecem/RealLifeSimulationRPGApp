extends "res://scripts/AuthBase.gd"

@onready var email_field = $NinePatchRect/EmailLineEdit
@onready var password_field = $NinePatchRect/PasswordLineEdit
@onready var login_button = $NinePatchRect/Login_Button
@onready var acc_button = $NinePatchRect/Acc_Button
@onready var forgot_label = $NinePatchRect/ForgotPasswordLabel
@onready var http = $HTTPRequest

# 👇 YENİ: Hata mesajı etiketini buraya ekledik
# (Eğer etiketin NinePatchRect'in altında değilse yolu düzeltmelisin)
@onready var error_label = $NinePatchRect/CoudlntLoginLabel 

func _ready():
	# Giriş ekranındayken oyunun UI'ını gizle
	if UI.has_node("UIRoot"):
		UI.get_node("UIRoot").hide_all_ui()
	
	# 👇 YENİ: Başlangıçta hata mesajını gizle
	if error_label:
		error_label.visible = false
		
	login_button.pressed.connect(_on_login_pressed)
	acc_button.pressed.connect(_on_acc_pressed)
	http.request_completed.connect(_on_request_completed)

	forgot_label.gui_input.connect(_on_forgot_label_input)

func _on_login_pressed() -> void:
	# 👇 YENİ: Yeni deneme yaparken eski hata mesajını gizle
	if error_label:
		error_label.visible = false
	
	var body = {
		"email": email_field.text,
		"password": password_field.text
	}
	send_request(http, "/api/login", body)

func _on_request_completed(_result: int, _code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var json = JSON.parse_string(body.get_string_from_utf8())
	
	if json == null:
		print("❌ Invalid JSON response")
		_show_error("Sunucu hatası! Lütfen tekrar dene.")
		return

	if json.has("access_token"):
		# --- BAŞARILI GİRİŞ ---
		Globals.auth_token = json["access_token"]
		Globals.user_id = json.get("user_id", "")
		print("✅ Login başarılı. User ID:", Globals.user_id)
		
		Globals.load_from_server()
		Globals.change_scene_with_loading("res://scenes/MainGame.tscn")
		
	else:
		# --- BAŞARISIZ GİRİŞ ---
		print("❌ Login failed:", json)
		
		var error_msg = "Login failed :("
		
		# 1. Şifre/Email Yanlış
		if json.has("error_code") and json["error_code"] == "invalid_credentials":
			error_msg = "Incorrect email or password."
			
		# 2. Email Boş Girildiyse
		elif json.has("error_code") and json["error_code"] == "validation_failed":
			if "email" in str(json.get("msg", "")):
				error_msg = "Please enter your email address."
			else:
				error_msg = "Validation failed."

		# 3. 👇 YENİ: Email Onaylanmadıysa
		elif json.has("error_code") and json["error_code"] == "email_not_confirmed":
			error_msg = "Email not confirmed. Please check your inbox."

		# 4. Diğer Hatalar (Fallback)
		elif json.has("msg"):
			error_msg = str(json["msg"])
		elif json.has("error_description"):
			error_msg = str(json["error_description"])
		
		# Hata mesajını ekranda göster
		_show_error(error_msg)

# 👇 YENİ: Hata gösterme fonksiyonu (Kod tekrarını önlemek için)
func _show_error(message: String):
	if error_label:
		error_label.text = message
		error_label.visible = true
		
		# (Opsiyonel) Dikkat çekmek için kırmızı yapabilirsin
		error_label.add_theme_color_override("font_color", Color.RED)

func _on_acc_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/authscreen_signup.tscn")

func _on_forgot_label_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		get_tree().change_scene_to_file("res://scenes/authscreen_forgotps.tscn")
