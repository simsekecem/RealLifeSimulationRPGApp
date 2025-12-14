extends Area2D

# Hedef sahne (Giriş kapısıysa burası dolu olur)
@export_file("*.tscn") var target_scene_path: String = ""

# Bu bir çıkış kapısı mı? (Inspector'dan işaretleyeceğiz)
@export var is_exit_door: bool = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("🚪 Kapı tetiklendi!")

		# --- DURUM 1: EVDEN ÇIKIŞ ---
		if is_exit_door:
			print("🔙 Town'a dönülüyor...")
			# UIRoot'taki güvenli dönüş fonksiyonunu kullanıyoruz
			if UI.has_node("UIRoot"):
				UI.get_node("UIRoot").return_to_town()
			return

		# --- DURUM 2: EVE GİRİŞ ---
		if target_scene_path == "":
			print("⚠️ Hata: Kapının hedefi seçilmemiş!")
			return

		# MainGame'i bulma ve içeri girme kodu (Daha önce yazdığımız aynısı)
		var current_node = self
		var main_game = null
		
		while current_node:
			if current_node.has_method("enter_house"):
				main_game = current_node
				break
			current_node = current_node.get_parent()
		
		if main_game:
			main_game.enter_house(target_scene_path)
		else:
			# Test modu
			get_tree().change_scene_to_file(target_scene_path)
