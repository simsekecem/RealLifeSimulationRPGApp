extends Control

@onready var bg = $BG
@onready var handle = $Handle

@export var max_distance := 100.0

var dragging := false
var direction := Vector2.ZERO

func _ready():
	# Başlangıçta merkeze al
	_reset_handle()

func _gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			dragging = true
			# event.position zaten LOCAL (bu node'a göre) olduğu için sorun yok
			_update_handle(event.position)
		else:
			dragging = false
			_reset_handle()

	elif event is InputEventScreenDrag and dragging:
		_update_handle(event.position)

func _update_handle(local_pos: Vector2):
	var center = bg.position + bg.size / 2
	var delta = local_pos - center

	# Maksimum mesafeyi aşma
	if delta.length() > max_distance:
		delta = delta.normalized() * max_distance

	# Handle pozisyonu
	handle.position = center + delta - handle.size / 2

	# --------- EĞRİLİ HIZ HESABI ---------
	var strength: float = delta.length() / max_distance

	# Eğri uygula
	# 1.0 = lineer
	# 0.6 = önerilen
	strength = pow(strength, 0.6)

	# Yön + güç
	if delta.length() > 0.0:
		direction = delta.normalized() * strength
	else:
		direction = Vector2.ZERO


func _reset_handle():
	# Burada da position kullanıyoruz
	handle.position = bg.position + bg.size / 2 - handle.size / 2
	direction = Vector2.ZERO
