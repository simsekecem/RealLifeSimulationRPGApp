extends Node

# ============================================================
#   GLOBAL STATE
# ============================================================
# 👇 UI güncellemesi için sinyal
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

# 👇 GÜNCELLEME: "fcm_token" alanını buraya ekledim.
var cache := {
	"owner_id": "", 
	"user": { 
		"name": "Rookie", 
		"birthdate": "", 
		"level": 1, 
		"experience": 0, 
		"character_id": 1, 
		"fcm_token": "" # <-- BURASI ÖNEMLİ
	},
	"preferences": { "music_volume": 50 }, 
	"gym_log": [],
	"library": [],
	"study_log": [],
	"market_items": [],
	"restaurant": [],
	"calendar_notes": [],
	"wardrobe": [],
	"quests": [],             # 👈 BU SATIR EKSİKTİ
	"last_quest_gen_date": "", # 👈 BU SATIR EKSİKTİ
	"unsynced_changes": false 
}

var save_timer := 0.0
var debounce_seconds := 10.0 if OS.has_feature("web") else 30.0

var cache_path := "user://user_cache.json"
var WEEK_RESET_DAYS := 7

# ============================================================
#   FIREBASE DEĞİŞKENLERİ
# ============================================================
var firebase_core
var firebase_messaging

# ============================================================
#   BAŞLANGIÇ AYARLARI
# ============================================================
func _ready():
	load_cache()
	reset_if_week_passed()
	get_tree().set_auto_accept_quit(false)
	
	# 👇 YENİ: Firebase Kurulumu (Sadece Mobilde)
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		_setup_firebase()

# ============================================================
#   FIREBASE KURULUMU
# ============================================================
func _setup_firebase():
	print("🔥 Firebase kurulumu başlıyor...")
	
	if Engine.has_singleton("GodotxFirebaseCore"):
		firebase_core = Engine.get_singleton("GodotxFirebaseCore")
		if not firebase_core.core_initialized.is_connected(_on_core_initialized):
			firebase_core.core_initialized.connect(_on_core_initialized)
	
	if Engine.has_singleton("GodotxFirebaseMessaging"):
		firebase_messaging = Engine.get_singleton("GodotxFirebaseMessaging")
		if not firebase_messaging.messaging_token_received.is_connected(_on_fcm_token_received):
			firebase_messaging.messaging_token_received.connect(_on_fcm_token_received)
		
		# Hata loglarını görmek için
		if not firebase_messaging.messaging_error.is_connected(func(msg): print("❌ FCM Hatası: ", msg)):
			firebase_messaging.messaging_error.connect(func(msg): print("❌ FCM Hatası: ", msg))
	
	# Core başlat
	if firebase_core:
		firebase_core.initialize()
	else:
		print("❌ GodotxFirebaseCore bulunamadı.")

func _on_core_initialized(success: bool):
	if success:
		print("✅ Firebase Core BAŞARILI!")
		# Messaging başlat
		if firebase_messaging:
			firebase_messaging.request_permission()
			firebase_messaging.get_token()
	else:
		print("❌ Firebase Core başlatılamadı.")

# 👇 KRİTİK BÖLÜM: Token Gelince Ne Yapıyoruz?
func _on_fcm_token_received(token: String):
	if token.is_empty():
		return

	print("🔥 FCM TOKEN ALINDI VE CACHE'E YAZILDI: ", token)
	
	# 1. Token'ı yerel hafızaya (Cache) yaz
	if not cache["user"].has("fcm_token"):
		cache["user"]["fcm_token"] = ""
	
	cache["user"]["fcm_token"] = token
	save_cache()
	
	# 2. Eğer kullanıcı ZATEN içerideyse (Auth Token varsa),
	#    Hiç beklemeden bu yeni token'ı sunucuya "Save All" paketiyle gönder.
	if auth_token != "":
		print("🔄 Token sunucuya senkronize ediliyor...")
		send_to_server_background()

# ============================================================
#   YEREL KAYIT (LOCAL SAVE)
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
#   HELPER FONKSİYONLAR
# ============================================================
func ensure_list(data) -> Array:
	if data == null: return []
	if typeof(data) == TYPE_DICTIONARY and data.has("results"): return data["results"]
	elif typeof(data) == TYPE_ARRAY: return data
	return []

