extends Node2D

# Sahne ağacındaki Container node'larına erişim
@onready var town_container = $TownContainer
@onready var home_container = $HomeContainer
@onready var others_container = $OthersContainer

# Town sahnesinin yolu
var town_scene_path = "res://scenes/town.tscn"

func _ready():
	print("MainGame Başlatıldı. TownContainer dolduruluyor...")
	# 🎵 ARKA PLAN MÜZİĞİ BAŞLAT
	MusicController.bgm_play()
	# ---------------------------------------------------------
	# 1. TOWN SAHNESİNİ YÜKLEME
	# ---------------------------------------------------------
	if town_scene_path != "":
		var town_scene = load(town_scene_path)
		var town_instance = town_scene.instantiate()
		town_container.add_child(town_instance)
		print("✅ Town sahneye eklendi.")
	else:
		print("❌ HATA: Town sahne yolu boş!")

	# ---------------------------------------------------------
	# 2. GLOBAL UI ERİŞİMİ
	# ---------------------------------------------------------
	if UI.has_node("UIRoot"):
		var ui_root = UI.get_node("UIRoot")
		
		# Joystick ve butonları göster
		if ui_root.has_method("show_full_ui"):
			ui_root.show_full_ui()
			ui_root.set_process_input(true) 
			print("✅ UI aktif edildi.")
	else:
		print("⚠️ UYARI: Global UI içinde 'UIRoot' bulunamadı!")

## ---------------------------------------------------------
# FONKSİYON: EVE/MEKANA GİRİŞ (GÜNCELLENDİ)
# ---------------------------------------------------------
func enter_house(house_path: String):
	print("🚪 Mekana giriliyor: ", house_path)
	
	# --- YENİ EKLENEN KISIM: GİRMEDEN ÖNCE İT ---
	# Town donmadan önce karakteri kapıdan uzaklaştırıyoruz.
	# Böylece geri döndüğümüzde (unpause olunca) kapıya basmıyor olacak.
	if town_container.get_child_count() > 0:
		var town_instance = town_container.get_child(0)
		if town_instance.has_node("Player"):
			var player = town_instance.get_node("Player")
			player.position.y += 10 # 50 piksel aşağı kaydır
			
			# Yüzünü de aşağı çevirelim ki kapıdan çıkmış gibi dursun
			if player.has_method("play_animation"):
				player.last_direction = Vector2.DOWN
				player.play_animation("idle")
	# --------------------------------------------

	# 1. Town'u gizle ve dondur
	town_container.visible = false
	town_container.process_mode = Node.PROCESS_MODE_DISABLED
	
	# 2. Yeni sahneyi yükle
	var new_scene = load(house_path).instantiate()
	
	# 3. Sahnenin türüne göre doğru kutuya koy
	if new_scene is Control:
		others_container.add_child(new_scene)
	elif new_scene is Node2D:
		home_container.add_child(new_scene)
		
		# Evin içindeki karakterin kamerasını aktif et
		if new_scene.has_node("Player"):
			var home_player = new_scene.get_node("Player")
			if home_player.has_node("Camera2D"):
				home_player.get_node("Camera2D").make_current()


# ---------------------------------------------------------
# FONKSİYON: EVDEN ÇIKIŞ (TOWN'A DÖNÜŞ)
# ---------------------------------------------------------
func exit_house():
	print("🌲 Town'a geri dönülüyor...")
	
	# 1. KAPILARI KİLİTLE (Spawn Loop Koruması)
	Globals.door_locked = true

	# 2. Evleri ve Menüleri temizle
	for child in home_container.get_children():
		child.queue_free()
	
	for child in others_container.get_children():
		child.queue_free()
		
	# 3. Town'u tekrar görünür yap ve çalıştır
	town_container.visible = true
	town_container.process_mode = Node.PROCESS_MODE_INHERIT
	
	# 4. KAMERAYI DÜZELT (İtme kodu kalktı!)
	if town_container.get_child_count() > 0:
		var town_instance = town_container.get_child(0)
		if town_instance.has_node("Player"):
			var player = town_instance.get_node("Player")
			
			# ARTIK İTMİYORUZ! (Bu satırı sildik: player.position.y += 100)
			
			# Sadece kamerayı Town karakterine veriyoruz
			if player.has_node("Camera2D"):
				player.get_node("Camera2D").make_current()
				
			# (Opsiyonel) Yüzünü aşağı çevirip durdurabilirsin
			if player.has_method("play_animation"):
				player.last_direction = Vector2.DOWN
				player.play_animation("idle")

	# 5. UI'ı göster
	if UI.has_node("UIRoot"):
		UI.get_node("UIRoot").show_full_ui()
		
	# 6. KİLİDİ AÇMA SAYACI
	print("⏳ Kapılar 1 saniye kilitlendi.")
	await get_tree().create_timer(1.0).timeout
	Globals.door_locked = false
	print("🔓 Kapılar tekrar aktif.")
	
	
	
  
