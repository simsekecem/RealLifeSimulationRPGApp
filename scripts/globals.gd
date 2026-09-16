extends Node

# ============================================================
#   GLOBAL STATE
# ============================================================
# Signal for UI update
signal data_updated 
signal sync_finished

var auth_token: String = ""
var user_id: String = ""
var door_locked: bool = false
var next_scene_path: String = "" 
var is_quitting: bool = false 
var last_scene_path := ""
var texture_cache: Dictionary = {}
var is_initial_sync_done: bool = false

var supabase_anon_key: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ6c25kdHN0b256dGZ1YXlvZG1nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAyOTg4OTQsImV4cCI6MjA3NTg3NDg5NH0.UPDS44mZl-YP0UNGqnpPzIedyphNptgnXehax5tUi50" 
var supabase_project_id: String = "rzsndtstonztfuayodmg"

# User cache structure
var cache := {
	"owner_id": "", 
	"user": { 
		"name": "Rookie", 
		"birthdate": "", 
		"level": 1, 
		"experience": 0, 
		"character_id": 1, 
		"fcm_token": "" # Important for FCM push notifications
	},
	"preferences": { "music_volume": 50 }, 
	"gym_log": [],
	"library": [],
	"study_log": [],
	"market_items": [],
	"restaurant": [],
	"calendar_notes": [],
	"wardrobe": [],
	"quests": [],
	"last_quest_gen_date": "",
	"unsynced_changes": false 
}

var save_timer := 0.0
var debounce_seconds := 10.0 if OS.has_feature("web") else 30.0

var cache_path := "user://user_cache.json"
var WEEK_RESET_DAYS := 7

# ============================================================
#   FIREBASE VARIABLES
# ============================================================
var firebase_core
var firebase_messaging

# ============================================================
#   INITIALIZATION
# ============================================================
func _ready():
	load_cache()
	reset_if_week_passed()
	get_tree().set_auto_accept_quit(false)
	
	# Firebase setup (Mobile only)
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		_setup_firebase()

# ============================================================
#   FIREBASE SETUP
# ============================================================
func _setup_firebase():
	print("Firebase setup initializing...")
	
	if Engine.has_singleton("GodotxFirebaseCore"):
		firebase_core = Engine.get_singleton("GodotxFirebaseCore")
		if not firebase_core.core_initialized.is_connected(_on_core_initialized):
			firebase_core.core_initialized.connect(_on_core_initialized)
	
	if Engine.has_singleton("GodotxFirebaseMessaging"):
		firebase_messaging = Engine.get_singleton("GodotxFirebaseMessaging")
		if not firebase_messaging.messaging_token_received.is_connected(_on_fcm_token_received):
			firebase_messaging.messaging_token_received.connect(_on_fcm_token_received)
		
		# Error logging
		if not firebase_messaging.messaging_error.is_connected(func(msg): print("FCM Error: ", msg)):
			firebase_messaging.messaging_error.connect(func(msg): print("FCM Error: ", msg))
	
	# Initialize Core
	if firebase_core:
		firebase_core.initialize()
	else:
		print("GodotxFirebaseCore singleton not found.")

func _on_core_initialized(success: bool):
	if success:
		print("Firebase Core initialized successfully.")
		# Initialize Messaging
		if firebase_messaging:
			firebase_messaging.request_permission()
			firebase_messaging.get_token()
	else:
		print("Firebase Core failed to initialize.")

# Handle received FCM token (Runs only on Mobile platforms)
func _on_fcm_token_received(token: String):
	if token.is_empty():
		return

	# Only process on Android or iOS
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		print("FCM Token Received: ", token)
		
		# Save to local cache
		if not cache["user"].has("fcm_token"):
			cache["user"]["fcm_token"] = ""
		
		cache["user"]["fcm_token"] = token
		save_cache()
		
		# If user is authenticated, sync to server immediately
		if auth_token != "":
			send_to_server_background()
	else:
		# Ignore on PC and Web platforms
		pass
# ============================================================
#   LOCAL SAVE
# ============================================================
func mark_dirty():
	cache["unsynced_changes"] = true
	save_timer = debounce_seconds
	data_updated.emit()

func _process(delta):
	if save_timer > 0:
		save_timer -= delta
		if save_timer <= 0:
			save_cache()

# ============================================================
#   HELPER FUNCTIONS
# ============================================================
func ensure_list(data) -> Array:
	if data == null: return []
	if typeof(data) == TYPE_DICTIONARY and data.has("results"): return data["results"]
	elif typeof(data) == TYPE_ARRAY: return data
	return []

func safe_int(value) -> int: return int(float(str(value)))
func safe_str(value) -> String: return str(value).strip_edges()

