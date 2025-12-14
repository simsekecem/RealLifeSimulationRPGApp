extends Area2D

@export_file("*.tscn") var target_scene_path: String = ""
@export var is_exit_door: bool = false

# Sahne ilk yüklendiğinde kapının hemen çalışmaması için yerel güvenlik
var is_active: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	
	# Sahne açıldıktan 0.5 saniye sonra kapıyı aktif et (Yerel koruma)
	await get_tree().create_timer(0.5).timeout
	is_active = true

func _on_body_entered(body):
	# --- 1. GLOBAL KİLİT KONTROLÜ (SPAWN LOOP KORUMASI) ---
	# Eğer evden yeni çıktıysak Globals.door_locked = true olmuştur.
	# Bu durumda kapı HİÇBİR İŞLEM YAPMAZ.
	if Globals.door_locked:
		print("⛔ Kapı kilitli (Cooldown süresinde), işlem reddedildi.")
		return
	# ------------------------------------------------------

	# --- 2. STANDART KONTROLLER ---
	# Kapı henüz aktif değilse veya çarpan şey Player değilse dur.
	if not is_active or not body.is_in_group("player"):
		return

	print("🚪 Kapı tetiklendi!")

	# --- 3. DURUM: EVDEN ÇIKIŞ ---
	if is_exit_door:
		print("🔙 Town'a dönülüyor (Deferred)...")
		
		if UI.has_node("UIRoot"):
			# Fizik hatası almamak için call_deferred kullanıyoruz
			UI.get_node("UIRoot").call_deferred("return_to_town")
		return

	# --- 4. DURUM: EVE GİRİŞ ---
	if target_scene_path == "":
		print("⚠️ Hata: Kapı hedefi (Target Scene) seçilmemiş!")
		return

	# MainGame'i bulana kadar yukarı tırman
	var current_node = self
	var main_game = null
	
	while current_node:
		if current_node.has_method("enter_house"):
			main_game = current_node
			break
		current_node = current_node.get_parent()
	
	if main_game:
		print("🚪 MainGame üzerinden giriliyor (Deferred)...")
		# MainGame'deki fonksiyonu sıraya koyarak çağır (Hatasız geçiş)
		main_game.call_deferred("enter_house", target_scene_path)
	else:
		# Test modu (MainGame yoksa)
		print("🛠️ Test modu geçişi (Deferred)...")
		get_tree().call_deferred("change_scene_to_file", target_scene_path)
