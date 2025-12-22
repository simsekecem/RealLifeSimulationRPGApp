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
	print("🔍 Görev Listeleniyor: ", all_quests.size(), " adet bulundu.")
	load_missions(all_quests)

func load_missions(missions: Array):
	# Eski listeyi temizle
	for child in missions_list.get_children():
		child.queue_free()

	for quest in missions:
		var row = mission_row_scene.instantiate()
		
		# --- DÜĞÜM YOLLARI (Hiyerarşine göre güncellendi) ---
		var name_label = row.get_node("MissionList/MissionName")
		var detail_label = row.get_node("MissionList/MissionDetail")
		var xp_label = row.get_node("MissionList/HBoxContainer/XP")
		
		# 👇 Senin görselindeki düğüm adı: "Completed" 
		# MissionRow'a direkt bağlı olduğu için başına yol eklemiyoruz
		var tick_icon = row.get_node_or_null("Completed") 
		
		# Verileri ata
		name_label.text = quest.get("description", "Mission")
		xp_label.text = str(quest.get("xp_reward", 0)) + " XP"
		
		var type_text = "[DAILY]" if quest.get("type") == "daily" else "[STORY]"
		detail_label.text = type_text + " Task"
		
		# --- TAMAMLANMA KONTROLÜ ---
		if quest.get("is_completed", false):
			# Eğer görev bittiyse "Completed" düğümünü göster
			if tick_icon:
				tick_icon.visible = true
			
			# İsteğe bağlı: İsmi de yeşil yapalım ki net anlaşılsın
			name_label.add_theme_color_override("font_color", Color.GREEN)
		else:
			# Bitmediyse gizle
			if tick_icon:
				tick_icon.visible = false
		
		missions_list.add_child(row)

func hide_missions_window():
	self.visible = false
