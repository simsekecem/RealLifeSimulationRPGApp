extends PopupPanel

@onready var container = $CenterContainer/VBoxContainer/HBoxContainer
@onready var explanation_label = $CenterContainer/VBoxContainer/RichTextLabel
@onready var close_button = $CenterContainer/VBoxContainer/Button

func _ready():
	exclusive = true 
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	# --- TEXT LABEL DISPLAY SETTINGS ---
	if explanation_label:
		# 1. Enable BBCode for styling and center tags
		explanation_label.bbcode_enabled = true
		
		# 2. Fit to content
		explanation_label.fit_content = true
		
		# 3. Set minimum width limit
		explanation_label.custom_minimum_size = Vector2(300, 0)
		
		# 4. Automatic word wrapping
		explanation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _on_close_pressed():
	queue_free()

func show_outfit(items: Array, explanation: String):
	popup_centered() 
	
	# Clear previous images
	for child in container.get_children():
		child.queue_free()
	
	# Update description text
	if explanation == "":
		explanation_label.text = "[center]Outfit is ready, but no description provided.[/center]"
	else:
		explanation_label.text = "[center]" + explanation + "[/center]"
	
	# Load item images
	for item in items:
		var tex_rect = TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(120, 120)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		container.add_child(tex_rect)
		
		var img_url = item.get("image_url", "")
		if img_url != "":
			_load_image(img_url, tex_rect)

func _load_image(url, target):
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(r, c, h, body):
		if not is_instance_valid(target):
			http.queue_free()
			return

		http.queue_free()
		
		if c == 200:
			var img = Image.new()
			var err = img.load_jpg_from_buffer(body)
			if err != OK: err = img.load_png_from_buffer(body)
				
			if err == OK:
				var tex = ImageTexture.create_from_image(img)
				target.texture = tex
	)
	http.request(url)
