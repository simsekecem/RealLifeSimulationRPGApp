extends Control

# =================================================
# NODE REFERENCES
# =================================================

# --- Main View ---
@onready var close_button_main = $CloseButton 
@onready var edit_button = $EditButton

# Display Labels
@onready var label_name_display = $Name
@onready var label_level_display = $Level
@onready var label_xp_display = $XP
@onready var label_birth_display = $Birthday

# Character Preview (Animated Sprite)
@onready var preview_sprite = $Background/CharacterPreviewHolder/PreviewSprite

# --- Edit Window ---
@onready var edit_window = $EditWindow
@onready var close_button_edit = $EditWindow/Background/CloseButton
@onready var save_button = $EditWindow/SaveButton
@onready var input_name = $EditWindow/NewNameLE

# Character Switching Buttons
@onready var btn_next = $BtnNext
@onready var btn_prev = $BtnPrev 

# Date Selectors
@onready var opt_day = $EditWindow/BirthdayContainer/Day
@onready var opt_month = $EditWindow/BirthdayContainer/Month 
@onready var opt_year = $EditWindow/BirthdayContainer/Year

# -----------------------------------------------
# VARIABLES
# -----------------------------------------------
var temp_char_id: int = 1
var max_character_count: int = 2

# =================================================
# INITIALIZATION
# =================================================
func _ready():
	# Main button connections
	close_button_main.pressed.connect(hide_avatar_window)
	edit_button.pressed.connect(show_edit_window)
	close_button_edit.pressed.connect(hide_edit_window)
	
	if save_button:
		save_button.pressed.connect(_on_save_pressed)
	
	# Refresh UI when cache data updates
	if Globals.has_signal("data_updated"):
		Globals.data_updated.connect(update_ui_from_cache)
	
	# Connect character switching buttons
	if btn_next: 
		btn_next.pressed.connect(_change_character.bind(1))
	if btn_prev: 
		btn_prev.pressed.connect(_change_character.bind(-1))
	
	_setup_date_dropdowns()
	edit_window.visible = false
	update_ui_from_cache()

# =================================================
# UI UPDATE
# =================================================
func update_ui_from_cache():
	var user_data = Globals.cache.get("user", {})
	
	# Populate main view
	if label_name_display: label_name_display.text = str(user_data.get("name", "Player"))
	
	# --- LEVEL & XP CALCULATION ---
	var total_xp = int(user_data.get("experience", 0))
	var current_level = int(user_data.get("level", 1))
	
	# Required XP for next level
	var xp_needed_for_next = 300 # Default
	if Globals.has_method("get_required_xp"):
		xp_needed_for_next = Globals.get_required_xp(current_level)
	
	# Update level text
	if label_level_display: 
		label_level_display.text = "LEVEL " + str(current_level)
		
	# Update XP text
	if label_xp_display: 
		label_xp_display.text = "%d / %d" % [total_xp, xp_needed_for_next]
	
	# Update Progress Bar if present
	if get_node_or_null("XPBar"):
		var bar = get_node("XPBar")
		bar.max_value = xp_needed_for_next
		bar.value = total_xp
	
	# Other profile fields
	var birth_str = str(user_data.get("birthdate", "2000-01-01"))
	if label_birth_display: label_birth_display.text = birth_str
	
	if input_name: input_name.text = str(user_data.get("name", ""))
	_set_date_selectors(birth_str)
	
	temp_char_id = int(user_data.get("character_id", 1))
	_update_character_visual(temp_char_id)

# =================================================
# CHARACTER VISUAL MANAGEMENT
# =================================================
func _update_character_visual(id: int):
	if id < 1: id = 1
	var path = "res://assets/characters/resources/char_%d.tres" % id
	
	if ResourceLoader.exists(path) and preview_sprite:
		preview_sprite.sprite_frames = load(path)
		preview_sprite.play("idle_down") 
		preview_sprite.scale = Vector2(4, 4) 
		preview_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	else:
		print("⚠️ Character animation not found: ", path)

