extends Area2D

@export_enum("Calendar", "NPC", "Bed", "Chest") var interact_type: String = "Calendar"
@export_multiline var dialog_text: String = "Merhaba!"

# Kaç saniye bekleyince açılsın?
@export var wait_time: float = 2.0

# Kodla oluşturacağımız zamanlayıcı
var timer: Timer
var has_triggered: bool = false # Zaten açıldı mı? (Sürekli açılmasın diye)

func _ready():
	# 1. Zamanlayıcıyı (Timer) oluştur
	timer = Timer.new()
	timer.wait_time = wait_time
	timer.one_shot = true # Sadece bir kere çalışsın, döngüye girmesin
	timer.timeout.connect(_on_timer_timeout) # Süre bitince ne yapsın?
	add_child(timer)
	
	# 2. Giriş-Çıkışları dinle
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

# --- ALANA GİRİNCE ---
func _on_body_entered(body):
	if body.is_in_group("player"):
		print("⏳ Bekleme başladı... (" + str(wait_time) + " sn)")
		has_triggered = false # Henüz tetiklenmedi
		timer.start() # Sayacı başlat

# --- ALANDAN ÇIKINCA ---
func _on_body_exited(body):
	if body.is_in_group("player"):
		print("❌ Alandan çıkıldı, sayaç iptal.")
		timer.stop() # Sayacı durdur (Vazgeçti)
		has_triggered = false

# --- SÜRE DOLUNCA (2 SANİYE SONRA) ---
func _on_timer_timeout():
	# Eğer zaten açılmadıysa ve oyuncu hala içerdeyse
	if not has_triggered:
		has_triggered = true # Açıldığını işaretle
		interact()

# --- ETKİLEŞİM İŞLEMLERİ ---
func interact():
	print("✅ Süre doldu! Etkileşim: ", interact_type)
	
	match interact_type:
		"Calendar":
			open_calendar()
		"NPC":
			start_dialog()
		"Bed":
			print("🛏️ Uykucu şirin!")

func open_calendar():
	# Takvim sahnesini yükle
	var calendar_scene = load("res://addons/calendar_library/demo/calendar_demo.tscn").instantiate()
	
	if UI.has_node("UIRoot"):
		UI.get_node("UIRoot").add_child(calendar_scene)
	else:
		add_child(calendar_scene)

func start_dialog():
	print("💬 NPC: ", dialog_text)
