extends CharacterBody2D

@export var speed: float = 150.0  # Karakterin hızı
@export var accel: float = 20.0   # Hızlanma
@export var friction: float = 20.0 # Durma

@onready var anim = $AnimatedSprite2D 

# --- YENİ EKLENEN KISIM 1: KAMERAYA ERİŞİM ---
# Player sahnesinin içindeki "Camera2D" isimli node'u bulur.
# Eğer ismini değiştirdiysen burayı da değiştir.
@onready var camera = $Camera2D 

var last_direction = Vector2.DOWN 

# --- YENİ EKLENEN KISIM 2: KAMERAYI ZORLA AKTİF ETME ---
func _ready():
	# Karakter sahneye girdiği an (ister Town, ister Ev olsun)
	# kamerayı kendine çeker. Zoom ayarların yüklenir.
	if camera:
		camera.make_current()

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
	anim.play(final_anim_name)
