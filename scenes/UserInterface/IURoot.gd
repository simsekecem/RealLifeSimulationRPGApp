extends Control

@onready var windows = $Windows

# Top-Left References
@onready var top_left_frame = $TopLeftButtons/Frame
@onready var avatar_icon = $TopLeftButtons/Frame/AvatarIcon
@onready var xp_bar = $TopLeftButtons/Frame/XPBar
@onready var username_text = $TopLeftButtons/Frame/UsernameText

func _ready():
	# Avatar button click
	if avatar_icon:
		avatar_icon.pressed.connect(show_avatar)
	
	# Top-Right Buttons
	if has_node("TopRightButtons/MissionsButton"):
		$TopRightButtons/MissionsButton.pressed.connect(show_missions)
	if has_node("TopRightButtons/SettingsButton"):
		$TopRightButtons/SettingsButton.pressed.connect(show_settings)
	
	if has_node("Joystick"):
		# Show joystick on mobile (Android/iOS), hide on desktop
		if OS.get_name() == "Android" or OS.get_name() == "iOS":
			$Joystick.visible = true
		else:
			$Joystick.visible = false
	
	# Update UI when cache data updates
	if Globals.has_signal("data_updated"):
		Globals.data_updated.connect(update_top_left_ui)
	
	# Initial UI load
	update_top_left_ui()
	print("✅ UI connections established.")

# =================================================
# TOP-LEFT UI MANAGEMENT
# =================================================
func update_top_left_ui():
	var user_data = Globals.cache.get("user", {})
	
	# 1. Username
	if username_text:
		username_text.text = str(user_data.get("name", "Player"))
	
	# 2. XP Bar
	if xp_bar:
		var current_xp = int(user_data.get("experience", 0))
		var current_lvl = int(user_data.get("level", 1))
		
		if Globals.has_method("get_required_xp"):
			xp_bar.max_value = Globals.get_required_xp(current_lvl)
		else:
			xp_bar.max_value = (current_lvl * 200) + 100
		xp_bar.value = current_xp
		xp_bar.tooltip_text = "Level: %d | XP: %d / %d" % [current_lvl, current_xp, xp_bar.max_value]

	# 3. Avatar Icon
	if avatar_icon:
		var char_id = int(user_data.get("character_id", 1))
		
		var path = "res://assets/characters/icons/char_icon_%d.png" % char_id
		
		if not ResourceLoader.exists(path):
			path = "res://assets/characters/char_%d.png" % char_id

		if ResourceLoader.exists(path):
			var tex = load(path)
			
			if avatar_icon is TextureButton:
				avatar_icon.texture_normal = tex
				avatar_icon.ignore_texture_size = true
				avatar_icon.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			elif avatar_icon is TextureRect:
				avatar_icon.texture = tex
		else:
			print("⚠️ Avatar icon not found: ", path)

# =================================================
# WINDOW MANAGEMENT
# =================================================

func hide_all_windows():
	if windows:
		for w in windows.get_children():
			w.visible = false

func hide_all_ui():
	$TopLeftButtons.visible = false
	$TopRightButtons.visible = false
	hide_all_windows()
	if has_node("Joystick"): $Joystick.visible = false

func show_avatar():
	hide_all_windows()
	if has_node("Windows/AvatarWindow"):
		$Windows/AvatarWindow.visible = true
		if $Windows/AvatarWindow.has_method("update_ui_from_cache"):
			$Windows/AvatarWindow.update_ui_from_cache()

func show_missions():
	hide_all_windows()
	if has_node("Windows/MissionsWindow"):
		$Windows/MissionsWindow.visible = true

func show_settings():
	hide_all_windows()
	if has_node("Windows/SettingsWindow"):
		$Windows/SettingsWindow.visible = true
	
func show_only_top_right_buttons():
	$TopLeftButtons.visible = false
	hide_all_windows()
	if has_node("Joystick"): $Joystick.visible = false
	$TopRightButtons.visible = true
	
func change_scene_to(scene_path: String):
	Globals.save_cache()
	Globals.change_scene_with_loading(scene_path)

func show_full_ui():
	$TopLeftButtons.visible = true
	$TopRightButtons.visible = true
	if has_node("Joystick"):
		if OS.get_name() == "Android" or OS.get_name() == "iOS":
			$Joystick.visible = true
		else:
			$Joystick.visible = false
	hide_all_windows()
	update_top_left_ui()

func return_to_town():
	var current_scene = get_tree().current_scene
	if current_scene.has_method("exit_house"):
		current_scene.exit_house()
		return
	if get_tree().root.has_node("MainGame"):
		var main_node = get_tree().root.get_node("MainGame")
		if main_node.has_method("exit_house"):
			main_node.exit_house()
			return
	get_tree().change_scene_to_file("res://scenes/town.tscn")
	show_full_ui()
