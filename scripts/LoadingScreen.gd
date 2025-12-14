extends Control

@onready var progress_bar = $ProgressBar
@onready var label = $Label

# --- AYARLAR ---
const MIN_PROGRESS_THRESHOLD = 20.0
const DOT_CHANGE_RATE: float = 0.25  # Noktalar ne kadar hızlı değişsin?
const MAX_DOTS: int = 4              # En fazla kaç nokta olsun? (Loading....)

# --- DEĞİŞKENLER ---
var dot_timer: float = 0.0
var current_dot_count: int = 0       # <--- YENİ: Basit sayaç değişkeni

var target_scene_path: String = ""
var progress = []
var load_status = 0

func _ready():
	# UI'ı gizle (Arka planda joystick kalmasın)
	if UI.has_node("UIRoot"):
		UI.get_node("UIRoot").hide_all_ui()
	
	# Hedefi al
	target_scene_path = Globals.next_scene_path
	
	if target_scene_path == "":
		print("❌ Hata: Yüklenecek sahne yolu boş!")
		return

	# Yüklemeyi başlat
	ResourceLoader.load_threaded_request(target_scene_path, "", true)
	print("⏳ Loading başladı: ", target_scene_path)

func _process(delta):
	if target_scene_path == "":
		return
		
	# ==================================
	# 1. NOKTA ANİMASYONU (GARANTİLİ YÖNTEM)
	# ==================================
	
	dot_timer += delta
	
	# Süre dolduysa bir sonraki noktaya geç
	if dot_timer >= DOT_CHANGE_RATE:
		dot_timer = 0.0  # Sayacı sıfırla
		
		# Nokta sayısını 1 artır
		current_dot_count += 1
		
		# Eğer 4 noktayı geçerse 0'a dön
		if current_dot_count > MAX_DOTS:
			current_dot_count = 0
		
		# Ekrana yazdır (Loading + noktalar)
		if label:
			label.text = "Loading" + ".".repeat(current_dot_count)

	# ==================================
	# 2. PROGRESS BAR VE BİTİŞ KONTROLÜ
	# ==================================
	
	load_status = ResourceLoader.load_threaded_get_status(target_scene_path, progress)
	
	if progress.size() > 0:
		# Yüzdeyi hesapla
		var yuzde = progress[0] * 100
		progress_bar.value = max(yuzde, MIN_PROGRESS_THRESHOLD)

	# Yükleme bitti mi?
	if load_status == ResourceLoader.THREAD_LOAD_LOADED:
		print("✅ Yükleme bitti, sahne açılıyor!")
		set_process(false) 
		
		var new_scene = ResourceLoader.load_threaded_get(target_scene_path)
		get_tree().change_scene_to_packed(new_scene)
		
	elif load_status == ResourceLoader.THREAD_LOAD_FAILED:
		print("❌ Hata: Sahne yüklenemedi!")
		set_process(false)
