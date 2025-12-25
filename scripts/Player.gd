extends CharacterBody2D

@export var speed: float = 150.0  # Karakterin hızı
@export var accel: float = 20.0    # Hızlanma
@export var friction: float = 20.0 # Durma

@onready var anim = $AnimatedSprite2D 

# --- KAMERA ---
@onready var camera = $Camera2D 

var last_direction = Vector2.DOWN 

# 👇 YENİ: Yüklenmiş olan karakter ID'sini takip etmek için
var current_visual_id: int = -1 

func _ready():
	# 1. Kamera Ayarı
	if camera:
		camera.make_current()
	
	# 👇 YENİ: Kamera sınırlarını otomatik ayarla
	# (call_deferred kullanıyoruz ki sahne tamamen yüklensin)
	call_deferred("setup_camera_limits")
	
	# 2. Karakter Görünümünü Yükle
	load_character_visuals()

	# 👇 Sinyal Bağlantısı
	if Globals.has_signal("data_updated"):
		if not Globals.data_updated.is_connected(load_character_visuals):
			Globals.data_updated.connect(load_character_visuals)
			print("✅ Player, global veri güncellemelerini dinlemeye başladı.")

# ============================================================
# 👇 YENİ: KAMERA SINIRLAMA FONKSİYONU 📷
# ============================================================
func setup_camera_limits():
	if camera == null: return

	# Player'ın eklendiği sahnedeki (Parent) zemin node'unu bulmaya çalışıyoruz.
	# Genelde adı "TileMap" veya "Ground" olur.
	var tilemap = get_parent().get_node_or_null("TileMap")
	
	if tilemap == null:
		tilemap = get_parent().get_node_or_null("Ground")
		
	if tilemap:
		# 1. Haritanın dolu olan kısmını (dikdörtgen) al
		var map_rect = tilemap.get_used_rect()
		
		# 2. Tile boyutunu (kare boyutu) al (örn: 16px veya 32px)
		var tile_size = tilemap.tile_set.tile_size
		
		# 3. Sol ve Üst sınır (Başlangıç noktası)
		camera.limit_left = map_rect.position.x * tile_size.x
		camera.limit_top = map_rect.position.y * tile_size.y
		
		# 4. Sağ ve Alt sınır (Başlangıç + Genişlik)
		camera.limit_right = (map_rect.position.x + map_rect.size.x) * tile_size.x
		camera.limit_bottom = (map_rect.position.y + map_rect.size.y) * tile_size.y
		
		print("📷 Kamera sınırları haritaya göre ayarlandı: ", map_rect)
	else:
		print("⚠️ Uyarı: Kamera sınırı için sahnede 'TileMap' veya 'Ground' bulunamadı.")

# --- KARAKTER GÖRÜNÜMÜNÜ YÜKLE ---
func load_character_visuals():
	# 1. Global veriden seçili karakter ID'sini al
	var user_data = Globals.cache.get("user", {})
	var char_id = int(user_data.get("character_id", 1))
	
	if char_id == current_visual_id:
		return
	
	# 2. Dosya yolunu oluştur
	var path = "res://assets/characters/resources/char_%d.tres" % char_id
	
	# 3. Dosya varsa yükle ve karaktere giydir
	if ResourceLoader.exists(path):
		var new_frames = load(path)
		if new_frames is SpriteFrames:
			anim.sprite_frames = new_frames
			play_animation("idle")
			
			current_visual_id = char_id
			print("🎭 [PLAYER] Görünüm güncellendi: ID ", char_id)
		else:
			print("⚠️ Hata: Yüklenen dosya SpriteFrames formatında değil!")
	else:
		print("⚠️ Hata: Karakter dosyası bulunamadı -> ", path)

func _physics_process(delta):
	var direction = Vector2.ZERO

	# 1. JOYSTICK KONTROLÜ
	if UI.has_node("UIRoot/Joystick"):
		var joystick = UI.get_node("UIRoot/Joystick")
		if "direction" in joystick and joystick.direction.length() > 0:
			direction = (joystick.direction * 1.5).limit_length(1.0)

	# 2. KLAVYE KONTROLÜ
	if direction == Vector2.ZERO:
		direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# 3. HAREKET VE ANİMASYON
	if direction != Vector2.ZERO:
		velocity = velocity.lerp(direction * speed, accel * delta)
		last_direction = direction
		play_animation("walk")
	else:
		velocity = velocity.lerp(Vector2.ZERO, friction * delta)
		play_animation("idle")

	move_and_slide()

func play_animation(action_name: String):
	var dir_suffix = "_down"
	
	if abs(last_direction.x) > abs(last_direction.y):
		if last_direction.x > 0:
			dir_suffix = "_right"
		else:
			dir_suffix = "_left"
	else:
		if last_direction.y > 0:
			dir_suffix = "_down"
		else:
			dir_suffix = "_up"
	
	var final_anim_name = action_name + dir_suffix
	
	if anim.sprite_frames.has_animation(final_anim_name):
		anim.play(final_anim_name)
	else:
		pass
