extends Area2D

# 👇 Wardrobe seçeneği eklendi
@export_enum("Calendar", "NPC", "Bed", "Chest", "Wardrobe") var interact_type: String = "Calendar"
@export_multiline var dialog_text: String = "Merhaba!"

# Kaç saniye bekleyince açılsın?
@export var wait_time: float = 2.0

# Kodla oluşturacağımız zamanlayıcı
var timer: Timer
var has_triggered: bool = false # Zaten açıldı mı?

func _ready():
	# 1. Zamanlayıcıyı (Timer) oluştur
	timer = Timer.new()
	timer.wait_time = wait_time
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	
	# 2. Giriş-Çıkışları dinle
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

# --- ALANA GİRİNCE ---
func _on_body_entered(body):
	if body.is_in_group("player"):
		print("⏳ Bekleme başladı... (" + str(wait_time) + " sn)")
		has_triggered = false
		timer.start()

# --- ALANDAN ÇIKINCA ---
func _on_body_exited(body):
	if body.is_in_group("player"):
		print("❌ Alandan çıkıldı, sayaç iptal.")
		timer.stop()
		has_triggered = false

# --- SÜRE DOLUNCA ---
func _on_timer_timeout():
	if not has_triggered:
		has_triggered = true
		interact()

# --- ETKİLEŞİM İŞLEMLERİ ---
func interact():
	print("✅ Süre doldu! Etkileşim: ", interact_type)
	
	match interact_type:
		"Calendar":
			open_calendar()
		"Wardrobe":
			open_wardrobe() # 👈 Gardırop buraya yönlendirildi
		"NPC":
			start_dialog()

# ============================================================
# 👗 GARDIROP (OVERLAY) MANTIĞI
# ============================================================
func open_wardrobe():
	print("👕 Gardırop Overlay olarak açılıyor...")
	
	# 1. Gardırop sahnesini belleğe yükle
	# Dosya yolunun projendekiyle aynı olduğundan emin ol
	var wardrobe_scn = load("res://scenes/Wardrobe.tscn").instantiate()
	
	# 2. Pause modunda butonların çalışması için ayar
	wardrobe_scn.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 3. Oyunu durdur (Karakter arkada hareket etmesin)
	get_tree().paused = true
	
	# 4. Takvim gibi UIRoot altına ekle
	if UI.has_node("UIRoot"):
		UI.get_node("UIRoot").add_child(wardrobe_scn)
	else:
		# Yedek plan: Direkt sahne ağacının köküne ekle
		get_tree().root.add_child(wardrobe_scn)

# ============================================================
# 📅 TAKVİM MANTIĞI
# ============================================================
func open_calendar():
	print("📅 Takvim Overlay olarak açılıyor...")
	
	var calendar_scn = load("res://addons/calendar_library/demo/calendar_demo.tscn").instantiate()
	calendar_scn.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	
	if UI.has_node("UIRoot"):
		UI.get_node("UIRoot").add_child(calendar_scn)
	else:
		add_child(calendar_scn)

# ============================================================
# 💬 DİĞERLERİ
# ============================================================
func start_dialog():
	print("💬 NPC: ", dialog_text)
