extends Panel

signal item_selected(data)
signal item_delete_requested(data) 
signal item_edit_requested(data)

@onready var texture_rect = $VBoxContainer/TextureRect
@onready var label = $VBoxContainer/Label
# Based on your previous snippet, check if this path is correct for your scene:
@onready var delete_button = $VBoxContainer/HBoxContainer/DeleteButton 
@onready var edit_button = $VBoxContainer/HBoxContainer/EditButton 

var item_data: Dictionary = {}

func _ready():
	# Make TextureRect clickable
	texture_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	texture_rect.gui_input.connect(_on_texture_gui_input)
	
	# Connect Delete button
	if delete_button:
		delete_button.pressed.connect(_on_delete_pressed)
		
	if edit_button: 
		edit_button.pressed.connect(_on_edit_pressed)

func setup(data: Dictionary):
	item_data = data
	var display_name = data.get("item_name", "Unknown").capitalize()
	label.text = display_name
	
	# 1. Cast to float to guarantee safety
	var confidence = float(data.get("confidence", 1.0))
	
	if confidence < 0.70:
		# Make it Red
		label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		# Show a tooltip when mouse hovers over the text
		tooltip_text = "Low Confidence Score: %" + str(snapped(confidence * 100, 0.1))
	else:
		# Make it White
		label.add_theme_color_override("font_color", Color.WHITE)
		tooltip_text = "" # Clear tooltip

	# Load Image
	var image_url = data.get("image_url", "")
	if image_url != "":
		_load_remote_image(image_url)

func _load_remote_image(url: String):
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, code, headers, body):
		http.queue_free()
		if code == 200:
			var img = Image.new()
			# Try loading as JPG first, if fails try PNG (just in case)
			var err = img.load_jpg_from_buffer(body)
			if err != OK:
				err = img.load_png_from_buffer(body)
				
			if err == OK:
				texture_rect.texture = ImageTexture.create_from_image(img)
				texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)
	http.request(url)

# 🔥 SELECT ON IMAGE CLICK
func _on_texture_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("item_selected", item_data)

# 🔥 DELETE REQUEST
func _on_delete_pressed():
	emit_signal("item_delete_requested", item_data)

func _on_edit_pressed():
	print("✏️ Edit butonuna basıldı: ", item_data.get("item_name"))
	emit_signal("item_edit_requested", item_data)
