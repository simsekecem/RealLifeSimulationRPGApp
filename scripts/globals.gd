extends Node

# ============================================================
#  GLOBAL STATE
# ============================================================
var auth_token: String = ""
var user_id: String = ""
var door_locked: bool = false

# Loading Screen için
var next_scene_path: String = "" 

# Çıkış işlemi kontrolü
var is_quitting: bool = false 

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
var debounce_seconds := 30.0 # Yerel kaydetme sıklığı

var cache_path := "user://user_cache.json"
var WEEK_RESET_DAYS := 7

# ============================================================
#  BAŞLANGIÇ AYARLARI
# ============================================================
func _ready():
	load_cache()
	reset_if_week_passed()
	
	# ÖNEMLİ: Otomatik çıkışı kapatıyoruz.
	# Kullanıcı X'e bastığında kontrolü biz alacağız (_notification fonksiyonunda).
	get_tree().set_auto_accept_quit(false)

# ============================================================
#  YEREL KAYIT (LOCAL SAVE) - Her dakika çalışır
# ============================================================
func mark_dirty():
	save_timer = debounce_seconds

func _process(delta):
	if save_timer > 0:
		save_timer -= delta
		if save_timer <= 0:
			save_cache()

# ============================================================
#  ÇIKIŞ SİNYALİNİ YAKALAMA (KAPATMA İSTEĞİ)
# ============================================================
func _notification(what):
	# Kullanıcı oyunu kapatmak istediğinde (X tuşu, Alt+F4, Mobil Geri Tuşu)
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		
		# Eğer zaten çıkış sürecindeysek tekrar işlem yapma
		if is_quitting:
			return
			
		print("🛑 Çıkış isteği algılandı. Veriler sunucuya gönderiliyor...")
		is_quitting = true
		
		# 1. Önce yerel dosyaya kaydet (Garanti olsun)
		save_cache()
		
		# 2. Sunucuya veriyi gönder ve CEVABI BEKLE
		send_to_server_and_quit()

# ============================================================
#  SUNUCUYA GÖNDER VE ÇIK (ASYNC)
# ============================================================
func send_to_server_and_quit():
	# Token yoksa (Login olunmamışsa) beklemeden çık
	if auth_token == "":
		print("⚠️ Token yok, direkt çıkılıyor.")
		get_tree().quit()
		return

	var http = HTTPRequest.new()
	add_child(http)
	
	# İstek bittiğinde çalışacak fonksiyonu bağla
	http.request_completed.connect(_on_exit_save_completed)
	
	# ZAMAN AŞIMI KORUMASI:
	# Sunucu 3 saniye içinde cevap vermezse oyunu zorla kapat.
	get_tree().create_timer(3.0).timeout.connect(force_quit)

	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + auth_token
	]
	
	print("📡 Kapanış verisi gönderiliyor...")
	var error = http.request(
		"https://life-sim-worker.life-simulation.workers.dev/api/save_all",
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(cache)
	)
	
	# Eğer HTTP isteği bile oluşturulamazsa (İnternet yoksa vs.)
	if error != OK:
		print("❌ İstek hatası! Direkt çıkılıyor.")
		get_tree().quit()

# Sunucudan cevap gelince burası çalışır
func _on_exit_save_completed(result, response_code, headers, body):
	if response_code == 200:
		print("✅ Kapanış kaydı BAŞARILI! Oyun kapatılıyor.")
	else:
		print("❌ Kapanış kaydı BAŞARISIZ (Kod: " + str(response_code) + ").")
		# --- HATA MESAJINI OKUMA ---
		var error_msg = body.get_string_from_utf8()
		print("🔥 SUNUCU HATASI DETAYI: ", error_msg)
	
	get_tree().quit()

# 3 saniye dolarsa burası çalışır
func force_quit():
	if is_quitting:
		print("⏰ Zaman aşımı! Zorla kapatılıyor.")
		get_tree().quit()

# ============================================================
#  CACHE YÖNETİMİ (YEREL)
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
#  HAFTALIK SIFIRLAMA
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
#  SUNUCUDAN YÜKLEME (LOGIN SONRASI)
# ============================================================
func load_from_server():
	if auth_token == "": return
	print("⬇️ Sunucudan veriler çekiliyor...")
	
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_load_complete)
	
	var headers = ["Authorization: Bearer " + auth_token]
	http.request("https://life-sim-worker.life-simulation.workers.dev/api/load_all", headers, HTTPClient.METHOD_GET)

# ============================================================
#  SUNUCUDAN YÜKLEME (DATA CLEANER EKLENDİ)
# ============================================================
func _on_load_complete(_res, code, _headers, body):
	if code == 200:
		var json = JSON.new()
		var parse_result = json.parse(body.get_string_from_utf8())
		
		if parse_result != OK:
			print("❌ JSON Parse Hatası!")
			return

		var data = json.get_data()

		if typeof(data) == TYPE_DICTIONARY:
			# --- VERİ TEMİZLEME (UNWRAP) İŞLEMİ ---
			# Cloudflare D1 veriyi { "results": [...] } içine sarıp gönderiyor.
			# Biz sadece içindeki listeyi alacağız.
			
			if data.has("user"): cache["user"] = data["user"] # User genelde düz gelir
			if data.has("preferences"): cache["preferences"] = data["preferences"]
			
			# Listeler için "unwrap_d1_data" fonksiyonunu kullanıyoruz
			if data.has("study_log"): cache["study_log"] = unwrap_d1_data(data["study_log"])
			if data.has("gym_log"): cache["gym_log"] = unwrap_d1_data(data["gym_log"])
			if data.has("library"): cache["library"] = unwrap_d1_data(data["library"]) # library_books olabilir, kontrol et
			if data.has("market_items"): cache["market_items"] = unwrap_d1_data(data["market_items"])
			if data.has("calendar_notes"): cache["calendar_notes"] = unwrap_d1_data(data["calendar_notes"])
			if data.has("restaurant"): cache["restaurant"] = unwrap_d1_data(data["restaurant"])
			
			save_cache()
			print("✅ Veriler kutudan çıkarıldı ve senkronize edildi.")
			# Debug için temizlenmiş halini görelim
			# print("TEMİZ STUDY LOG: ", cache["study_log"])
	else:
		print("❌ Veri çekme hatası: ", code)

# --- YARDIMCI FONKSİYON (Bunu _on_load_complete'in altına yapıştır) ---
func unwrap_d1_data(incoming_data):
	# 1. Eğer veri { "results": [...] } şeklindeyse, içini al
	if typeof(incoming_data) == TYPE_DICTIONARY and incoming_data.has("results"):
		return incoming_data["results"]
	
	# 2. Eğer zaten direkt Listeyse ([...]) olduğu gibi kullan
	if typeof(incoming_data) == TYPE_ARRAY:
		return incoming_data
		
	# 3. Eğer boşsa veya bozuksa, boş liste dön (Crash önleyici)
	return []

# ============================================================
#  SAHNE GEÇİŞİ (LOADING SCREEN)
# ============================================================
func change_scene_with_loading(target_path: String):
	# Geçiş yapmadan önce yerel kaydet
	save_cache()
	
	next_scene_path = target_path
	get_tree().change_scene_to_file("res://scenes/UserInterface/LoadingScreen.tscn")
