extends Control

# 🔑 Senin Supabase bilgilerin
const SUPABASE_URL = "https://rzsndtstonztfuayodmg.supabase.co"
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ6c25kdHN0b256dGZ1YXlvZG1nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAyOTg4OTQsImV4cCI6MjA3NTg3NDg5NH0.UPDS44mZl-YP0UNGqnpPzIedyphNptgnXehax5tUi50"

@onready var email_field = $EmailField
@onready var password_field = $PasswordField
@onready var http = $HTTPRequest

var pending_action := ""  # "login" or "signup"

func _ready():
	$LoginButton.pressed.connect(_on_login)
	$SignupButton.pressed.connect(_on_signup)
	http.request_completed.connect(_on_request_completed)

# 🔹 LOGIN
func _on_login() -> void:
	pending_action = "login"
	var url = SUPABASE_URL + "/auth/v1/token?grant_type=password"
	var headers = [
		"Content-Type: application/json",
		"apikey: " + SUPABASE_KEY
	]
	var body = {
		"email": email_field.text,
		"password": password_field.text
	}
	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

# 🔹 SIGNUP
func _on_signup() -> void:
	pending_action = "signup"
	var url = SUPABASE_URL + "/auth/v1/signup"
	var headers = [
		"Content-Type: application/json",
		"apikey: " + SUPABASE_KEY
	]
	var body = {
		"email": email_field.text,
		"password": password_field.text
	}
	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

# 🔹 YANIT İŞLEME
func _on_request_completed(result: int, code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var data = JSON.parse_string(body.get_string_from_utf8())

	# Eğer kullanıcı onay bekliyorsa:
	if data.has("user") and data["user"] == null and not data.has("session"):
		print("📧 E-posta adresinizi kontrol edin. Onay maili gönderildi.")
		return

	var token: String = ""
	var user_id: String = ""

	if data.has("access_token"):
		token = data["access_token"]
	if data.has("user") and data["user"] != null and data["user"].has("id"):
		user_id = data["user"]["id"]

	# Bazı cevaplarda session içinde olur
	if data.has("session"):
		var session = data["session"]
		if session.has("access_token"):
			token = session["access_token"]
		if session.has("user") and session["user"].has("id"):
			user_id = session["user"]["id"]

	if token == "" or user_id == "":
		print("⚠️ Kullanıcı veya token bilgisi eksik:", data)
		return

	Globals.auth_token = token
	Globals.user_id = user_id

	print(pending_action + " successful!")
	print("User ID:", user_id)
	print("Token:", token)

	# Başarılı giriş sonrası sahne geçişi örneği:
	# get_tree().change_scene_to_file("res://Main.tscn")


func _on_acc_button_pressed() -> void:
	print("Create Account clicked!") # test için
	get_tree().change_scene_to_file("res://scenes/authscreen_signup.tscn")
