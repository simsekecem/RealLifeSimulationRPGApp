extends CharacterBody2D

@export var speed: float = 150.0  # Karakterin hızı
@export var accel: float = 20.0   # Hızlanma
@export var friction: float = 20.0 # Durma

@onready var anim = $AnimatedSprite2D 

# --- KAMERA ---
@onready var camera = $Camera2D 

var last_direction = Vector2.DOWN 

func _ready():
	# 1. Kamera Ayarı
	if camera:
		camera.make_current()
	
	# 👇 YENİ: KARAKTER GÖRÜNÜMÜNÜ YÜKLE
	# Oyun açıldığında Globals'a bakıp doğru kıyafeti (SpriteFrames) giyer.
	load_character_visuals()

# 👇 YENİ FONKSİYON: Animasyon Paketini Değiştirir
func load_character_visuals():
	# 1. Global veriden seçili karakter ID'sini al (Yoksa 1 varsay)
	# cache.user içinden veriyi güvenli şekilde alıyoruz
	var user_data = Globals.cache.get("user", {})
	var char_id = int(user_data.get("character_id", 1))
	
	# 2. Dosya yolunu oluştur (Örn: res://assets/characters/resources/char_2.tres)
	var path = "res://assets/characters/resources/char_%d.tres" % char_id
	
	# 3. Dosya varsa yükle ve karaktere giydir
	if ResourceLoader.exists(path):
		var new_frames = load(path)
		# Eğer yüklenen şey gerçekten SpriteFrames ise
		if new_frames is SpriteFrames:
			anim.sprite_frames = new_frames
			# Görünüm değişince "Idle" moduna geç ki ekranda hemen güncellensin
			play_animation("idle")
			print("✅ Player karakteri yüklendi: ID ", char_id)
		else:
			print("⚠️ Hata: Yüklenen dosya SpriteFrames formatında değil!")
	else:
		print("⚠️ Hata: Karakter dosyası bulunamadı -> ", path)
		# Dosya yoksa oyun çökmesin diye varsayılan (editörde seçili olan) kalır.

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
	
	# Çökme önleyici: Eğer yeni yüklenen pakette bu animasyon yoksa hata vermesin
	if anim.sprite_frames.has_animation(final_anim_name):
		anim.play(final_anim_name)
	else:
		# Yeni pakette animasyon ismi hatalıysa konsola yazsın (Debug için)
		print_debug("Animasyon bulunamadı: ", final_anim_name)