func _get_sync_payload() -> Dictionary:
	var payload = cache.duplicate(true)

	if payload.has("preferences"):
		payload.erase("preferences")

	var is_mobile = (OS.get_name() == "Android" or OS.get_name() == "iOS")

	# PC / WEB -> Never send fcm_token
	if not is_mobile:
		if payload.has("user"):
			payload["user"].erase("fcm_token")
	else:
		# Do not send if empty on mobile
		var token = payload["user"].get("fcm_token", "")
		if token == "":
			payload["user"].erase("fcm_token")

	return payload

# ============================================================
#   EXIT AND NOTIFICATION SIGNALS
# ============================================================
func _notification(what):
	# 1. Close request (Exit button or tab close)
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# On web, attempt quick save
		if OS.has_feature("web"):
			print("(WEB) Tab closing. Attempting quick save...")
			save_cache()
			send_to_server_background() 
		else:
			# Safe exit on PC
			print("(PC) Exit request. Syncing data to server...")
			handle_save_and_exit()

	# 2. Focus loss (Tab switch / Alt-Tab / Mobile background)
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		# If Mobile or Web, immediately sync to server
		if OS.has_feature("web") or OS.get_name() == "Android" or OS.get_name() == "iOS":
			print("(WEB/MOBILE) App paused / focus lost. Syncing to server...")
			save_cache()
			send_to_server_background()
			
		# If PC, save to local cache only
		else:
			print("(PC) Window focus lost. Saved to local cache.")
			save_cache()

func handle_save_and_exit():
	if is_quitting: return
	is_quitting = true
	save_cache()
	send_to_server_and_quit()

# ============================================================
#   SERVER SYNCHRONIZATION (SAVE)
# ============================================================
func send_to_server_and_quit():
	if auth_token == "": get_tree().quit(); return

	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_exit_save_completed)
	get_tree().create_timer(17.0).timeout.connect(force_quit)

	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
	print("Sending exit save data...")
	
	var payload = _get_sync_payload()
	http.request("https://life-sim-worker.life-simulation.workers.dev/api/save_all", headers, HTTPClient.METHOD_POST, JSON.stringify(payload))

func _on_exit_save_completed(_result, response_code, _headers, body):
	if response_code == 200:
		print("Exit save successful.")
		cache["unsynced_changes"] = false
		save_cache()
	else:
		print("Save failed. Local data preserved.")
		if body: print("Error: ", body.get_string_from_utf8())
	
	get_tree().quit()

func send_to_server_background():
	call_deferred("_deferred_background_save")

func _deferred_background_save():
	if auth_token == "": return
	
	var http = HTTPRequest.new()
	add_child(http)
	
	http.request_completed.connect(func(res, code, head, body): http.queue_free())
	
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
	
	var payload = _get_sync_payload()
	http.request("https://life-sim-worker.life-simulation.workers.dev/api/save_all", headers, HTTPClient.METHOD_POST, JSON.stringify(payload))

func force_quit():
	get_tree().quit()

# ============================================================
#   SERVER DATA LOADING
# ============================================================
func load_from_server():
	if auth_token == "": 
		is_initial_sync_done = true
		sync_finished.emit()
		return
		
	print("Checking data from server...")
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_load_complete)
	var headers = ["Authorization: Bearer " + auth_token]
	http.request("https://life-sim-worker.life-simulation.workers.dev/api/load_all", headers, HTTPClient.METHOD_GET)

func _on_load_complete(_res, code, _headers, body):
	if code == 200:
		var json = JSON.new()
		var parse_result = json.parse(body.get_string_from_utf8())
		if parse_result == OK:
			var data = json.get_data()
			if typeof(data) == TYPE_DICTIONARY:
				var local_owner = cache.get("owner_id", "")
				if local_owner != "" and local_owner != user_id:
					apply_server_data(data)
				elif cache.get("unsynced_changes", false) == true:
					merge_server_with_local(data)
				else:
					apply_server_data(data)
	else:
		print("Data fetch error: ", code)
		is_initial_sync_done = true 
		sync_finished.emit()

func apply_server_data(data):
	var current_local_token = cache["user"].get("fcm_token", "")
	var is_mobile = (OS.get_name() == "Android" or OS.get_name() == "iOS")

	if data.has("user"):
		var server_user = data["user"]

		# Apply server data
		cache["user"] = server_user

		# Preserve local FCM token on mobile
		if is_mobile and current_local_token != "":
			cache["user"]["fcm_token"] = current_local_token
	
	cache["study_log"] = ensure_list(data.get("study_log"))
	cache["gym_log"] = ensure_list(data.get("gym_log"))
	cache["library"] = ensure_list(data.get("library"))
	cache["market_items"] = ensure_list(data.get("market_items"))
	cache["calendar_notes"] = ensure_list(data.get("calendar_notes"))
	cache["restaurant"] = ensure_list(data.get("restaurant"))
	cache["wardrobe"] = ensure_list(data.get("wardrobe"))
	
	cache["owner_id"] = user_id 
	cache["unsynced_changes"] = false
	save_cache()
	
	is_initial_sync_done = true
	sync_finished.emit() # Signal loading screen to proceed
	data_updated.emit()

