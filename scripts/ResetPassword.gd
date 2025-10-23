extends "res://scripts/AuthBase.gd"

@onready var email_field = $LineEdit
@onready var reset_button = $Reset_Button
@onready var message_label = $ResetMessageLabel
@onready var http = $HTTPRequest

func _ready():
	reset_button.pressed.connect(_on_reset_pressed)
	http.request_completed.connect(_on_request_completed)
	message_label.visible = false

# 🔹 Şifre sıfırlama isteği
func _on_reset_pressed() -> void:
	var url = SUPABASE_URL + "/auth/v1/recover"
	var body = { "email": email_field.text }
	send_request(http, url, body)

# 🔹 Cevap geldiğinde
func _on_request_completed(result: int, code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if code == 200:
		message_label.visible = true
		message_label.text = "📧 Şifre sıfırlama e-postası gönderildi!"
	else:
		message_label.visible = true
		message_label.text = "⚠️ Şifre sıfırlama başarısız. E-postayı kontrol et."