func safe_int(value) -> int: return int(float(str(value)))
func safe_str(value) -> String: return str(value).strip_edges()

func _get_sync_payload() -> Dictionary:
	# Cache'i kopyala. Token zaten cache["user"] içinde olduğu için
	# otomatik olarak pakete dahil edilecek!
	var payload = cache.duplicate(true)
	if payload.has("preferences"):
		payload.erase("preferences") 
	return payload

# ============================================================
#   ÇIKIŞ VE ARKA PLAN SİNYALLERİ
# ============================================================
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("🛑 (PC) Çıkış. Veriler sunucuya gönderiliyor...")
		handle_save_and_exit()

	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		print("📱 (MOBİL) Arka plan. Yerel kayıt alınıyor...")
		save_cache() 
		send_to_server_background()

func handle_save_and_exit():
	if is_quitting: return
	is_quitting = true
	save_cache()
	send_to_server_and_quit()

# ============================================================
#   SUNUCUYA GÖNDERME (SENKRONİZASYON)
# ============================================================
func send_to_server_and_quit():
	if auth_token == "": get_tree().quit(); return

	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_exit_save_completed)
	get_tree().create_timer(17.0).timeout.connect(force_quit)

	var headers = ["Content-Type: application/json", "Authorization: Bearer " + auth_token]
	print("📡 Kapanış verisi gönderiliyor...")
	
	var payload = _get_sync_payload()
	http.request("https://life-sim-worker.life-simulation.workers.dev/api/save_all", headers, HTTPClient.METHOD_POST, JSON.stringify(payload))

func _on_exit_save_completed(_result, response_code, _headers, body):
	if response_code == 200:
		print("✅ Kapanış kaydı BAŞARILI!")
		cache["unsynced_changes"] = false
		save_cache()
	else:
		print("❌ Kayıt başarısız. Yerel veri korunuyor.")
		if body: print("🔥 Hata: ", body.get_string_from_utf8())
	
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
#   SUNUCUDAN YÜKLEME
# ============================================================
func load_from_server():
	if auth_token == "": 
		is_initial_sync_done = true
		sync_finished.emit()
		return
		
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
				var local_owner = cache.get("owner_id", "")
				if local_owner != "" and local_owner != user_id:
					apply_server_data(data)
				elif cache.get("unsynced_changes", false) == true:
					merge_server_with_local(data)
				else:
					apply_server_data(data)
	else:
		print("❌ Veri çekme hatası: ", code)
		is_initial_sync_done = true 
		sync_finished.emit()

func apply_server_data(data):
	var current_local_token = cache["user"].get("fcm_token", "")
	if data.has("user"): cache["user"] = data["user"]
	if cache["user"].get("fcm_token", "") == "" and current_local_token != "":
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
	sync_finished.emit() # 👈 Yükleme ekranına "geçebilirsin" haberi ver
	data_updated.emit()

# --- Veri Birleştirme ---
func merge_server_with_local(server_data):
	var current_local_token = cache["user"].get("fcm_token", "")
	if server_data.has("user"): cache["user"] = server_data["user"]
	if cache["user"].get("fcm_token", "") == "" and current_local_token != "":
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
# 👇 GÜNCELLENMİŞ MERGE SİSTEMİ (Çift Kayıt Önleyici)
# ============================================================
func merge_list(key: String, server_list: Array):
	var local_list = cache.get(key, [])
	
	# Başlangıçta server listesini kopyala (Eski veriler burada)
	var combined_list = server_list.duplicate()
	
	for local_item in local_list:
		var is_match_found = false
		
		# Veri tipi kontrolü (Hata önleyici)
		if typeof(local_item) != TYPE_DICTIONARY:
			# Basit veriyse (string vs) direkt listede var mı bak
			if local_item in server_list: is_match_found = true
			if not is_match_found: combined_list.append(local_item)
			continue

		for server_item in server_list:
			if typeof(server_item) != TYPE_DICTIONARY: continue

			# --- GYM LOG MANTIĞI ---
			if key == "gym_log":
				var l_id = local_item.get("id"); var s_id = server_item.get("id")
				if l_id != null and s_id != null:
					if str(l_id) == str(s_id): is_match_found = true
				elif local_item.get("date") == server_item.get("date") and \
					 local_item.get("exercise_name") == server_item.get("exercise_name"):
					is_match_found = true
			
			# --- 🔥 WARDROBE MANTIĞI (Edit Sorunu Çözümü) ---
			elif key == "wardrobe":
				# Kıyafetlerde kimlik kartımız "image_url"dir.
				if local_item.get("image_url") == server_item.get("image_url"):
					is_match_found = true
					
					# 🔥 KRİTİK NOKTA: Eşleşme varsa, LOCAL veriyi kullan!
					# Çünkü Local veri, kullanıcının az önce yaptığı düzenlemeyi içerir.
					# Server verisi henüz güncellenmemiş eski veridir.
					var idx = combined_list.find(server_item)
					if idx != -1:
						combined_list[idx] = local_item # Eski veriyi yenisiyle ez
					break

			# --- DİĞERLERİ (Hash Kontrolü) ---
			else:
				if local_item.hash() == server_item.hash(): 
					is_match_found = true
			
			if is_match_found: break
		
		# Eğer serverda hiç yoksa (Yeni eklenen eşya), listeye ekle
		if not is_match_found:
			combined_list.append(local_item)
			
	cache[key] = combined_list
