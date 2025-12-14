extends Node

# ============================================================
#  GLOBAL STATE
# ============================================================
var auth_token: String = ""
var user_id: String = ""

# --- LOADING SCREEN İÇİN GEREKLİ DEĞİŞKEN ---
var next_scene_path: String = "" # <--- YENİ EKLENDİ: Sırada hangi sahne var?

var cache := {
	"user": { "name": "", "birthdate": "" },
	"preferences": { "music_volume": 50 },
	"gym_log": [],
	"library": [],
	"study_log": [],
	"market_items": [],
	"restaurant": [],
	"calendar_notes": []
}

var save_timer := 0.0
var debounce_seconds := 60.0

var cache_path := "user://user_cache.json"
var WEEK_RESET_DAYS := 7

# ============================================================
#  READY
# ============================================================
func _ready():
	load_cache()
	reset_if_week_passed()

# ============================================================
#  SAVE DEBOUNCE
# ============================================================
func mark_dirty():
	save_timer = debounce_seconds

func _process(delta):
	if save_timer > 0:
		save_timer -= delta
		if save_timer <= 0:
			save_cache()

# ============================================================
#  LOAD CACHE (LOCAL JSON)
# ============================================================
func load_cache():
	if not FileAccess.file_exists(cache_path):
		save_cache()
		return

	var file = FileAccess.open(cache_path, FileAccess.READ)
	if not file:
		return

	var text := file.get_as_text()
	var data := {}

	if text != "":
		data = JSON.parse_string(text)

	if typeof(data) == TYPE_DICTIONARY:
		cache = data


# ============================================================
#  SAVE CACHE (LOCAL JSON)
# ============================================================
func save_cache():
	var file = FileAccess.open(cache_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(cache))

# ============================================================
#  WEEKLY RESET
# ============================================================
func reset_if_week_passed():
	var meta_path = "user://cache_meta.json"

	if not FileAccess.file_exists(meta_path):
		var file = FileAccess.open(meta_path, FileAccess.WRITE)
		file.store_string(JSON.stringify({ "last_reset": Time.get_unix_time_from_system() }))
		return

	var file = FileAccess.open(meta_path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())

	var last_reset = data.get("last_reset", 0)
	var now = Time.get_unix_time_from_system()

	if now - last_reset > WEEK_RESET_DAYS * 24 * 3600:
		print("Weekly reset triggered")
		weekly_reset()

		var f = FileAccess.open(meta_path, FileAccess.WRITE)
		f.store_string(JSON.stringify({ "last_reset": now }))

func weekly_reset():
	cache["gym_log"].clear()
	cache["study_log"].clear()
	cache["restaurant"].clear()
	cache["calendar_notes"].clear()
	save_cache()

# ============================================================
#  WRITE HELPERS
# ============================================================
func set_user_info(name: String, birthdate: String):
	cache["user"]["name"] = name
	cache["user"]["birthdate"] = birthdate
	mark_dirty()

func set_music_volume(vol: int):
	cache["preferences"]["music_volume"] = vol
	mark_dirty()

func add_gym_entry(entry: Dictionary):
	for i in range(cache["gym_log"].size()):
		var e = cache["gym_log"][i]
		if e["date"] == entry["date"] and e["exercise_name"] == entry["exercise_name"]:
			cache["gym_log"][i] = entry
			mark_dirty()
			return

	cache["gym_log"].append(entry)
	mark_dirty()

func add_market_item(item: Dictionary):
	for i in range(cache["market_items"].size()):
		var e = cache["market_items"][i]
		if e["category"] == item["category"] and e["item_name"] == item["item_name"]:
			cache["market_items"][i] = item
			mark_dirty()
			return

	cache["market_items"].append(item)
	mark_dirty()

func add_calendar_note(note: Dictionary):
	for i in range(cache["calendar_notes"].size()):
		var e = cache["calendar_notes"][i]
		if e["date"] == note["date"]:
			cache["calendar_notes"][i] = note
			mark_dirty()
			return

	cache["calendar_notes"].append(note)
	mark_dirty()

# ============================================================
#  SYNC FROM SERVER (LOGIN SONRASI)
# ============================================================
func load_from_server():
	if auth_token == "":
		print("Cannot load — no auth token.")
		return

	print("Requesting user data from server...")

	var headers = [
		"Authorization: Bearer " + auth_token
	]

	var http = HTTPRequest.new()
	add_child(http)

	http.request_completed.connect(_on_load_complete)

	http.request(
		"https://life-sim-worker.life-simulation.workers.dev/api/load_all",
		headers,
		HTTPClient.METHOD_GET
	)

func _on_load_complete(_res, code, _headers, body):
	if code != 200:
		print("❌ Failed to load user data:", code)
		return

	var data = JSON.parse_string(body.get_string_from_utf8())

	if typeof(data) != TYPE_DICTIONARY:
		print("❌ Invalid load response", data)
		return

	# D1 → Local Cache Mapping
	cache["user"] = data.get("user", { "name": "", "birthdate": "" })
	cache["preferences"] = data.get("preferences", { "music_volume": 50 })
	cache["library"] = data.get("library", [])
	cache["study_log"] = data.get("study_log", [])
	cache["gym_log"] = data.get("gym_log", [])
	cache["market_items"] = data.get("market_items", [])
	cache["restaurant"] = data.get("restaurant", [])
	cache["calendar_notes"] = data.get("calendar_notes", [])

	save_cache()

	print("✅ User data synchronized from server.")

# ============================================================
#  SEND TO SERVER (KAPANIŞTA)
# ============================================================
func send_to_server():
	if auth_token == "":
		print("No auth token — skipping save.")
		return

	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + auth_token
	]

	var http = HTTPRequest.new()
	add_child(http)

	http.request(
		"https://life-sim-worker.life-simulation.workers.dev/api/save_all",
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(cache)
	)

	print("Cache sent to server.")

# ============================================================
#  EXIT & SCENE MANAGEMENT
# ============================================================
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_cache()
		send_to_server()
		# Not: send_to_server asenkron olduğu için quit hemen çalışırsa 
		# veri gitmeyebilir. İdeal dünyada 'request_completed' beklemek lazım
		# ama şimdilik böyle kalsın.
		get_tree().quit()

func safe_local_save():
	save_cache()

func finalize_save():
	save_cache()
	send_to_server()

# --- YENİ EKLENDİ: SAHNE DEĞİŞTİRME FONKSİYONU ---
func change_scene_with_loading(target_scene_path: String):
	"""
	Bu fonksiyonu herhangi bir yerden çağırarak Loading Screen ile 
	sahne değiştirebilirsin.
	Örn: Globals.change_scene_with_loading("res://scenes/MainGame.tscn")
	"""
	# 1. Önce mevcut verileri kaydet (Garanti olsun)
	safe_local_save()
	
	# 2. Hedef sahneyi ayarla
	next_scene_path = target_scene_path
	
	# 3. Loading ekranına git
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")
