extends Control

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var label: Label = $Label

# --------------------
# SETTINGS
# --------------------
const MIN_PROGRESS_THRESHOLD: float = 20.0
const MIN_LOADING_TIME: float = 1.0
const SMOOTH_RATE: float = 5.0

const DOT_CHANGE_RATE: float = 0.25
const MAX_DOTS: int = 4

# --------------------
# VARIABLES
# --------------------
var dot_timer: float = 0.0
var current_dot_count: int = 0
var target_scene_path: String = ""
var progress: Array = []
var load_status: int = 0
var loading_time: float = 0.0
var is_loaded: bool = false
var current_progress: float = 0.0 
var finish_speed: float = 0.0

# --------------------
# READY
# --------------------
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)

	if UI.has_node("UIRoot"):
		UI.get_node("UIRoot").hide_all_ui()

	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = MIN_PROGRESS_THRESHOLD
	current_progress = MIN_PROGRESS_THRESHOLD

	label.text = "Loading"

	# Start background server data sync
	Globals.load_from_server()

	target_scene_path = Globals.next_scene_path
	if target_scene_path == "":
		print("❌ Error: Target scene path is empty!")
		return

	ResourceLoader.load_threaded_request(target_scene_path)
	print("⏳ Scene loading and data synchronization started...")

# --------------------
# PROCESS
# --------------------
func _process(delta: float) -> void:
	loading_time += delta
	
	# 1. Dot animation and label update
	dot_timer += delta
	if dot_timer >= DOT_CHANGE_RATE:
		dot_timer = 0.0
		current_dot_count = (current_dot_count + 1) % (MAX_DOTS + 1)
		
		# If scene is loaded but initial sync is still running, show Syncing Data
		if is_loaded and not Globals.is_initial_sync_done:
			label.text = "Syncing Data" + ".".repeat(current_dot_count)
		else:
			label.text = "Loading" + ".".repeat(current_dot_count)

	# 2. Progress status and interpolation
	load_status = ResourceLoader.load_threaded_get_status(target_scene_path, progress)

	var target_progress: float = MIN_PROGRESS_THRESHOLD

	if not is_loaded:
		if progress.size() > 0:
			var actual_pct: float = progress[0] * 100.0
			target_progress = clamp(actual_pct, MIN_PROGRESS_THRESHOLD, 90.0)
		else:
			target_progress = lerp(MIN_PROGRESS_THRESHOLD, 90.0, loading_time / MIN_LOADING_TIME)
			target_progress = clamp(target_progress, MIN_PROGRESS_THRESHOLD, 90.0)
			
		current_progress = lerp(current_progress, target_progress, delta * SMOOTH_RATE)
		
		if load_status == ResourceLoader.THREAD_LOAD_LOADED:
			is_loaded = true
			var time_remaining = max(0.01, MIN_LOADING_TIME - loading_time) 
			finish_speed = 1.0 / time_remaining
			print("✅ Scene resource loaded. Awaiting data sync...")

	else:
		# Scene loaded, push to 100%
		current_progress = lerp(current_progress, 100.0, delta * finish_speed)
		
	progress_bar.value = current_progress

	# --------------------
	# 3. Scene transition
	# --------------------
	# Requirements: Scene loaded + Bar full + Initial server sync complete
	if is_loaded and current_progress >= 99.9 and Globals.is_initial_sync_done:
		progress_bar.value = 100
		await get_tree().process_frame
		set_process(false)

		print("🚀 Data ready, switching scene!")
		var new_scene = ResourceLoader.load_threaded_get(target_scene_path)
		get_tree().change_scene_to_packed(new_scene)

	elif load_status == ResourceLoader.THREAD_LOAD_FAILED:
		print("❌ Error: Scene failed to load!")
		set_process(false)