# ============================================================
#   CACHE YÖNETİMİ
# ============================================================
# globals.gd içindeki load_cache fonksiyonunu bu şekilde güncelle:

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
				# Var olan anahtarları güncelle
				for key in data.keys():
					if cache.has(key):
						if key == "user" and typeof(data[key]) == TYPE_DICTIONARY:
							for u_key in data[key].keys():
								cache["user"][u_key] = data[key][u_key]
						else:
							cache[key] = data[key]
					else:
						# Yeni gelen anahtarları ekle (örneğin wardrobe)
						cache[key] = data[key]

				# wardrobe yoksa boş array oluştur
				if not cache.has("wardrobe"):
					cache["wardrobe"] = []

				print("✅ Yerel cache yüklendi (wardrobe dahil).")
			else:
				print("❌ Cache dosyası bozuk, sıfırlanıyor.")
				save_cache()
		else:
			print("❌ JSON parse hatası: ", json.get_error_message())
			save_cache()


func save_cache():
	var file = FileAccess.open(cache_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(cache))
		file.close()

# ============================================================
#   HAFTALIK RESET
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
	
	# Eğer cache'in bir sahibi varsa VE bu sahip yeni giren kişi değilse:
	if local_owner != "" and local_owner != new_user_id:
		print("⚠️ GÜVENLİK: Farklı bir kullanıcı tespit edildi! Eski veriler temizleniyor...")
		_reset_cache_to_default()
	
	# Yeni ID'yi güvenle ata
	user_id = new_user_id
	cache["owner_id"] = new_user_id

func _reset_cache_to_default():
	# Cache'i varsayılan, boş bir oyuncu haline getiriyoruz.
	# Böylece internet olmasa bile B kişisi, A kişisinin eşyalarını görmez.
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
		
		# --- YENİ EKLENECEKLER ---
		"quests": [], # Tüm görevler (statik ve günlük) burada duracak
		"last_quest_gen_date": "", # Günlük görevlerin en son ne zaman üretildiği
		# -------------------------
		
		"unsynced_changes": false 
	}
	# İstersen dosyayı da fiziksel olarak silebilirsin ama RAM'i temizlemek yeterlidir.
	# DirAccess.remove_absolute(cache_path)

# ============================================================
#   SAHNE GEÇİŞİ
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
#   LEVEL & XP SİSTEMİ
# ============================================================
func add_xp(amount: int):
	cache["user"]["experience"] += amount
	print("🌟 XP Kazanıldı: ", amount, " | Toplam: ", cache["user"]["experience"])
	
	# Level Atlama Kontrolü (Her 300 XP = 1 Level)
	var xp_needed = 300
	while cache["user"]["experience"] >= xp_needed:
		cache["user"]["experience"] -= xp_needed
		cache["user"]["level"] += 1
		print("🎉 TEBRİKLER! Level Atladın: ", cache["user"]["level"])
		
		# Level 2 Ödülü Kontrolü (MC Değişimi)
		if cache["user"]["level"] == 2:
			print("🎁 Ödül: Yeni Karakter Kilidi Açıldı!")
			# Örnek: Karakter ID'sini değiştiriyoruz
			# cache["user"]["character_id"] = 2 
			
	# Değişikliği kaydet ve UI'ı güncelle
	save_cache()
	emit_signal("data_updated")
