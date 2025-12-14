extends CharacterBody2D

@export var speed: float = 150.0  # Karakterin hızı
@export var accel: float = 20.0   # Hızlanma
@export var friction: float = 20.0 # Durma

@onready var anim = $AnimatedSprite2D 

# Karakter durduğunda en son baktığı yöne baksın diye bir değişken
var last_direction = Vector2.DOWN 

func _physics_process(delta):
	var direction = Vector2.ZERO

	# ---------------------------------------------------------
	# 1. JOYSTICK KONTROLÜ (GÜNCELLENDİ)
	# ---------------------------------------------------------
	if UI.has_node("UIRoot/Joystick"):
		var joystick = UI.get_node("UIRoot/Joystick")
		
		if "direction" in joystick and joystick.direction.length() > 0:
			# DÜZELTME BURADA YAPILDI:
			# Joystick yönünü 1.5 ile çarpıyoruz (Hassasiyeti artırıyoruz).
			# limit_length(1.0) ile de hızın tavanı delmesini engelliyoruz.
			direction = (joystick.direction * 1.5).limit_length(1.0)

	# ---------------------------------------------------------
	# 2. KLAVYE KONTROLÜ (WASD ve OK TUŞLARI)
	# ---------------------------------------------------------
	# Eğer joystick kullanılmıyorsa klavyeye bak
	if direction == Vector2.ZERO:
		direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# ---------------------------------------------------------
	# 3. HAREKET VE ANİMASYON
	# ---------------------------------------------------------
	if direction != Vector2.ZERO:
		# Hareket var: Hızlan
		velocity = velocity.lerp(direction * speed, accel * delta)
		
		# Son yönü kaydet
		last_direction = direction
		
		# Yürüme animasyonunu oynat
		play_animation("walk")
	else:
		# Hareket yok: Dur
		velocity = velocity.lerp(Vector2.ZERO, friction * delta)
		
		# Durma (Idle) animasyonunu oynat
		play_animation("idle")

	move_and_slide()

func play_animation(action_name: String):
	var dir_suffix = "_down" # Varsayılan aşağı
	
	if abs(last_direction.x) > abs(last_direction.y):
		# Yatay hareket daha baskın
		if last_direction.x > 0:
			dir_suffix = "_right"
		else:
			dir_suffix = "_left"
	else:
		# Dikey hareket daha baskın
		if last_direction.y > 0:
			dir_suffix = "_down"
		else:
			dir_suffix = "_up"
	
	var final_anim_name = action_name + dir_suffix
	anim.play(final_anim_name)
