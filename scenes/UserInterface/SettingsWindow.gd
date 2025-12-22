extends Control

@onready var close_button = $Background/CloseButton
@onready var volume_slider: HSlider = $VolumeSlider

func _ready():
	# CloseButton'a basılınca pencereyi kapatma fonksiyonunu bağla
	close_button.pressed.connect(hide_settings_window)
	
	# --- YENİ KISIM: BAŞLANGIÇ DEĞERİNİ YÜKLE ---
	# Globals.cache içindeki 'preferences' kısmından kayıtlı sesi al.
	# Eğer kayıt yoksa varsayılan olarak 50 kullan.
	var saved_volume = 50
	if Globals.cache.has("preferences") and Globals.cache["preferences"].has("music_volume"):
		saved_volume = Globals.cache["preferences"]["music_volume"]
	
	# Slider'ın konumunu kayıtlı değere getir
	volume_slider.value = saved_volume
	
	# Oyun açıldığında (veya bu pencere ilk yüklendiğinde) sesin doğru çıkması için ayarı uygula
	_apply_volume(saved_volume)
	
	print("SettingsWindow bağlantıları kuruldu. Ses seviyesi: ", saved_volume)

func hide_settings_window():
	"""SettingsWindow'u tamamen gizler."""
	
	# --- YENİ KISIM: KAPATIRKEN KAYDET ---
	# Kullanıcı ayarını bitirdi, pencereyi kapatıyor.
	# Şimdi yerel dosyaya (user://user_cache.json) yazabiliriz.
	Globals.save_cache()
	print("Tercihler yerel dosyaya kaydedildi.")
	
	# Bu düğümün kendisini (SettingsWindow'u) gizler.
	self.visible = false
	print("SettingsWindow kapandı.")

func _on_volume_slider_value_changed(value):
	# 1. Sesi sistemde değiştir (AudioServer)
	_apply_volume(value)
	
	# 2. Değeri Globals'daki cache değişkenine işle
	# (Henüz diske kaydetmiyoruz, sadece hafızada güncelliyoruz)
	if Globals.cache.has("preferences"):
		Globals.cache["preferences"]["music_volume"] = value
		# 👇 GÖREV TETİKLEYİCİSİ
	var q_manager = get_node_or_null("/root/QuestManager")
	if q_manager:
		q_manager.trigger_action("first_music")

# Yardımcı fonksiyon: Sesi AudioServer'a uygular
func _apply_volume(value):
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"), # "Music" bus'ının var olduğundan emin ol
		db
	)
