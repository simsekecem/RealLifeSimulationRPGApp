extends Node2D

# Access to Container nodes in the scene tree
@onready var town_container = $TownContainer
@onready var home_container = $HomeContainer
@onready var others_container = $OthersContainer

# Path to the Town scene
var town_scene_path = "res://scenes/town.tscn"

func _ready():
	print("MainGame initialized. Populating TownContainer...")
	# 🎵 START BACKGROUND MUSIC
	MusicController.bgm_play()
	# ---------------------------------------------------------
	# 1. LOAD TOWN SCENE
	# ---------------------------------------------------------
	if town_scene_path != "":
		var town_scene = load(town_scene_path)
		var town_instance = town_scene.instantiate()
		town_container.add_child(town_instance)
		print("✅ Town added to scene.")
	else:
		print("❌ ERROR: Town scene path is empty!")

	# ---------------------------------------------------------
	# 2. GLOBAL UI ACCESS
	# ---------------------------------------------------------
	if UI.has_node("UIRoot"):
		var ui_root = UI.get_node("UIRoot")
		
		# Show joystick and buttons
		if ui_root.has_method("show_full_ui"):
			ui_root.show_full_ui()
			ui_root.set_process_input(true) 
			print("✅ UI activated.")
	else:
		print("⚠️ WARNING: 'UIRoot' not found in Global UI!")

## ---------------------------------------------------------
# FUNCTION: ENTER HOUSE / INDOOR VENUE (UPDATED)
# ---------------------------------------------------------
func enter_house(house_path: String):
	print("🚪 Entering indoor venue: ", house_path)
	
	# --- OFFSET BEFORE ENTERING ---
	# Move the character away from the door before freezing Town.
	# This prevents re-triggering the door upon returning (unpausing).
	if town_container.get_child_count() > 0:
		var town_instance = town_container.get_child(0)
		if town_instance.has_node("Player"):
			var player = town_instance.get_node("Player")
			player.position.y += 10 # Shift down
			
			# Face down so character looks like they exited through the door
			if player.has_method("play_animation"):
				player.last_direction = Vector2.DOWN
				player.play_animation("idle")
	# --------------------------------------------

	# 1. Hide and freeze Town
	town_container.visible = false
	town_container.process_mode = Node.PROCESS_MODE_DISABLED
	
	# 2. Instantiate the new scene
	var new_scene = load(house_path).instantiate()
	
	# 3. Place into appropriate container based on scene type
	if new_scene is Control:
		others_container.add_child(new_scene)
	elif new_scene is Node2D:
		home_container.add_child(new_scene)
		
		# Activate the indoor player's camera
		if new_scene.has_node("Player"):
			var home_player = new_scene.get_node("Player")
			if home_player.has_node("Camera2D"):
				home_player.get_node("Camera2D").make_current()


# ---------------------------------------------------------
# FUNCTION: EXIT HOUSE (RETURN TO TOWN)
# ---------------------------------------------------------
func exit_house():
	print("🌲 Returning to Town...")
	
	# 1. LOCK DOORS (Spawn loop protection)
	Globals.door_locked = true

	# 2. Clear indoor locations and menus
	for child in home_container.get_children():
		child.queue_free()
	
	for child in others_container.get_children():
		child.queue_free()
		
	# 3. Unhide and resume Town
	town_container.visible = true
	town_container.process_mode = Node.PROCESS_MODE_INHERIT
	
	# 4. ADJUST CAMERA
	if town_container.get_child_count() > 0:
		var town_instance = town_container.get_child(0)
		if town_instance.has_node("Player"):
			var player = town_instance.get_node("Player")
			
			# Switch camera back to the Town player
			if player.has_node("Camera2D"):
				player.get_node("Camera2D").make_current()
				
			# Face down and switch to idle animation
			if player.has_method("play_animation"):
				player.last_direction = Vector2.DOWN
				player.play_animation("idle")

	# 5. Show UI
	if UI.has_node("UIRoot"):
		UI.get_node("UIRoot").show_full_ui()
		
	# 6. UNLOCK TIMER
	print("⏳ Doors locked for 1 second.")
	await get_tree().create_timer(1.0).timeout
	Globals.door_locked = false
	print("🔓 Doors re-enabled.")
	
	
	
  
