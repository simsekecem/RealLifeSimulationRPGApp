extends Control

@onready var windows = $Windows

# Sol Üst Köşe Referansları
@onready var top_left_frame = $TopLeftButtons/Frame
@onready var avatar_icon = $TopLeftButtons/Frame/AvatarIcon
@onready var xp_bar = $TopLeftButtons/Frame/XPBar
@onready var username_text = $TopLeftButtons/Frame/UsernameText

func _ready():
	# Avatar Butonu Tıklaması
	if avatar_icon:
		avatar_icon.pressed.connect(show_avatar)
	
	# Sağ Üst Butonlar
	if has_node("TopRightButtons/MissionsButton"):
		$TopRightButtons/MissionsButton.pressed.connect(show_missions)
	if has_node("TopRightButtons/SettingsButton"):
		$TopRightButtons/SettingsButton.pressed.connect(show_settings)
	
	if has_node("Joystick"):
		# Eğer işletim sistemi Android veya iOS ise GÖSTER, değilse GİZLE.
		if OS.get_name() == "Android" or OS.get_name() == "iOS":
			$Joystick.visible = true
		else:
			$Joystick.visible = false # PC'de gizle
	
	# 👇 Veri değişince (İsim, XP veya Karakter değişince) burayı güncelle
	if Globals.has_signal("data_updated"):
		Globals.data_updated.connect(update_top_left_ui)
	
	# Başlangıçta verileri yükle
	update_top_left_ui()
	print("✅ UI bağlantıları başarıyla kuruldu.")

# =================================================
# 👇 GÜNCELLENDİ: SOL ÜST KÖŞE YÖNETİMİ
# =================================================
func update_top_left_ui():
	var user_data = Globals.cache.get("user", {})
	
	# 1. İsim
	if username_text:
		username_text.text = str(user_data.get("name", "Player"))
	
	# 2. XP Bar
	if xp_bar:
		var current_xp = int(user_data.get("experience", 0))
		var current_lvl = int(user_data.get("level", 1))
		
		# ❌ ESKİSİ: xp_bar.max_value = current_lvl * 100 
		# (Logic 300 isterken bu 100 gösterdiği için bar erken doluyordu)
		
		if Globals.has_method("get_required_xp"):
			xp_bar.max_value = Globals.get_required_xp(current_lvl)
		else:
			xp_bar.max_value = (current_lvl * 200) + 100
		xp_bar.value = current_xp
		xp_bar.tooltip_text = "Level: %d | XP: %d / %d" % [current_lvl, current_xp, xp_bar.max_value]

	# 3. 👇 YENİ: AVATAR İKONUNU GÜNCELLE
	if avatar_icon:
		var char_id = int(user_data.get("character_id", 1))
		
		# İkon dosya yolu (Eğer ikonların yoksa burayı normal resim yolu yapabilirsin)
		# Örnek İkon Yolu: res://assets/characters/icons/char_icon_1.png
		var path = "res://assets/characters/icons/char_icon_%d.png" % char_id
		
		# Eğer ikon dosyası yoksa, belki normal karakter dosyası vardır?
		if not ResourceLoader.exists(path):
			path = "res://assets/characters/char_%d.png" % char_id

		if ResourceLoader.exists(path):
			var tex = load(path)
			
			# AvatarIcon bir Button mu yoksa TextureRect mi? Ona göre atama yapalım.
			if avatar_icon is TextureButton:
				avatar_icon.texture_normal = tex
				# İkonun boyutunu korumak için (gerekirse)
				avatar_icon.ignore_texture_size = true
				avatar_icon.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			elif avatar_icon is TextureRect:
				avatar_icon.texture = tex
		else:
			print("⚠️ Avatar ikonu bulunamadı: ", path)

# =================================================
# PENCERE YÖNETİMİ (Burası aynı kalıyor)
# =================================================

func hide_all_windows():
	if windows:
		for w in windows.get_children():
			w.visible = false

func hide_all_ui():
	$TopLeftButtons.visible = false
	$TopRightButtons.visible = false
	hide_all_windows()
	if has_node("Joystick"): $Joystick.visible = false

func show_avatar():
	hide_all_windows()
	if has_node("Windows/AvatarWindow"):
		$Windows/AvatarWindow.visible = true
		if $Windows/AvatarWindow.has_method("update_ui_from_cache"):
			$Windows/AvatarWindow.update_ui_from_cache()

func show_missions():
	hide_all_windows()
	if has_node("Windows/MissionsWindow"):
		$Windows/MissionsWindow.visible = true

func show_settings():
	hide_all_windows()
	if has_node("Windows/SettingsWindow"):
		$Windows/SettingsWindow.visible = true
	
func show_only_top_right_buttons():
	$TopLeftButtons.visible = false
	hide_all_windows()
	if has_node("Joystick"): $Joystick.visible = false
	$TopRightButtons.visible = true
	
func change_scene_to(scene_path: String):
	Globals.save_cache()
	Globals.change_scene_with_loading(scene_path)

func show_full_ui():
	$TopLeftButtons.visible = true
	$TopRightButtons.visible = true
	if has_node("Joystick"):
		if OS.get_name() == "Android" or OS.get_name() == "iOS":
			$Joystick.visible = true
		else:
			$Joystick.visible = false
	hide_all_windows()
	update_top_left_ui() # UI açılınca bilgileri tazele

func return_to_town():
	var current_scene = get_tree().current_scene
	if current_scene.has_method("exit_house"):
		current_scene.exit_house()
		return
	if get_tree().root.has_node("MainGame"):
		var main_node = get_tree().root.get_node("MainGame")
		if main_node.has_method("exit_house"):
			main_node.exit_house()
			return
	get_tree().change_scene_to_file("res://scenes/town.tscn")
	show_full_ui()
