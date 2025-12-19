extends CanvasLayer

const CHAT_MESSAGE_SCENE = preload("res://scenes/prefabs/chat_message_r.tscn")

@onready var message_list = $MainWindow/MarginContainer/ContentLayout/ChatScroll/MessageList
@onready var chat_scroll = $MainWindow/MarginContainer/ContentLayout/ChatScroll
@onready var input_field = $MainWindow/InputField
@onready var send_button = $MainWindow/SendButton
@onready var http = $HTTPRequest # ⚠️ Sahneye eklediğinden emin ol!

var is_waiting_for_response = false

func _ready():
	# Sinyallerin daha önce bağlanıp bağlanmadığını kontrol ederek bağla
	if http and not http.request_completed.is_connected(_on_ai_request_completed):
		http.request_completed.connect(_on_ai_request_completed)
	
	if input_field and not input_field.text_submitted.is_connected(_on_input_field_text_submitted):
		input_field.text_submitted.connect(_on_input_field_text_submitted)
	
	if send_button and not send_button.pressed.is_connected(_on_send_button_pressed):
		send_button.pressed.connect(_on_send_button_pressed)

func add_message_to_chat(text: String, is_user: bool):
	var new_message = CHAT_MESSAGE_SCENE.instantiate()
	message_list.add_child(new_message)
	new_message.setup(text, is_user)
	_scroll_to_bottom()

func _scroll_to_bottom():
	await get_tree().process_frame
	chat_scroll.scroll_vertical = chat_scroll.get_v_scroll_bar().max_value

func _on_send_button_pressed():
	if is_waiting_for_response: return 

	var user_text = input_field.text.strip_edges()
	if user_text == "": return

	add_message_to_chat(user_text, true)
	input_field.clear()
	
	is_waiting_for_response = true
	input_field.placeholder_text = "Diyetisyen düşünüyor..."
	input_field.editable = false
	
	_send_to_ai_dietitian(user_text)

func _send_to_ai_dietitian(user_msg: String):
	# Restaurant verilerini al
	var diet_logs = Globals.cache.get("restaurant", []) 
	
	# GÜVENLİK: Eğer çok fazla yemek yendiyse sadece son 40 kaydı gönder (Token sınırı için)
	if typeof(diet_logs) == TYPE_ARRAY and diet_logs.size() > 40:
		diet_logs = diet_logs.slice(-40)
		
	var user_name = Globals.cache.get("user", {}).get("name", "Gurme")
	
	var body = {
		"message": user_msg,
		"context": diet_logs, 
		"user_name": user_name
	}
	
	var headers = ["Content-Type: application/json"]
	var api_url = "https://life-sim-worker.life-simulation.workers.dev/api/ai_diet" 
	
	http.request(api_url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func _on_ai_request_completed(_result, response_code, _headers, body):
	is_waiting_for_response = false
	input_field.placeholder_text = "Mesaj yaz..." 
	input_field.editable = true
	input_field.grab_focus()

	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json.has("reply"):
			add_message_to_chat(json["reply"], false)
		else:
			add_message_to_chat("Hata: JSON formatı bozuk.", false)
	else:
		add_message_to_chat("Bağlantı hatası: %d" % response_code, false)

func _on_input_field_text_submitted(_new_text: String) -> void:
	_on_send_button_pressed()
	
func _on_close_button_pressed() -> void:
	visible = false
