extends Control

@export var mission_row_scene: PackedScene = preload("res://scenes/prefabs/MissionRow.tscn")
@onready var missions_list = $ScrollContainer/MissionsPanel
@onready var close_button = $Background/CloseButton 

func _ready():
	close_button.pressed.connect(hide_missions_window)
	
	# Connect signal (triggered when quests complete or update)
	if Globals.has_signal("data_updated"):
		Globals.data_updated.connect(refresh_mission_list)
	
	# Allow QuestManager a short moment to populate static quests
	await get_tree().create_timer(0.1).timeout
	refresh_mission_list()

func refresh_mission_list():
	var all_quests = Globals.cache.get("quests", [])
	
	# --- SORTING LOGIC ---
	var daily_quests = []
	var other_quests = []
	
	# Split quests by type
	for q in all_quests:
		if q.get("type") == "daily":
			daily_quests.append(q)
		else:
			other_quests.append(q)
	
	# Daily quests first, followed by story quests
	var sorted_quests = daily_quests + other_quests
	
	print("🔍 Listing quests: ", sorted_quests.size(), " total (Daily prioritized)")
	load_missions(sorted_quests)

func load_missions(missions: Array):
	# Clear old list
	for child in missions_list.get_children():
		child.queue_free()

	for quest in missions:
		var row = mission_row_scene.instantiate()
		
		# --- NODE PATHS ---
		var name_label = row.get_node("MissionList/MissionName")
		var detail_label = row.get_node("MissionList/MissionDetail")
		var xp_label = row.get_node("MissionList/HBoxContainer/XP")
		
		var tick_icon = row.get_node_or_null("Completed") 
		
		# Populate data
		name_label.text = quest.get("description", "Mission")
		xp_label.text = str(quest.get("xp_reward", 0)) + " XP"
		
		var type_text = "[DAILY]" if quest.get("type") == "daily" else "[STORY]"
		detail_label.text = type_text + " Task"
		
		var is_done = quest.get("is_completed", false)

		# --- CHECKBOX ICON SETTINGS ---
		if tick_icon:
			tick_icon.visible = true
			if "button_pressed" in tick_icon:
				tick_icon.button_pressed = is_done
				tick_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# --- COLOR STYLING ---
		if is_done:
			name_label.add_theme_color_override("font_color", Color.GREEN)
		else:
			name_label.add_theme_color_override("font_color", Color.BLACK)
		
		missions_list.add_child(row)

func hide_missions_window():
	self.visible = false
