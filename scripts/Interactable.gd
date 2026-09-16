extends Area2D

# 👇 Wardrobe option added
@export_enum("Calendar", "NPC", "Bed", "Chest", "Wardrobe") var interact_type: String = "Calendar"
@export_multiline var dialog_text: String = "Hello!"

# Interaction delay in seconds
@export var wait_time: float = 2.0

# Timer created at runtime
var timer: Timer
var has_triggered: bool = false

func _ready():
	# 1. Create and setup timer
	timer = Timer.new()
	timer.wait_time = wait_time
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	
	# 2. Connect collision detection
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

# --- PLAYER ENTERED AREA ---
func _on_body_entered(body):
	if body.is_in_group("player"):
		print("⏳ Timer started... (" + str(wait_time) + " s)")
		has_triggered = false
		timer.start()

# --- PLAYER EXITED AREA ---
func _on_body_exited(body):
	if body.is_in_group("player"):
		print("❌ Exited area, timer cancelled.")
		timer.stop()
		has_triggered = false

# --- TIMER TIMEOUT ---
func _on_timer_timeout():
	if not has_triggered:
		has_triggered = true
		interact()

# --- INTERACTION LOGIC ---
func interact():
	print("✅ Timer finished! Interaction: ", interact_type)
	
	match interact_type:
		"Calendar":
			open_calendar()
		"Wardrobe":
			open_wardrobe()
		"NPC":
			start_dialog()

# ============================================================
# WARDROBE OVERLAY LOGIC
# ============================================================
func open_wardrobe():
	print("👕 Opening Wardrobe overlay...")
	
	# 1. Instantiate wardrobe scene
	var wardrobe_scn = load("res://scenes/Wardrobe.tscn").instantiate()
	
	# 2. Allow processing when paused
	wardrobe_scn.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 3. Pause game tree
	get_tree().paused = true
	
	# 4. Add child under UIRoot
	if UI.has_node("UIRoot"):
		UI.get_node("UIRoot").add_child(wardrobe_scn)
	else:
		# Fallback: add directly to root tree
		get_tree().root.add_child(wardrobe_scn)

# ============================================================
# CALENDAR OVERLAY LOGIC
# ============================================================
func open_calendar():
	print("📅 Opening Calendar overlay...")
	
	var calendar_scn = load("res://addons/calendar_library/demo/calendar_demo.tscn").instantiate()
	calendar_scn.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	
	if UI.has_node("UIRoot"):
		UI.get_node("UIRoot").add_child(calendar_scn)
	else:
		add_child(calendar_scn)

# ============================================================
# DIALOGUE
# ============================================================
func start_dialog():
	print("💬 NPC: ", dialog_text)
