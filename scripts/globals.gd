extends Node

# ============================================================
#  GLOBAL STATE
# ============================================================
var auth_token: String = ""
var user_id: String = ""
var door_locked: bool = false
var next_scene_path: String = "" 
var is_quitting: bool = false 

var cache := {
	"user": { "name": "", "birthdate": "" },
	"preferences": { "music_volume": 50 },
	"gym_log": [],
	"library": [],
	"study_log": [],
	"market_items": [],
	"restaurant": [],
	"calendar_notes": [],
	"unsynced_changes": false 
}

var save_timer := 0.0
var debounce_seconds := 30.0
var cache_path := "user://user_cache.json"
var WEEK_RESET_DAYS := 7

# ============================================================
#  BAŞLANGIÇ AYARLARI
# ============================================================
func _ready():
	load_cache()
	reset_if_week_passed()
	get_tree().set_auto_accept_quit(false)

# ============================================================
#  YEREL KAYIT (LOCAL SAVE)
# ============================================================
func mark_dirty():
	cache["unsynced_changes"] = true
	save_timer = debounce_seconds

func _process(delta):
	if save_timer > 0:
		save_timer -= delta
		if save_timer <= 0:
			save_cache()

# ============================================================
#  HELPER FONKSİYONLAR
# ============================================================
func ensure_list(data) -> Array:
	if typeof(data) == TYPE_DICTIONARY and data.has("results"): return data["results"]
	elif typeof(data) == TYPE_ARRAY: return data
	return []

func safe_int(value) -> int: return int(float(str(value)))
func safe_str(value) -> String: return str(value).strip_edges()

# ============================================================
#  ÇIKIŞ VE ARKA PLAN SİNYALLERİ
# ============================================================
func _notification(what):
	# 1. PC: Çarpı tuşu
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("🛑 (PC) Çıkış. Veriler sunucuya gönderiliyor...")
		handle_save_and_exit()

	# 2. MOBİL: Uygulama arka plana atıldı
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		print("📱 (MOBİL) Arka plan. Yerel kayıt alınıyor...")
		save_cache() 
		# Arka planda gönderme işlemini erteliyoruz (Deferred)
		# Bu sayede "Parent is busy" hatası almıyoruz.
		send_to_server_background()

func handle_save_and_exit():
	if is_quitting: return
	is_quitting = true
	save_cache()
	send_to_server_and_quit()

# ============================================================
#  SUNUCUYA GÖNDERME (SENKRONİZASYON)
# ============================================================
func send_to_server_and_quit():
	if auth_token == "": get_tree().quit(); return

	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_exit_save_completed)
	get_tree().create_timer(3.0).timeout.connect(force_quit)

	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
	print("📡 Kapanış verisi gönderiliyor...")
	http.request("https://life-sim-worker.life-simulation.workers.dev/api/save_all", headers, HTTPClient.METHOD_POST, JSON.stringify(cache))

func _on_exit_save_completed(_result, response_code, _headers, body):
	if response_code == 200:
		print("✅ Kapanış kaydı BAŞARILI!")
		cache["unsynced_changes"] = false
		save_cache()
	else:
		print("❌ Kayıt başarısız. Yerel veri korunuyor.")
		if body: print("🔥 Hata: ", body.get_string_from_utf8())
	
	get_tree().quit()

# ------------------------------------------------------------------
# DÜZELTME: "Parent Busy" Hatasını Çözen Arka Plan Gönderimi
# ------------------------------------------------------------------
func send_to_server_background():
	# HATA ÇÖZÜMÜ: add_child işlemini hemen yapma, bir sonraki kareye ertele.
	# Böylece Godot meşgulken düğüm eklemeye çalışıp hata vermez.
	call_deferred("_deferred_background_save")

func _deferred_background_save():
	if auth_token == "": return
	
	var http = HTTPRequest.new()
	add_child(http)
	
	# İşlem bitince bu node'u silmek bellek için iyi olur
	http.request_completed.connect(func(res, code, head, body): http.queue_free())
	
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
	http.request("https://life-sim-worker.life-simulation.workers.dev/api/save_all", headers, HTTPClient.METHOD_POST, JSON.stringify(cache))
# ------------------------------------------------------------------

func force_quit():
	get_tree().quit()

# ============================================================
#  SUNUCUDAN YÜKLEME (AKILLI BİRLEŞTİRME / SMART MERGE)
# ============================================================
func load_from_server():
	if auth_token == "": return
	print("⬇️ Sunucudan veriler kontrol ediliyor...")
	
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
				
				if cache.get("unsynced_changes", false) == true:
					print("⚠️ ÇAKIŞMA: Sunucu ve Yerel veri birleştiriliyor...")
					merge_server_with_local(data)
				else:
					apply_server_data(data)
					print("✅ Veriler sunucudan alındı.")
	else:
		print("❌ Veri çekme hatası: ", code)

# --- Veri Uygulama ---
func apply_server_data(data):
	if data.has("user"): cache["user"] = data["user"]
	if data.has("preferences"): cache["preferences"] = data["preferences"]
	
	cache["study_log"] = ensure_list(data.get("study_log"))
	cache["gym_log"] = ensure_list(data.get("gym_log"))
	cache["library"] = ensure_list(data.get("library"))
	cache["market_items"] = ensure_list(data.get("market_items"))
	cache["calendar_notes"] = ensure_list(data.get("calendar_notes"))
	cache["restaurant"] = ensure_list(data.get("restaurant"))
	
	cache["unsynced_changes"] = false
	save_cache()

# --- Veri Birleştirme ---
func merge_server_with_local(server_data):
	if server_data.has("user"): cache["user"] = server_data["user"]
	if server_data.has("preferences"): cache["preferences"] = server_data["preferences"]
	
	merge_list("study_log", ensure_list(server_data.get("study_log")))
	merge_list("gym_log", ensure_list(server_data.get("gym_log")))
	merge_list("library", ensure_list(server_data.get("library")))
	merge_list("market_items", ensure_list(server_data.get("market_items")))
	merge_list("calendar_notes", ensure_list(server_data.get("calendar_notes")))
	merge_list("restaurant", ensure_list(server_data.get("restaurant")))
	
	print("🤝 Veriler birleştirildi. Sunucuya geri yükleniyor...")
	cache["unsynced_changes"] = false
	save_cache()
	send_to_server_background()

func merge_list(key: String, server_list: Array):
	var local_list = cache[key]
	var combined_list = server_list.duplicate()
	
	for local_item in local_list:
		var is_present = false
		for server_item in server_list:
			if local_item.hash() == server_item.hash():
				is_present = true
				break
		
		if not is_present:
			combined_list.append(local_item)
	
	cache[key] = combined_list

# ============================================================
#  CACHE YÖNETİMİ
# ============================================================
func load_cache():
	if not FileAccess.file_exists(cache_path):
		save_cache()
		return
	var file = FileAccess.open(cache_path, FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		if typeof(data) == TYPE_DICTIONARY:
			cache = data

func save_cache():
	var file = FileAccess.open(cache_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(cache))

# ============================================================
#  HAFTALIK RESET
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

# ============================================================
#  SAHNE GEÇİŞİ
# ============================================================
func change_scene_with_loading(target_path: String):
	save_cache()
	next_scene_path = target_path
	get_tree().change_scene_to_file("res://scenes/UserInterface/LoadingScreen.tscn")
