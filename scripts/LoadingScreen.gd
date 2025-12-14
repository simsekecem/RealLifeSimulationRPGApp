extends Control

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var label: Label = $Label

# --------------------
# AYARLAR
# --------------------
const MIN_PROGRESS_THRESHOLD: float = 20.0
const DOT_CHANGE_RATE: float = 0.25
const MAX_DOTS: int = 4
const MIN_LOADING_TIME: float = 1.2   # Minimum loading süresi

# --------------------
# DEĞİŞKENLER
# --------------------
var dot_timer: float = 0.0
var current_dot_count: int = 0

var target_scene_path: String = ""
var progress: Array = []
var load_status: int = 0

var loading_time: float = 0.0
var is_loaded: bool = false

# --------------------
# READY
# --------------------
func _ready() -> void:
	# Pause olsa bile process çalışsın
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)

	# UI gizle
	if UI.has_node("UIRoot"):
		UI.get_node("UIRoot").hide_all_ui()

	# ProgressBar ayarları
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = MIN_PROGRESS_THRESHOLD

	# Label başlangıç
	label.text = "Loading"

	# Hedef sahne
	target_scene_path = Globals.next_scene_path
	if target_scene_path == "":
		print("❌ Hata: Yüklenecek sahne yolu boş!")
		return

	# Threaded loading başlat
	ResourceLoader.load_threaded_request(target_scene_path)
	print("⏳ Loading başladı:", target_scene_path)

# --------------------
# PROCESS
# --------------------
func _process(delta: float) -> void:
	loading_time += delta

	# --------------------
	# 1️⃣ Nokta animasyonu
	# --------------------
	dot_timer += delta
	if dot_timer >= DOT_CHANGE_RATE:
		dot_timer = 0.0
		current_dot_count += 1
		if current_dot_count > MAX_DOTS:
			current_dot_count = 0
		label.text = "Loading" + ".".repeat(current_dot_count)

	# --------------------
	# 2️⃣ Progress kontrolü
	# --------------------
	load_status = ResourceLoader.load_threaded_get_status(target_scene_path, progress)

	if progress.size() > 0:
		var yuzde: float = progress[0] * 100.0
		progress_bar.value = clamp(
			max(yuzde, MIN_PROGRESS_THRESHOLD),
			MIN_PROGRESS_THRESHOLD,
			99.0
		)
	else:
		# Fake smooth progress (20 → 90)
		progress_bar.value = lerp(progress_bar.value, 90.0, delta * 2.0)
		progress_bar.value = max(progress_bar.value, MIN_PROGRESS_THRESHOLD)

	# Thread bitti mi?
	if load_status == ResourceLoader.THREAD_LOAD_LOADED:
		is_loaded = true

	# --------------------
	# 3️⃣ Sahne geçişi
	# --------------------
	if is_loaded and loading_time >= MIN_LOADING_TIME:
		progress_bar.value = 100
		await get_tree().process_frame  # %100 bir frame göster
		set_process(false)

		var new_scene = ResourceLoader.load_threaded_get(target_scene_path)
		get_tree().change_scene_to_packed(new_scene)

	elif load_status == ResourceLoader.THREAD_LOAD_FAILED:
		print("❌ Hata: Sahne yüklenemedi!")
		set_process(false)