# --- Data Merging ---
func merge_server_with_local(server_data):
	var current_local_token = cache["user"].get("fcm_token", "")
	var is_mobile = (OS.get_name() == "Android" or OS.get_name() == "iOS")

	if server_data.has("user"):
		var server_user = server_data["user"]

		cache["user"] = server_user

		if is_mobile and current_local_token != "":
			cache["user"]["fcm_token"] = current_local_token
	
	merge_list("study_log", ensure_list(server_data.get("study_log")))
	merge_list("gym_log", ensure_list(server_data.get("gym_log")))
	merge_list("library", ensure_list(server_data.get("library")))
	merge_list("market_items", ensure_list(server_data.get("market_items")))
	merge_list("calendar_notes", ensure_list(server_data.get("calendar_notes")))
	merge_list("restaurant", ensure_list(server_data.get("restaurant")))
	merge_list("wardrobe", ensure_list(server_data.get("wardrobe")))
	
	cache["owner_id"] = user_id 
	cache["unsynced_changes"] = false
	save_cache()
	send_to_server_background()
	
	is_initial_sync_done = true
	sync_finished.emit()
	data_updated.emit()

# ============================================================
#   MERGE SYSTEM (DEDUPLICATION)
# ============================================================

func merge_list(key: String, server_list: Array):
	var local_list = cache.get(key, [])
	
	# Duplicate server list initially
	var combined_list = server_list.duplicate()
	
	for local_item in local_list:
		var is_match_found = false
		
		# Data type validation
		if typeof(local_item) != TYPE_DICTIONARY:
			if local_item in server_list: is_match_found = true
			if not is_match_found: combined_list.append(local_item)
			continue

		for server_item in server_list:
			if typeof(server_item) != TYPE_DICTIONARY: continue

			# --- 1. GYM LOG LOGIC ---
			if key == "gym_log":
				var l_id = local_item.get("id"); var s_id = server_item.get("id")
				if l_id != null and s_id != null:
					if str(l_id) == str(s_id): is_match_found = true
				elif local_item.get("date") == server_item.get("date") and \
					 local_item.get("exercise_name") == server_item.get("exercise_name"):
					is_match_found = true
			
			# --- 2. WARDROBE LOGIC ---
			elif key == "wardrobe":
				if local_item.get("image_url") == server_item.get("image_url"):
					is_match_found = true
					var idx = combined_list.find(server_item)
					if idx != -1: combined_list[idx] = local_item 
					break

			# --- 3. LIBRARY ID LOGIC (CONFLICT PREVENTION) ---
			elif key == "library":
				var l_id = local_item.get("id")
				var s_id = server_item.get("id")
				var l_title = local_item.get("title", "")
				var s_title = server_item.get("title", "")

				# A) ID Match (Safest)
				if l_id != null and s_id != null and str(l_id) == str(s_id):
					is_match_found = true
					# Overwrite server data with updated local data
					var idx = combined_list.find(server_item)
					if idx != -1: combined_list[idx] = local_item
					break
				
				# B) Title Match (If ID missing)
				elif l_title == s_title:
					is_match_found = true
					# Inherit server ID if local is missing
					if l_id == null and s_id != null:
						local_item["id"] = s_id
					
					var idx = combined_list.find(server_item)
					if idx != -1: combined_list[idx] = local_item
					break

			# --- 4. QUESTS LOGIC ---
			elif key == "quests":
				if str(local_item.get("id")) == str(server_item.get("id")):
					is_match_found = true
					var l_done = local_item.get("is_completed", false)
					if l_done: 
						var idx = combined_list.find(server_item)
						if idx != -1: combined_list[idx] = local_item
					break

			# --- 5. OTHER DATA (Hash comparison) ---
			else:
				if local_item.hash() == server_item.hash(): 
					is_match_found = true
			
			if is_match_found: break
		
		if not is_match_found:
			combined_list.append(local_item)
			
	cache[key] = combined_list
