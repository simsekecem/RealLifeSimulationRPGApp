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
	# DÜZELTME BURADA:
	# global_position yerine sadece position kullanıyoruz.
	# Böylece Joystick ekranın neresinde olursa olsun kendi içine göre hesap yapar.
	
	var center = bg.position + bg.size / 2
	var delta = local_pos - center

	if delta.length() > max_distance:
		delta = delta.normalized() * max_distance

	# handle.global_position yerine handle.position kullanıyoruz
	handle.position = center + delta - handle.size / 2
	
	direction = delta / max_distance

func _reset_handle():
	# Burada da position kullanıyoruz
	handle.position = bg.position + bg.size / 2 - handle.size / 2
	direction = Vector2.ZERO
