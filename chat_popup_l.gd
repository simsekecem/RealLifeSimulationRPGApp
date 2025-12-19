extends CanvasLayer

const CHAT_MESSAGE_SCENE = preload("res://scenes/chat_message_l.tscn") # L versiyonu varsa

@onready var message_list = $MainWindow/MarginContainer/ContentLayout/ChatScroll/MessageList
@onready var chat_scroll = $MainWindow/MarginContainer/ContentLayout/ChatScroll
@onready var input_field = $MainWindow/InputField
@onready var send_button = $MainWindow/SendButton
@onready var http = $HTTPRequest

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

func _on_send_button_pressed():
	if is_waiting_for_response: return 

	var user_text = input_field.text.strip_edges()
	if user_text == "": return

	add_message_to_chat(user_text, true)
	input_field.clear()
	
	is_waiting_for_response = true
	input_field.placeholder_text = "Librain/Study Coach is thinking..."
	input_field.editable = false
	
	_send_to_ai_librarian(user_text)

func _send_to_ai_librarian(user_msg: String):
	# Kütüphane verilerini al (LibraryBooks tablosu)
	var library_data = Globals.cache.get("library", [])
	
	var user_name = "Kitap Kurdu"
	if Globals.cache.has("user") and Globals.cache["user"] != null:
		user_name = Globals.cache["user"].get("name", "Kitap Kurdu")
	
	var body = {
		"message": user_msg,
		"context": library_data, 
		"user_name": user_name
	}
	
	var headers = ["Content-Type: application/json"]
	# Endpoint'i kütüphane için değiştirdik
	var api_url = "https://life-sim-worker.life-simulation.workers.dev/api/ai_library" 
	
	http.request(api_url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func _on_ai_request_completed(_result, response_code, _headers, body):
	is_waiting_for_response = false
	input_field.placeholder_text = "Enter your text..." 
	input_field.editable = true
	input_field.grab_focus()

	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json.has("reply"):
			add_message_to_chat(json["reply"], false)
	else:
		add_message_to_chat("Library couldnt find (Error: %d)" % response_code, false)

func add_message_to_chat(text: String, is_user: bool):
	var new_message = CHAT_MESSAGE_SCENE.instantiate()
	message_list.add_child(new_message)
	new_message.setup(text, is_user)
	_scroll_to_bottom()

func _scroll_to_bottom():
	await get_tree().process_frame
	chat_scroll.scroll_vertical = chat_scroll.get_v_scroll_bar().max_value

func _on_input_field_text_submitted(_new_text: String) -> void:
	_on_send_button_pressed()

func _on_close_button_pressed() -> void:
	visible = false
