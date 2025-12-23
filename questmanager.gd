extends Node

# Statik görev tanımları
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
	if not Globals.cache.has("quests"):
		Globals.cache["quests"] = []
		
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
		if Globals.has_signal("data_updated"):
			Globals.data_updated.emit()
	
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
		
func _on_daily_received(_result, response_code, _headers, body, today_str, http_node):
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json is Array:
			var new_list = []
			var static_ids = []
			for s_def in static_quest_definitions:
				static_ids.append(s_def["id"])
				
			for q in Globals.cache["quests"]:
				if q.get("id") in static_ids:
					new_list.append(q)
			
			for dq in json:
				dq["type"] = "daily" 
				new_list.append(dq)
			
			Globals.cache["quests"] = new_list
			Globals.cache["last_quest_gen_date"] = today_str
			Globals.save_cache()
			
			if Globals.has_signal("data_updated"):
				Globals.data_updated.emit()
			print("✅ QuestManager: Liste senkronize edildi.")
	else:
		print("❌ QuestManager: Worker hatası! Kod: ", response_code)
	
	if http_node: http_node.queue_free()

# ==========================================================
# 👇 GÜNCELLENEN TRIGGER ACTION (GECİKMELİ)
# ==========================================================
func trigger_action(action_name: String):
	var updated = false
	if not Globals.cache.has("quests"): return

	for q in Globals.cache["quests"]:
		if q["target_action"].to_lower() == action_name.to_lower() and not q["is_completed"]:
			# 1. State'i hemen güncelle (Güvenlik için)
			q["is_completed"] = true
			Globals.add_xp(q["xp_reward"])
			updated = true
			print("🎯 Görev Tamamlandı (Saved): ", q["description"])
			
			# 2. Bildirimi 5 saniye sonra göster (Görsel keyif için)
			# 'bind' fonksiyonu ile parametreleri şimdi paketliyoruz, 5 sn sonra açılacak.
			get_tree().create_timer(3.0).timeout.connect(
				show_mission_popup.bind(q["description"], q["xp_reward"])
			)
			
	if updated:
		# Veriyi anında kaydet, oyuncu 5 saniye beklemeden çıksa bile görev sayılmış olsun.
		Globals.save_cache()
		if Globals.has_signal("data_updated"):
			Globals.data_updated.emit()

# ==========================================================
# 👇 DİNAMİK BİLDİRİM PENCERESİ (CODE ONLY)
# ==========================================================
func show_mission_popup(desc: String, xp: int):
	# 1. CanvasLayer (Ekranda en üstte dursun diye)
	var layer = CanvasLayer.new()
	layer.layer = 100 # Z-Index gibi, en öne alır
	get_tree().root.add_child(layer)
	
	# 2. Arka Plan Kutusu (Panel)
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left = 20; panel.offset_right = -20
	panel.position.y = -150 # Başlangıçta yukarıda gizli
	
	# Stil
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	style.border_width_bottom = 4
	style.border_color = Color.GOLD
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	
	layer.add_child(panel)
	
	# 3. İçerik Düzeni
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var lbl_title = Label.new()
	lbl_title.text = "MISSION COMPLETED!"
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.add_theme_color_override("font_color", Color.GOLD)
	lbl_title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(lbl_title)
	
	var lbl_desc = Label.new()
	lbl_desc.text = desc
	lbl_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_desc.add_theme_font_size_override("font_size", 16)
	vbox.add_child(lbl_desc)
	
	var lbl_xp = Label.new()
	lbl_xp.text = "+ " + str(xp) + " XP"
	lbl_xp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_xp.add_theme_color_override("font_color", Color.GREEN)
	lbl_xp.add_theme_font_size_override("font_size", 18)
	vbox.add_child(lbl_xp)
	
	# 4. Animasyon (Tween)
	var tween = create_tween()
	tween.tween_property(panel, "position:y", 20.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(3.0) # Ekranda kalma süresi
	tween.tween_property(panel, "position:y", -200.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(layer.queue_free)