func _change_character(direction: int):
	# 1. Fetch current level
	var user_data = Globals.cache.get("user", {})
	var current_level = int(user_data.get("level", 1))
	
	# 2. Calculate target ID
	var target_id = temp_char_id + direction
	
	# Cyclical wrap (1 -> 2 -> 1)
	if target_id > max_character_count: target_id = 1
	elif target_id < 1: target_id = max_character_count
	
	# 3. Lock check: Character ID cannot exceed user level
	if target_id > current_level:
		print("🔒 LOCKED! Level ", target_id, " required for this character.")
		
		# Visual alert: flash red
		if preview_sprite:
			preview_sprite.modulate = Color.RED
			var tween = get_tree().create_tween()
			tween.tween_property(preview_sprite, "modulate", Color.WHITE, 0.3)
			
		return

	# 4. Apply character change
	print("🔘 Changing character: ", temp_char_id, " -> ", target_id)
	temp_char_id = target_id
	_update_character_visual(temp_char_id)

# =================================================
# SAVE
# =================================================
func _on_save_pressed():
	# Save name and birthdate changes
	var new_name = input_name.text.strip_edges()
	var new_birth_date = _get_date_string_from_selectors()
	
	if not Globals.cache.has("user"): Globals.cache["user"] = {}
	Globals.cache["user"]["name"] = new_name
	Globals.cache["user"]["birthdate"] = new_birth_date
	
	Globals.mark_dirty()
	Globals.save_cache()
	print("✅ Profile (Name/Birthdate) updated.")
	
	# Quest triggers
	var q_manager = get_node_or_null("/root/QuestManager")
	if q_manager:
		if new_name != "" and new_name != "Player" and new_name != "Rookie":
			q_manager.trigger_action("first_name")
		
		if new_birth_date != "":
			q_manager.trigger_action("first_birthday")
	update_ui_from_cache()
	hide_edit_window()

# =================================================
# WINDOW MANAGEMENT & PERSISTENCE
# =================================================
func hide_avatar_window():
	if not Globals.cache.has("user"): 
		Globals.cache["user"] = {}
	
	# Persist selected character ID
	Globals.cache["user"]["character_id"] = temp_char_id
	
	Globals.mark_dirty()
	Globals.save_cache()
	
	print("💾 [AVATAR] Character selected: ", temp_char_id)
	
	# Notify UI elements
	if Globals.has_signal("data_updated"):
		Globals.emit_signal("data_updated")
	
	# Update top-left avatar icon
	_trigger_main_ui_update()
	
	self.visible = false

func _trigger_main_ui_update():
	var p = get_parent()
	while p:
		if p.has_method("update_top_left_ui"):
			p.update_top_left_ui()
			break
		p = p.get_parent()

func show_edit_window():
	update_ui_from_cache()
	edit_window.visible = true

func hide_edit_window():
	edit_window.visible = false

# =================================================
# DATE HELPERS
# =================================================
func _setup_date_dropdowns():
	if opt_day:
		opt_day.clear()
		for i in range(1, 32): opt_day.add_item(str(i))
	if opt_month:
		opt_month.clear()
		var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
		for m in months: opt_month.add_item(m)
	if opt_year:
		opt_year.clear()
		for i in range(1950, 2026): opt_year.add_item(str(i))

func _get_date_string_from_selectors() -> String:
	var d = "01"
	if opt_day: d = opt_day.get_item_text(opt_day.selected).pad_zeros(2)
	var m = "01"
	if opt_month: m = str(opt_month.selected + 1).pad_zeros(2)
	var y = "2000"
	if opt_year: y = opt_year.get_item_text(opt_year.selected)
	return "%s-%s-%s" % [y, m, d]

func _set_date_selectors(date_str: String):
	var parts = date_str.split("-")
	if parts.size() == 3:
		var y = int(parts[0]); var m = int(parts[1]); var d = int(parts[2])
		if opt_year:
			for i in range(opt_year.item_count):
				if int(opt_year.get_item_text(i)) == y: opt_year.select(i); break
		if opt_month: opt_month.select(m - 1)
		if opt_day: opt_day.select(d - 1)
