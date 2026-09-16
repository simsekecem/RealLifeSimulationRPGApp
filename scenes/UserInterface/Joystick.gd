extends Control

@onready var bg = $BG
@onready var handle = $Handle

@export var max_distance := 100.0

var dragging := false
var direction := Vector2.ZERO

func _ready():
	# Center handle on start
	_reset_handle()

func _gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			dragging = true
			# event.position is local to this node
			_update_handle(event.position)
		else:
			dragging = false
			_reset_handle()

	elif event is InputEventScreenDrag and dragging:
		_update_handle(event.position)

func _update_handle(local_pos: Vector2):
	var center = bg.position + bg.size / 2
	var delta = local_pos - center

	# Clamp to max distance
	if delta.length() > max_distance:
		delta = delta.normalized() * max_distance

	# Update handle position
	handle.position = center + delta - handle.size / 2

	# --------- CURVED SPEED CALCULATION ---------
	var strength: float = delta.length() / max_distance

	# Apply curve
	# 1.0 = linear
	# 0.6 = recommended
	strength = pow(strength, 0.6)

	# Direction + strength
	if delta.length() > 0.0:
		direction = delta.normalized() * strength
	else:
		direction = Vector2.ZERO


func _reset_handle():
	# Reset handle to center
	handle.position = bg.position + bg.size / 2 - handle.size / 2
	direction = Vector2.ZERO
