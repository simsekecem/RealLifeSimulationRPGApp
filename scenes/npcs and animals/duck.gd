# Duck.gd
extends CharacterBody2D

# --- Yapılandırma Değişkenleri ---

@export var speed: float = 20.0 
const MIN_WAIT_TIME: float = 0.1 # Bekleme süresini kısalttım
const MAX_WAIT_TIME: float = 0.2 # Bekleme süresini kısalttım

# --- DÜZ ÇİZGİ KOORDİNATLARI (Y YATAY KALACAK) ---
# Ördeğin hareket edeceği çizgi üzerindeki BAŞLANGIÇ ve BİTİŞ noktaları
# Y koordinatını aynı tutarak düz bir hat oluşturuyoruz.
const START_POINT: Vector2 = Vector2(986, 230) # Soldaki nokta (Xmin)
const END_POINT: Vector2 = Vector2(1268, 230)   # Sağdaki nokta (Xmax)

# --- İç Değişkenler ---
const TARGET_TOLERANCE: float = 5.0
var target_position: Vector2 = END_POINT # Başlangıçta END_POINT'e doğru yola çık
var is_moving_to_end: bool = true        # Bitiş noktasına mı gidiyor?
var time_to_next_target: float = 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# --- Godot Fonksiyonları ---

func _ready() -> void:
	randomize() 
	# Oyun başladığında ördeği başlangıç noktasına ayarla (istenirse)
	global_position = START_POINT 
	time_to_next_target = 1.0 # Hemen harekete başla

func _physics_process(delta: float) -> void:
	if time_to_next_target > 0:
		var distance_to_target: float = global_position.distance_to(target_position)

		if distance_to_target < TARGET_TOLERANCE:
			# HEDEFE ULAŞILDI: Dur, bekleme süresini başlat ve hedefi değiştir
			velocity = Vector2.ZERO
			
			# Bekleme süresini ayarla
			time_to_next_target = -randf_range(MIN_WAIT_TIME, MAX_WAIT_TIME)
			
			animated_sprite.play("swim_right") # Dururken de animasyon devam edebilir
			animated_sprite.flip_h = false # Animasyonu sıfırla
			return

		# HAREKET ETME
		var direction: Vector2 = global_position.direction_to(target_position)
		velocity = direction * speed
		move_and_slide()
		
		update_animation(direction)
		
	else:
		# BEKLEME BİTTİ: Yeni hedefi belirle
		time_to_next_target += delta # time_to_next_target negatif olduğu için delta eklenir.
		if time_to_next_target >= 0:
			switch_target()

# --- Özel Fonksiyonlar ---

func switch_target() -> void:
	# Hedefi tersine çevir
	is_moving_to_end = !is_moving_to_end
	
	if is_moving_to_end:
		target_position = END_POINT
	else:
		target_position = START_POINT
		
	# Hemen yüzmeye başla
	time_to_next_target = 1.0 

func update_animation(direction: Vector2) -> void:
	animated_sprite.play("swim_right") 
	
	if direction.x > 0.1: # Sağa Yüzme
		animated_sprite.flip_h = false 
	elif direction.x < -0.1: # Sola Yüzme
		animated_sprite.flip_h = true
