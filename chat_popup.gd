extends CanvasLayer

const CHAT_MESSAGE_SCENE = preload("res://scenes/prefabs/chat_message.tscn")

@onready var message_list = $MainWindow/MarginContainer/ContentLayout/ChatScroll/MessageList
@onready var chat_scroll = $MainWindow/MarginContainer/ContentLayout/ChatScroll
@onready var input_field = $MainWindow/InputField
@onready var send_button = $MainWindow/SendButton
# HTTP Request node
@onready var http = $HTTPRequest

# Check if awaiting bot response
var is_waiting_for_response = false

func _ready():
	# Connect HTTP signal
	if http:
		if not http.request_completed.is_connected(_on_ai_request_completed):
			http.request_completed.connect(_on_ai_request_completed)
	
	# Input submit signal
	if input_field:
		if not input_field.text_submitted.is_connected(_on_input_field_text_submitted):
			input_field.text_submitted.connect(_on_input_field_text_submitted)
	
	# Send button signal
	if send_button:
		if not send_button.pressed.is_connected(_on_send_button_pressed):
			send_button.pressed.connect(_on_send_button_pressed)
	
	# Close button signal
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
	if is_waiting_for_response: return

	var user_text = input_field.text.strip_edges()
	if user_text == "": return

	# 1. Add user message
	add_message_to_chat(user_text, true)
	input_field.clear()
	
	# 2. Loading state
	is_waiting_for_response = true
	input_field.placeholder_text = "Coach is thinking..."
	input_field.editable = false
	
	# 3. Prepare payload and dispatch
	_send_to_ai_coach(user_text)

# --- AI COMMUNICATION ---
func _send_to_ai_coach(user_msg: String):
	# A) Fetch Gym Logs
	var gym_logs = Globals.cache.get("gym_log", [])
	
	# Slice last 50 entries to conserve context window
	if typeof(gym_logs) == TYPE_ARRAY and gym_logs.size() > 50:
		gym_logs = gym_logs.slice(-50)
	
	# B) User Name
	var user_name = Globals.cache.get("user", {}).get("name", "Athlete")
	
	# C) Prepare Payload
	var body = {
		"message": user_msg,
		"context": gym_logs,
		"user_name": user_name
	}
	
	var headers = ["Content-Type: application/json"]
	var api_url = "https://life-sim-worker.life-simulation.workers.dev/api/ai_chat" 
	
	# D) Send request
	http.request(api_url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func _on_ai_request_completed(_result, response_code, _headers, body):
	is_waiting_for_response = false
	input_field.placeholder_text = "Enter your text..."
	input_field.editable = true
	input_field.grab_focus()

	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json.has("reply"):
			# Add AI response
			add_message_to_chat(json["reply"], false)
		else:
			add_message_to_chat("Could not understand the answer.", false)
	else:
		print("AI Error: ", response_code)
		add_message_to_chat("Load error. (Code: %d)" % response_code, false)

func _on_input_field_text_submitted(_new_text: String) -> void:
	_on_send_button_pressed()

func _on_close_button_pressed() -> void:
	visible = false