# ============================================================
#   CACHE MANAGEMENT
# ============================================================
func load_cache():
	if not FileAccess.file_exists(cache_path):
		save_cache()
		return

	var file = FileAccess.open(cache_path, FileAccess.READ)
	if file:
		var text = file.get_as_text()
		file.close()

		var json = JSON.new()
		var parse_result = json.parse(text)
		if parse_result == OK:
			var data = json.get_data()
			if typeof(data) == TYPE_DICTIONARY:
				# Update existing keys
				for key in data.keys():
					if cache.has(key):
						if key == "user" and typeof(data[key]) == TYPE_DICTIONARY:
							for u_key in data[key].keys():
								cache["user"][u_key] = data[key][u_key]
						else:
							cache[key] = data[key]
					else:
						# Append newly introduced keys (e.g. wardrobe)
						cache[key] = data[key]

				# Ensure wardrobe array exists
				if not cache.has("wardrobe"):
					cache["wardrobe"] = []

				print("Local cache loaded.")
			else:
				print("Cache file corrupted, resetting.")
				save_cache()
		else:
			print("JSON parse error: ", json.get_error_message())
			save_cache()

func save_cache():
	var file = FileAccess.open(cache_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(cache))
		file.close()

# ============================================================
#   WEEKLY RESET
# ============================================================
func reset_if_week_passed():
	var meta_path = "user://cache_meta.json"
	if not FileAccess.file_exists(meta_path):
		var f = FileAccess.open(meta_path, FileAccess.WRITE)
		f.store_string(JSON.stringify({ "last_reset": Time.get_unix_time_from_system() }))
		return
	var file = FileAccess.open(meta_path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	if Time.get_unix_time_from_system() - data.get("last_reset", 0) > WEEK_RESET_DAYS * 24 * 3600:
		weekly_reset()
		var f = FileAccess.open(meta_path, FileAccess.WRITE)
		f.store_string(JSON.stringify({ "last_reset": Time.get_unix_time_from_system() }))

func weekly_reset():
	cache["gym_log"].clear()
	cache["study_log"].clear()
	cache["restaurant"].clear()
	cache["calendar_notes"].clear()
	mark_dirty()
	save_cache()
	
func prepare_for_user(new_user_id: String):
	var local_owner = cache.get("owner_id", "")
	
	# If cache belongs to a different user, reset to default
	if local_owner != "" and local_owner != new_user_id:
		print("Different user detected. Resetting local cache...")
		_reset_cache_to_default()
	
	# Assign new user ID
	user_id = new_user_id
	cache["owner_id"] = new_user_id

func _reset_cache_to_default():
	# Reset cache to default player template
	cache = {
		"owner_id": "", 
		"user": { 
			"name": "Rookie", 
			"birthdate": "", 
			"level": 1, 
			"experience": 0, 
			"character_id": 1, 
			"fcm_token": "" 
		},
		"preferences": { "music_volume": 50 }, 
		"gym_log": [],
		"library": [],
		"study_log": [],
		"market_items": [],
		"restaurant": [],
		"calendar_notes": [],
		"wardrobe": [],
		"quests": [],
		"last_quest_gen_date": "",
		"unsynced_changes": false 
	}

# ============================================================
#   SCENE TRANSITIONS
# ============================================================
func change_scene_with_loading(target_path: String):
	save_cache()
	
	if OS.has_feature("web") and auth_token != "":
		if target_path != last_scene_path and cache.get("unsynced_changes", false):
			send_to_server_background()
			cache["unsynced_changes"] = false
	
	last_scene_path = target_path
	next_scene_path = target_path
	get_tree().change_scene_to_file("res://scenes/UserInterface/LoadingScreen.tscn")
	
# ============================================================
#   LEVEL & XP SYSTEM
# ============================================================
func get_required_xp(lvl: int) -> int:
	return (lvl * 200) + 100

func add_xp(amount: int):
	var current_xp = int(cache["user"].get("experience", 0))
	var current_lvl = int(cache["user"].get("level", 1))
	
	current_xp += amount
	print("XP Gained: ", amount, " | Current: ", current_xp)
	
	# Calculate threshold for next level
	var xp_needed = get_required_xp(current_lvl)
	
	# Level up processing loop
	while current_xp >= xp_needed:
		current_xp -= xp_needed
		current_lvl += 1
		print("LEVEL UP! New Level: ", current_lvl)
		
		# Level 2 Reward (Character Evolution)
		if current_lvl == 2:
			print("Special Reward: Character 2 unlocked!")
			
			var qm = get_node_or_null("/root/QuestManager")
			if qm and qm.has_method("show_unlock_popup"):
				get_tree().create_timer(7.0).timeout.connect(
					qm.show_unlock_popup.bind(2)
				)
		
		xp_needed = get_required_xp(current_lvl)
	
	# Save updated progress
	cache["user"]["experience"] = current_xp
	cache["user"]["level"] = current_lvl
	
	save_cache()
	data_updated.emit()
