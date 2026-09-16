extends Area2D

@export_file("*.tscn") var target_scene_path: String = ""
@export var is_exit_door: bool = false

# Local safety delay so door doesn't trigger immediately on scene load
var is_active: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	
	# Activate door 0.5 seconds after scene load
	await get_tree().create_timer(0.5).timeout
	is_active = true

func _on_body_entered(body):
	# --- 1. GLOBAL LOCK CHECK (SPAWN LOOP PROTECTION) ---
	if Globals.door_locked:
		print("⛔ Door locked (cooldown active), transition rejected.")
		return

	# --- 2. STANDARD CHECKS ---
	if not is_active or not body.is_in_group("player"):
		return

	print("🚪 Door triggered!")

	# --- 3. CASE: EXITING BUILDING ---
	if is_exit_door:
		print("🔙 Returning to Town (Deferred)...")
		
		if UI.has_node("UIRoot"):
			UI.get_node("UIRoot").call_deferred("return_to_town")
		return

	# --- 4. CASE: ENTERING BUILDING ---
	if target_scene_path == "":
		print("⚠️ Error: Target scene path is not set!")
		return

	# Traverse hierarchy to find MainGame
	var current_node = self
	var main_game = null
	
	while current_node:
		if current_node.has_method("enter_house"):
			main_game = current_node
			break
		current_node = current_node.get_parent()
	
	if main_game:
		print("🚪 Entering via MainGame (Deferred)...")
		main_game.call_deferred("enter_house", target_scene_path)
	else:
		# Fallback for isolated scene testing
		print("🛠️ Test mode transition (Deferred)...")
		get_tree().call_deferred("change_scene_to_file", target_scene_path)
