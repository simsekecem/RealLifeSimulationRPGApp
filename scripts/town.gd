extends Node

@onready var http := $HTTPRequest

func _ready():
	print("🔄 [TOWN] Sunucudan veriler çekiliyor...")
	load_remote_data()

func load_remote_data():
	if Globals.auth_token == "":
		print("⚠️ [TOWN] Token bulunamadı, senkronizasyon atlanıyor.")
		return

	var headers = [
		"Authorization: Bearer " + Globals.auth_token
	]

	var url = "https://life-sim-worker.life-simulation.workers.dev/api/load_all"

	# Sinyal bağlantısını kontrol ederek yapıyoruz (çift bağlantıyı önlemek için)
	if not http.request_completed.is_connected(_on_load_response):
		http.request_completed.connect(_on_load_response)
	
	http.request(url, headers, HTTPClient.METHOD_GET)

func _on_load_response(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray):
	if code != 200:
		print("❌ [TOWN] Yükleme başarısız, hata kodu:", code)
		return

	var data = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) != TYPE_DICTIONARY:
		print("❌ [TOWN] Geçersiz JSON verisi.")
		return

	print("✅ [TOWN] Sunucu verisi alındı, yerel hafızaya işleniyor...")
	_apply_remote_to_cache(data)

func _apply_remote_to_cache(data: Dictionary):
	# 1. USER VERİLERİ (GÜNCELLENDİ ✨)
	if data.has("user") and data["user"] != null:
		var u = data["user"]
		# Mevcutları koruyoruz
		Globals.cache["user"]["name"] = u.get("name", "Rookie")
		Globals.cache["user"]["birthdate"] = u.get("birthdate", "")
		
		# 👇 YENİ: Bunlar eklenmezse UI (Level/XP) ve Player (Karakter) güncellenmez!
		Globals.cache["user"]["character_id"] = int(u.get("character_id", 1))
		Globals.cache["user"]["level"] = int(u.get("level", 1))
		Globals.cache["user"]["experience"] = int(u.get("experience", 0))
		Globals.cache["user"]["fcm_token"] = u.get("fcm_token", "")

	# 2. PREFERENCES
	if data.has("preferences") and data["preferences"] != null:
		Globals.cache["preferences"]["music_volume"] = data["preferences"].get("music_volume", 50)

	# 3. LİSTELER (Diziler)
	Globals.cache["library"] = data.get("library", [])
	Globals.cache["study_log"] = data.get("study_log", [])
	Globals.cache["gym_log"] = data.get("gym_log", [])
	Globals.cache["market_items"] = data.get("market_items", [])
	Globals.cache["restaurant"] = data.get("restaurant", [])
	Globals.cache["calendar_notes"] = data.get("calendar_notes", [])

	# 4. YEREL KAYIT VE UI TETİKLEME
	Globals.save_cache()
	print("💾 [TOWN] Yerel cache senkronize edildi.")

	# 👇 KRİTİK: Tüm sahneleri (UI, Player vb.) verilerin geldiğine dair uyar
	if Globals.has_signal("data_updated"):
		Globals.data_updated.emit()
