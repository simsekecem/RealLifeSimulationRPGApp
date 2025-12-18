extends CanvasLayer

const CHAT_MESSAGE_SCENE = preload("res://scenes/prefabs/chat_message.tscn")

@onready var message_list = $MainWindow/MarginContainer/ContentLayout/ChatScroll/MessageList
@onready var chat_scroll = $MainWindow/MarginContainer/ContentLayout/ChatScroll
@onready var input_field = $MainWindow/InputField
@onready var send_button = $MainWindow/SendButton
# 👇 YENİ: HTTP Request düğümü (Sahneye eklediğinden emin ol)
@onready var http = $HTTPRequest

# Botun yazıp yazmadığını kontrol etmek için
var is_waiting_for_response = false

func _ready():
	# HTTP sinyalini bağla
	# HTTP sinyalini bağla (Önce kontrol et)
	if http:
		if not http.request_completed.is_connected(_on_ai_request_completed):
			http.request_completed.connect(_on_ai_request_completed)
	
	# Input enter tuşu sinyali
	if input_field:
		if not input_field.text_submitted.is_connected(_on_input_field_text_submitted):
			input_field.text_submitted.connect(_on_input_field_text_submitted)
	
	# Buton sinyali
	if send_button:
		if not send_button.pressed.is_connected(_on_send_button_pressed):
			send_button.pressed.connect(_on_send_button_pressed)
	
	# Close buton sinyali (Eğer varsa)
	if has_node("MainWindow/CloseButton"):
		var close_btn = $MainWindow/CloseButton
		if not close_btn.pressed.is_connected(_on_close_button_pressed):
			close_btn.pressed.connect(_on_close_button_pressed)

func add_message_to_chat(text: String, is_user: bool):
	var new_message = CHAT_MESSAGE_SCENE.instantiate()
	message_list.add_child(new_message)
	new_message.setup(text, is_user)
	_scroll_to_bottom()

func _scroll_to_bottom():
	await get_tree().process_frame
	chat_scroll.scroll_vertical = chat_scroll.get_v_scroll_bar().max_value

func _on_send_button_pressed():
	if is_waiting_for_response: return # Cevap gelmeden yeni soru sorulmasın

	var user_text = input_field.text.strip_edges()
	if user_text == "": return

	# 1. Kullanıcı mesajını ekle
	add_message_to_chat(user_text, true)
	input_field.clear()
	
	# 2. Yükleniyor mesajı (İstersen animasyonlu bir şey yapabilirsin)
	is_waiting_for_response = true
	input_field.placeholder_text = "Koç düşünüyor..."
	input_field.editable = false
	
	# 3. VERİLERİ HAZIRLA VE GÖNDER
	_send_to_ai_coach(user_text)

# --- YAPAY ZEKA İLETİŞİMİ ---
func _send_to_ai_coach(user_msg: String):
	# A) Kullanıcının Gym Verilerini Al
	var gym_logs = Globals.cache.get("gym_log", [])
	
	# Veri çok büyükse token limitini yememesi için son 50 kaydı alabiliriz
	if typeof(gym_logs) == TYPE_ARRAY and gym_logs.size() > 50:
		gym_logs = gym_logs.slice(-50) # Sondan 50 tanesini al
	
	# B) Kullanıcı Adı (Varsa)
	var user_name = Globals.cache.get("user", {}).get("name", "Sporcu")
	
	# C) İsteği Hazırla
	var body = {
		"message": user_msg,
		"context": gym_logs, # Egzersiz geçmişini buraya gömüyoruz
		"user_name": user_name
	}
	
	var headers = ["Content-Type: application/json"]
	
	# Worker URL'ini buraya yaz (Sonuna /api/ai_chat ekleyerek)
	# Örn: https://senin-worker-adın.workers.dev/api/ai_chat
	var api_url = "https://life-sim-worker.life-simulation.workers.dev/api/ai_chat" 
	
	# D) Gönder
	http.request(api_url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func _on_ai_request_completed(_result, response_code, _headers, body):
	is_waiting_for_response = false
	input_field.placeholder_text = "Mesaj yaz..." # Eski haline getir
	input_field.editable = true
	input_field.grab_focus()

	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json.has("reply"):
			# Gemini'nin cevabını ekle
			add_message_to_chat(json["reply"], false)
		else:
			add_message_to_chat("Cevap anlaşılmadı.", false)
	else:
		print("❌ AI Hatası: ", response_code)
		add_message_to_chat("Bağlantı hatası oluştu. (Kod: %d)" % response_code, false)

func _on_input_field_text_submitted(_new_text: String) -> void:
	_on_send_button_pressed()

func _on_close_button_pressed() -> void:
	visible = false
