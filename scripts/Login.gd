extends "res://scripts/AuthBase.gd"

@onready var email_field = $NinePatchRect/EmailLineEdit
@onready var password_field = $NinePatchRect/PasswordLineEdit
@onready var login_button = $NinePatchRect/Login_Button
@onready var acc_button = $NinePatchRect/Acc_Button
@onready var forgot_label = $NinePatchRect/ForgotPasswordLabel
@onready var http = $HTTPRequest

func _ready():
	# Giriş ekranındayken oyunun UI'ını (Joystick vb.) gizle
	if UI.has_node("UIRoot"):
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
	# AuthBase içindeki fonksiyonu kullanıyoruz
	send_request(http, "/api/login", body)

func _on_request_completed(_result: int, _code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var json = JSON.parse_string(body.get_string_from_utf8())
	
	if json == null:
		print("❌ Invalid JSON response")
		return

	if json.has("access_token"):
		# 1. Token'ı kaydet
		Globals.auth_token = json["access_token"]
		Globals.user_id = json.get("user_id", "")
		print("✅ Login başarılı. User ID:", Globals.user_id)
		
		# 2. Kullanıcının verilerini (Gym, Market, Notlar) sunucudan çek
		Globals.load_from_server()

		# 3. SAHNE DEĞİŞİMİ (DÜZELTİLDİ)
		# "Main.tscn" yerine "MainGame.tscn" kullanıyoruz.
		# Ayrıca direkt geçiş yerine Loading Screen kullanıyoruz.
		Globals.change_scene_with_loading("res://scenes/MainGame.tscn")
		
	else:
		print("❌ Login failed:", json)

func _on_acc_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/authscreen_signup.tscn")

func _on_forgot_label_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		get_tree().change_scene_to_file("res://scenes/authscreen_forgotps.tscn")
