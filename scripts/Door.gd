extends Area2D

# Editörden seçebileceğin bir dosya yolu değişkeni
# @export_file diyerek sadece .tscn dosyalarını seçmeni sağlıyoruz
@export_file("*.tscn") var target_scene_path: String = ""

func _ready():
	# body_entered sinyalini koda bağlayalım
	# (Bunu editörden Node sekmesinden de yapabilirsin ama kodla daha temiz)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Çarpan şey Karakter mi?
	# Karakterine "player" grubunu eklemeyi unutma! (Aşağıda anlatacağım)
	if body.is_in_group("player"):
		if target_scene_path == "":
			print("⚠️ Hata: Bu kapının hedef sahnesi seçilmemiş!")
			return
			
		print("🚪 Kapıya gelindi, içeri giriliyor: ", target_scene_path)
		
		# MainGame'e ulaş ve içeri girme fonksiyonunu çalıştır
		var main_game = get_tree().current_scene
		
		if main_game.has_method("enter_house"):
			main_game.enter_house(target_scene_path)
		else:
			print("MainGame bulunamadı! (Test modunda olabilirsin)")
