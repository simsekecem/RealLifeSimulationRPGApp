extends Node2D

# Sahne ağacındaki Container node'larına erişim
@onready var town_container = $TownContainer
@onready var home_container = $HomeContainer
@onready var others_container = $OthersContainer

# Town sahnesinin yolu
var town_scene_path = "res://scenes/town.tscn"

func _ready():
	print("MainGame Başlatıldı. TownContainer dolduruluyor...")
	
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

# ---------------------------------------------------------
# FONKSİYON: EVE/MEKANA GİRİŞ
# ---------------------------------------------------------
func enter_house(house_path: String):
	print("🚪 Mekana giriliyor: ", house_path)
	
	# 1. Town'u gizle ve dondur
	town_container.visible = false
	town_container.process_mode = Node.PROCESS_MODE_DISABLED
	
	# 2. Yeni sahneyi yükle
	var new_scene = load(house_path).instantiate()
	
	# 3. Sahnenin türüne göre doğru kutuya koy
	if new_scene is Control:
		# Market, Banka gibi Arayüzler
		print("   -> Tip: Control (Arayüz). OthersContainer'a ekleniyor.")
		others_container.add_child(new_scene)
		
	elif new_scene is Node2D:
		# Ev içi, Mağara gibi yürünebilir alanlar
		print("   -> Tip: Node2D (Mekan). HomeContainer'a ekleniyor.")
		home_container.add_child(new_scene)

# ---------------------------------------------------------
# FONKSİYON: EVDEN ÇIKIŞ (TOWN'A DÖNÜŞ)
# ---------------------------------------------------------
func exit_house():
	print("🌲 Town'a geri dönülüyor...")

	# 1. HomeContainer içindeki (Node2D) evleri temizle
	for child in home_container.get_children():
		child.queue_free()
	
	# 2. OthersContainer içindeki (Control) arayüzleri temizle
	for child in others_container.get_children():
		child.queue_free()
		
	# 3. Town'u tekrar görünür yap ve çalıştır
	town_container.visible = true
	town_container.process_mode = Node.PROCESS_MODE_INHERIT
	
	# --- 4. KRİTİK AYAR: KARAKTERİ KAPIDAN UZAKLAŞTIR ---
	# TownContainer'ın içindeki Town haritasını bul
	if town_container.get_child_count() > 0:
		var town_instance = town_container.get_child(0)
		
		# Town'daki Player node'unu bul (İsmi "Player" olmalı)
		if town_instance.has_node("Player"):
			var player = town_instance.get_node("Player")
			
			# Karakteri 40 piksel aşağı itiyoruz (Kapıdan kurtarıyoruz)
			player.position.y += 40
			
			# (Opsiyonel) Yüzünü aşağı çevirip durduruyoruz
			if player.has_method("play_animation"):
				player.last_direction = Vector2.DOWN
				player.play_animation("idle")
			
			print("📍 Karakter kapının önünden uzaklaştırıldı (y += 40).")

	# 5. UI'ı tekrar göster
	if UI.has_node("UIRoot"):
		UI.get_node("UIRoot").show_full_ui()
