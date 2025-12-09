extends Node

# Supabase auth bilgileri
var auth_token: String = ""
var user_id: String = ""

# -------------------------
# CACHE SİSTEMİ DEĞİŞKENLERİ
# -------------------------
var data_cache := {}               # RAM cache
var is_dirty := false              # değişiklik var mı?
var debounce_timer := 0.0
var debounce_interval := 60.0      # 1 dakika debounce

var cache_file_path := "user://user_cache.json"


func _ready():
	load_local_cache()


func _process(delta):
	if is_dirty:
		debounce_timer += delta
		if debounce_timer >= debounce_interval:
			save_to_local_cache()
			debounce_timer = 0.0


# -------------------------
# 1. RAM CACHE WRITE
# -------------------------
func set_cached_value(key: String, value):
	data_cache[key] = value
	is_dirty = true


# -------------------------
# 2. LOAD LOCAL CACHE
# -------------------------
func load_local_cache():
	if FileAccess.file_exists(cache_file_path):
		var file := FileAccess.open(cache_file_path, FileAccess.READ)
		var text := file.get_as_text()
		if text != "":
			data_cache = JSON.parse_string(text)
		else:
			data_cache = {}
	else:
		data_cache = {}


# -------------------------
# 3. SAVE LOCAL CACHE (debounce)
# -------------------------
func save_to_local_cache():
	var file := FileAccess.open(cache_file_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data_cache))
	print("[CACHE] Local cache saved to file.")
	is_dirty = false


# -------------------------
# 4. SAVE TO SERVER (Worker)
# -------------------------
func save_to_server():
	if data_cache.size() == 0:
		print("[SERVER] No data to send.")
		return

	var http := HTTPRequest.new()
	add_child(http)

	var url = "https://life-sim-worker.life-simulation.workers.dev/api/save_user_data"

	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + auth_token
	]

	var body = JSON.stringify({
		"user_id": user_id,
		"data": data_cache
	})

	http.request(url, headers, HTTPClient.METHOD_POST, body)
	print("[SERVER] Data sent to backend.")


# -------------------------
# 5. OYUN KAPANIRKEN VE SAHNE DEĞİŞİNCE ÇAĞIR
# -------------------------
func finalize_save():
	save_to_local_cache()
	save_to_server()
