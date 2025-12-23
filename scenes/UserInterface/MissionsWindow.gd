extends Control

@export var mission_row_scene: PackedScene = preload("res://scenes/prefabs/MissionRow.tscn")
@onready var missions_list = $ScrollContainer/MissionsPanel
@onready var close_button = $Background/CloseButton 

func _ready():
	close_button.pressed.connect(hide_missions_window)
	
	# Sinyali bağla (Görev tamamlandığında veya yenilendiğinde tetiklenir)
	if Globals.has_signal("data_updated"):
		Globals.data_updated.connect(refresh_mission_list)
	
	# 👇 KRİTİK: QuestManager'ın statik görevleri Globals'a yazması için 
	# çok kısa bir süre (0.1sn) bekliyoruz.
	await get_tree().create_timer(0.1).timeout
	refresh_mission_list()

func refresh_mission_list():
	var all_quests = Globals.cache.get("quests", [])
	
	# --- SIRALAMA MANTIĞI ---
	var daily_quests = []
	var other_quests = []
	
	# Görevleri türüne göre iki ayrı listeye ayırıyoruz
	for q in all_quests:
		if q.get("type") == "daily":
			daily_quests.append(q)
		else:
			other_quests.append(q)
	
	# Önce Daily olanları, sonra diğerlerini birleştirip gönderiyoruz
	var sorted_quests = daily_quests + other_quests
	
	print("🔍 Görev Listeleniyor: ", sorted_quests.size(), " adet. (Daily öncelikli)")
	load_missions(sorted_quests)

func load_missions(missions: Array):
	# Eski listeyi temizle
	for child in missions_list.get_children():
		child.queue_free()

	for quest in missions:
		var row = mission_row_scene.instantiate()
		
		# --- DÜĞÜM YOLLARI ---
		var name_label = row.get_node("MissionList/MissionName")
		var detail_label = row.get_node("MissionList/MissionDetail")
		var xp_label = row.get_node("MissionList/HBoxContainer/XP")
		
		# "Completed" düğümü (CheckBox olduğunu varsayıyoruz)
		var tick_icon = row.get_node_or_null("Completed") 
		
		# Verileri ata
		name_label.text = quest.get("description", "Mission")
		xp_label.text = str(quest.get("xp_reward", 0)) + " XP"
		
		var type_text = "[DAILY]" if quest.get("type") == "daily" else "[STORY]"
		detail_label.text = type_text + " Task"
		
		var is_done = quest.get("is_completed", false)

		# --- TİK İKONU AYARLARI ---
		if tick_icon:
			# 1. Her zaman görünür olsun
			tick_icon.visible = true
			
			# 2. Eğer görev bittiyse tikli olsun, bitmediyse boş olsun
			# (Eğer tick_icon bir CheckBox ise 'button_pressed' özelliğini kullanırız)
			if "button_pressed" in tick_icon:
				tick_icon.button_pressed = is_done
				
				# Kullanıcı elle tıklayıp değiştirmesin diye sadece görüntü yapalım:
				tick_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# --- RENK AYARI ---
		if is_done:
			# Tamamlananların yazısı yeşil olsun
			name_label.add_theme_color_override("font_color", Color.GREEN)
		else:
			# Tamamlanmayanlar normal (beyaz) kalsın
			name_label.add_theme_color_override("font_color", Color.WHITE)
		
		missions_list.add_child(row)

func hide_missions_window():
	self.visible = false
