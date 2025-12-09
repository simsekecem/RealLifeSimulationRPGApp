extends Control


@onready var windows = $Windows
var TownScene = preload("res://scenes/town.tscn")

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

	for w in windows.get_children():
		w.visible = false
		print("Tüm pencereler gizlendi.") 
		
func hide_all_ui():
	"""Tüm UI öğelerini gizler (login/signup/forgotpassword için)."""
	$TopLeftButtons.visible = false
	$TopRightButtons.visible = false
	hide_all_windows()
	$Joystick.visible = false
	print("UI öğeleri tamamen gizlendi.")

func show_avatar():
	"""AvatarWindow'u gösterir."""
	hide_all_windows()

	$Windows/AvatarWindow.visible = true
	print("🟢 AvatarWindow açıldı.")

func show_missions():
	"""MissionsWindow'u gösterir."""
	hide_all_windows()

	$Windows/MissionsWindow.visible = true
	print("🟢 MissionsWindow açıldı.")

func show_settings():
	"""SettingsWindow'u gösterir."""
	hide_all_windows()

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
	# SAHNE DEĞİŞMEDEN ÖNCE CACHE KAYDEDİLİR
	Globals.finalize_save()

	var error := OK 

	if scene_path == "res://scenes/town.tscn":
		error = get_tree().change_scene_to_packed(TownScene)
	else:
		error = get_tree().change_scene_to_file(scene_path)

	if error != OK:
		print("❌ GLOBAL SAHNE DEĞİŞİKLİĞİ HATASI (ERROR:", error, ")")
		print("Lütfen sahne yolunu kontrol edin: ", scene_path)
	else:
		print("✅ Sahne başarıyla değiştirildi: ", scene_path)


func show_full_ui():
	"""Town sahnesine dönüldüğünde tüm ana UI elemanlarını görünür yapar."""
	# $TopLeftButtons ve $TopRightButtons'ı gösterir
	$TopLeftButtons.visible = true
	$TopRightButtons.visible = true
	$Joystick.visible = true # Joystick'i de geri aç
	hide_all_windows() # Her ihtimale karşı tüm pencereleri kapat
	print("✅ Tam UI (Avatar dahil) görünür hale geldi.")
