extends Control

@onready var windows = $Windows

# ARTIK PRELOAD YOK! (Donma sebebi buydu, sildik)
# Town yükleme işini artık MainGame ve LoadingScreen yapıyor.

func _ready():
	# AvatarIcon, Frame altında yer alıyor.
	if has_node("TopLeftButtons/Frame/AvatarIcon"):
		$TopLeftButtons/Frame/AvatarIcon.pressed.connect(show_avatar)
	
	# TopRightButtons altındaki diğer butonlar
	if has_node("TopRightButtons/MissionsButton"):
		$TopRightButtons/MissionsButton.pressed.connect(show_missions)
	if has_node("TopRightButtons/SettingsButton"):
		$TopRightButtons/SettingsButton.pressed.connect(show_settings)

	print("✅ UI bağlantıları başarıyla kuruldu.")

### --- Pencere Yönetim Fonksiyonları --- ###

func hide_all_windows():
	"""Windows düğümünün altındaki tüm çocukları (pencereleri) gizler."""
	if windows:
		for w in windows.get_children():
			w.visible = false
	print("Tüm pencereler gizlendi.")

func hide_all_ui():
	"""Tüm UI öğelerini gizler (login/signup/forgotpassword/cutscene için)."""
	$TopLeftButtons.visible = false
	$TopRightButtons.visible = false
	hide_all_windows()
	
	# Joystick varsa gizle
	if has_node("Joystick"):
		$Joystick.visible = false
		
	print("UI öğeleri tamamen gizlendi.")

func show_avatar():
	"""AvatarWindow'u gösterir."""
	hide_all_windows()
	if has_node("Windows/AvatarWindow"):
		$Windows/AvatarWindow.visible = true
		print("🟢 AvatarWindow açıldı.")

func show_missions():
	"""MissionsWindow'u gösterir."""
	hide_all_windows()
	if has_node("Windows/MissionsWindow"):
		$Windows/MissionsWindow.visible = true
		print("🟢 MissionsWindow açıldı.")

func show_settings():
	"""SettingsWindow'u gösterir."""
	hide_all_windows()
	if has_node("Windows/SettingsWindow"):
		$Windows/SettingsWindow.visible = true
		print("🟢 SettingsWindow açıldı.")
	
func show_only_top_right_buttons():
	"""Sadece TopRightButtons görünür, diğer her şey gizlenir."""
	$TopLeftButtons.visible = false
	hide_all_windows()
	if has_node("Joystick"):
		$Joystick.visible = false
	$TopRightButtons.visible = true
	
func change_scene_to(scene_path: String):
	"""
	Genel Sahne Değiştirici.
	UYARI: Bu fonksiyon artık 'MainGame' içindeki ev değişimleri için değil,
	Login -> Oyun veya Oyun -> Login gibi KÖKLÜ değişiklikler içindir.
	"""
	
	# 1. Verileri kaydet
	Globals.safe_local_save()

	# 2. Loading Screen sistemini kullan (Yeni Sistem)
	print("🔄 Sahne değiştiriliyor (Loading ile): ", scene_path)
	Globals.change_scene_with_loading(scene_path)

func show_full_ui():
	"""Town veya MainGame açıldığında UI elemanlarını görünür yapar."""
	$TopLeftButtons.visible = true
	$TopRightButtons.visible = true
	
	if has_node("Joystick"):
		$Joystick.visible = true 
		
	hide_all_windows() 
	print("✅ Tam UI görünür hale geldi.")
	
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		print("🔄 Oyun kapanırken veriler kaydediliyor...")
		Globals.finalize_save()


func return_to_town():
	print("🔙 Town'a dönülüyor...")
	
	# 1. YÖNTEM: Normal Oyun Modu (MainGame var mı?)
	var current_scene = get_tree().current_scene
	
	# Eğer sahnenin kendisi MainGame ise veya MainGame'i bulabiliyorsak
	if current_scene.has_method("exit_house"):
		current_scene.exit_house()
		return
	
	# MainGame ağacın tepesinde olabilir mi?
	if get_tree().root.has_node("MainGame"):
		var main_node = get_tree().root.get_node("MainGame")
		if main_node.has_method("exit_house"):
			main_node.exit_house()
			return

	# 2. YÖNTEM: Test Modu (MainGame yok)
	print("⚠️ Test Modu: Direkt Town sahnesi yükleniyor...")
	# Town sahnesinin yolunu buraya doğru yazdığından emin ol
	get_tree().change_scene_to_file("res://scenes/town.tscn")
	
	# UI'ı tekrar açalım ki joystick gelsin
	show_full_ui()
