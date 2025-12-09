extends Node

@onready var http := $HTTPRequest

func _ready():
	print("🔄 Town: loading remote data...")
	load_remote_data()


func load_remote_data():
	if Globals.auth_token == "":
		print("⚠️ No token — skipping remote sync")
		return

	var headers = [
		"Authorization: Bearer " + Globals.auth_token
	]

	var url = "https://life-sim-worker.life-simulation.workers.dev/api/load_all"

	http.request(url, headers, HTTPClient.METHOD_GET)
	http.request_completed.connect(_on_load_response)

func _on_load_response(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray):
	if code != 200:
		print("❌ Remote load failed:", code)
		return

	var data = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) != TYPE_DICTIONARY:
		print("❌ Invalid JSON:", data)
		return

	print("✅ Remote data loaded:", data)

	_apply_remote_to_cache(data)


func _apply_remote_to_cache(data: Dictionary):
	# USER
	if data.has("user") and data["user"] != null:
		Globals.cache["user"]["name"] = data["user"].get("name", "")
		Globals.cache["user"]["birthdate"] = data["user"].get("birthdate", "")

	# PREFERENCES
	if data.has("preferences") and data["preferences"] != null:
		Globals.cache["preferences"]["music_volume"] = data["preferences"].get("music_volume", 50)

	# ARRAYS
	Globals.cache["library"] = data.get("library", [])
	Globals.cache["study_log"] = data.get("study_log", [])
	Globals.cache["gym_log"] = data.get("gym_log", [])
	Globals.cache["market_items"] = data.get("market_items", [])
	Globals.cache["restaurant"] = data.get("restaurant", [])
	Globals.cache["calendar_notes"] = data.get("calendar_notes", [])

	# Local JSON güncelle
	Globals.save_cache()

	print("💾 Local cache synced with server.")
