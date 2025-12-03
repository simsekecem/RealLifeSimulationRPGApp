extends Control

# Windows (Pencereler) düğümüne kolay erişim için @onready kullanılır
@onready var windows = $Windows

func _ready():
	# AvatarIcon, Frame altında yer alıyor.
	$TopLeftButtons/Frame/AvatarIcon.pressed.connect(show_avatar)
	
	# TopRightButtons altındaki diğer butonlar
	$TopRightButtons/MissionsButton.pressed.connect(show_missions)
	$TopRightButtons/SettingsButton.pressed.connect(show_settings)

	print("UI bağlantıları başarıyla kuruldu.")

### --- Pencere Yönetim Fonksiyonları --- ###

func hide_all_windows():
	"""Windows düğümünün altındaki tüm çocukları (pencereleri) gizler."""
	# $Windows altındaki tüm pencereleri döngü ile gizler
	for w in windows.get_children():
		w.visible = false
		print("Tüm pencereler gizlendi.") 

func show_avatar():
	"""AvatarWindow'u gösterir."""
	hide_all_windows()
	# Düğüm Yolu: UI/Windows/AvatarWindow
	$Windows/AvatarWindow.visible = true
	print("🟢 AvatarWindow açıldı.")

func show_missions():
	"""MissionsWindow'u gösterir."""
	hide_all_windows()
	# Düğüm Yolu: UI/Windows/MissionsWindow
	$Windows/MissionsWindow.visible = true
	print("🟢 MissionsWindow açıldı.")

func show_settings():
	"""SettingsWindow'u gösterir."""
	hide_all_windows()
	# Düğüm Yolu: UI/Windows/SettingsWindow
	$Windows/SettingsWindow.visible = true
	print("🟢 SettingsWindow açıldı.")
	
func show_only_top_right_buttons():
	"""Sadece TopRightButtons görünür, diğer her şey gizlenir (TopLeftButtons ve Joystick dahil)."""
	# TopLeftButtons'u gizle
	$TopLeftButtons.visible = false
	
	# Windows altındaki tüm pencereleri gizle
	hide_all_windows()
	
	# Joystick'i gizle
	$Joystick.visible = false
	
	# TopRightButtons'u göster
	$TopRightButtons.visible = true
	
func change_scene_to(scene_path: String):
	"""Verilen dosya yoluna (res://) sahip sahneye geçiş yapar.
	Bu fonksiyon, tüm sahneler arası geçişi merkezi olarak yönetir.
	"""
	
	# SceneTree objesini kullanarak sahneyi değiştiririz.
	var error = get_tree().change_scene_to_file(scene_path)
	
	if error != OK:
		# Konsolda hata varsa detaylı bilgi verilir.
		print("❌ GLOBAL SAHNE DEĞİŞİKLİĞİ HATASI (ERROR:", error, ")")
		print("Lütfen sahne yolunu kontrol edin: ", scene_path)
	else:
		print("✅ Sahne başarıyla değiştirildi: ", scene_path)
