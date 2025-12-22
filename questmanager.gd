extends Node

var static_quest_definitions = [
	{"id": "static_rest", "desc": "Restaurant first entry", "target": "first_restaurant", "xp": 20},
	{"id": "static_mark", "desc": "Market first entry", "target": "first_market", "xp": 20},
	{"id": "static_gym",  "desc": "Gym first entry", "target": "first_gym", "xp": 20},
	{"id": "static_lib",  "desc": "Library first entry", "target": "first_library", "xp": 20},
	{"id": "static_ward", "desc": "Wardrobe first outfit", "target": "first_wardrobe", "xp": 20},
	{"id": "static_name", "desc": "Give character a name", "target": "first_name", "xp": 20},
	{"id": "static_bday", "desc": "Enter birthday", "target": "first_birthday", "xp": 20},
	{"id": "static_cal",  "desc": "Calendar first entry", "target": "first_calendar", "xp": 20},
	{"id": "static_mus",  "desc": "Adjust music settings", "target": "first_music", "xp": 20},
]

func _ready():
	print("🚀 QuestManager: Hazır, görevler kontrol ediliyor...")
	call_deferred("check_and_init_quests")
	

func check_and_init_quests():
	# 1. Güvenlik: Globals.cache içinde 'quests' yoksa oluştur
	if not Globals.cache.has("quests"):
		Globals.cache["quests"] = []
		print("ℹ️ QuestManager: Cache içinde 'quests' dizisi oluşturuldu.")
		
	var current_quests = Globals.cache["quests"]
	var existing_ids = []
	for q in current_quests:
		if q is Dictionary and q.has("id"):
			existing_ids.append(q["id"])
		
	var updated = false
	for def in static_quest_definitions:
		if not def["id"] in existing_ids:
			Globals.cache["quests"].append({
				"id": def["id"], 
				"type": "static", 
				"description": def["desc"],
				"target_action": def["target"], 
				"xp_reward": def["xp"], 
				"is_completed": false
			})
			updated = true
			
	if updated:
		print("✅ QuestManager: Yeni statik görevler eklendi.")
		Globals.save_cache() 
		# UI'ı güncellemesi için sinyal gönder
		if Globals.has_signal("data_updated"):
			Globals.data_updated.emit()
	else:
		print("ℹ️ QuestManager: Eklenecek yeni statik görev yok, hepsi mevcut.")
	
	check_daily_quests()

func check_daily_quests():
	var today_str = Time.get_date_string_from_system()
	if Globals.cache.get("last_quest_gen_date", "") != today_str:
		print("📡 QuestManager: Bugünün günlük görevleri yok, Worker'a gidiliyor...")
		fetch_daily_quests_from_worker(today_str)
	else:
		print("ℹ️ QuestManager: Bugünün günlük görevleri zaten yüklü.")

func fetch_daily_quests_from_worker(today_str):
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(self._on_daily_received.bind(today_str, http))
	
	var url = "https://life-sim-worker.life-simulation.workers.dev/api/daily_quests"
	var err = http.request(url, [], HTTPClient.METHOD_POST, "{}")
	if err != OK:
		print("❌ QuestManager: HTTP isteği başlatılamadı!")

func _on_daily_received(result, response_code, headers, body, today_str, http_node):
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json is Array:
			var new_list = []
			# Mevcut listeden sadece statik olanları koru
			for q in Globals.cache["quests"]:
				if q.get("type") != "daily":
					new_list.append(q)
			
			# Worker'dan gelen yeni günlükleri ekle
			for dq in json:
				new_list.append(dq)
			
			Globals.cache["quests"] = new_list
			Globals.cache["last_quest_gen_date"] = today_str
			Globals.save_cache()
			
			if Globals.has_signal("data_updated"):
				Globals.data_updated.emit()
			print("✅ QuestManager: Günlük görevler başarıyla güncellendi.")
	else:
		print("❌ QuestManager: Worker hatası! Kod: ", response_code)
	
	http_node.queue_free()

func trigger_action(action_name: String):
	var updated = false
	if not Globals.cache.has("quests"): return

	for q in Globals.cache["quests"]:
		# .to_lower() ekleyerek büyük/küçük harf hatasını engelliyoruz
		if q["target_action"].to_lower() == action_name.to_lower() and not q["is_completed"]:
			q["is_completed"] = true
			Globals.add_xp(q["xp_reward"])
			updated = true
			print("🎯 Görev Tamamlandı: ", q["description"])
			
	if updated:
		Globals.save_cache()
		if Globals.has_signal("data_updated"):
			Globals.data_updated.emit()
