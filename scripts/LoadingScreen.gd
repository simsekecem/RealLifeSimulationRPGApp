extends Control

@onready var progress_bar = $ProgressBar
@onready var label = $Label

# Progress Bar'ın minimum göstermesi gereken değer
const MIN_PROGRESS_THRESHOLD = 20.0

# Etiket animasyonu için sayaç ve hız
var dot_timer: float = 0.0
const DOT_CHANGE_RATE: float = 0.2  # Noktaların her 0.2 saniyede bir değişmesi
const MAX_DOTS: int = 5            # Maksimum nokta sayısı (Yükleniyor.....)

# Yüklenecek sahnenin yolu (Globals'dan gelecek)
var target_scene_path: String = ""
var progress = []
var load_status = 0

func _ready():
	UI.get_node("UIRoot").hide_all_ui()
	# 1. Hedef sahneyi Globals'dan al
	target_scene_path = Globals.next_scene_path
	
	if target_scene_path == "":
		print("❌ Hata: Yüklenecek sahne yolu boş!")
		return

	# 2. Arka planda yüklemeyi başlat
	ResourceLoader.load_threaded_request(target_scene_path, "", true)
	print("⏳ Yükleme başladı: ", target_scene_path)

func _process(delta):
	if target_scene_path == "":
		return
		
	# ==================================
	# 1. LABEL ANİMASYONU
	# ==================================
	
	# Delta ile zaman sayacını artır
	dot_timer += delta
	
	# Belirlenen zaman geçtiyse noktaları güncelle
	if dot_timer >= DOT_CHANGE_RATE:
		dot_timer -= DOT_CHANGE_RATE # Sayacı sıfırla (kalan zamanı koruyarak)
		
		# Hangi noktadayız? (0'dan 4'e kadar)
		var current_dot_count = int(fmod(get_tree().get_process_time() / DOT_CHANGE_RATE, MAX_DOTS + 1))
		
		# Noktaları oluştur
		var dots = ".".repeat(current_dot_count)
		
		# Etiketi güncelle
		if label:
			label.text = "Loading" + dots

	# ==================================
	# 2. PROGRESS BAR GÜNCELLEME
	# ==================================
	
	# Yükleme durumunu sürekli kontrol et
	load_status = ResourceLoader.load_threaded_get_status(target_scene_path, progress)
	
	# Progress Bar'ı minimum kurala göre güncelle
	if progress.size() > 0:
		var yuzde = progress[0] * 100
		
		# Minimum %20 kuralı uygulanır
		var gosterilen_yuzde = max(yuzde, MIN_PROGRESS_THRESHOLD)
		
		progress_bar.value = gosterilen_yuzde

	# ==================================
	# 3. YÜKLEME TAMAMLANDI MI?
	# ==================================
	if load_status == ResourceLoader.THREAD_LOAD_LOADED:
		set_process(false) # İşlem bitti, döngüyü durdur
		
		var new_scene_resource = ResourceLoader.load_threaded_get(target_scene_path)
		
		get_tree().change_scene_to_packed(new_scene_resource)
		print("Completed!")
		
	elif load_status == ResourceLoader.THREAD_LOAD_FAILED:
		print("❌ Hata: Sahne yüklenemedi! Yol hatalı olabilir.")
		set_process(false)
