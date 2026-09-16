extends CharacterBody2D # Changed from Area2D to CharacterBody2D

# --- EXPORT VARIABLES ---
@export var wait_time: float = 1.0

var dialog_text: String = "MOOO!" 

# --- SCENE NODE REFERENCES ---
@onready var sprite = $Sprite2D
@onready var dialog_bubble = $DialogBubble
@onready var quest_label = $DialogBubble/Panel/QuestLabel
@onready var timer = $Timer
@onready var detection_area = $Area2D # Detection trigger area

var has_triggered: bool = false
var player_ref: Node2D = null

func _ready():
	# 1. Timer Configuration
	timer.wait_time = wait_time
	timer.one_shot = true
	
	# 2. Connect signals through Area2D
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	timer.timeout.connect(_on_timer_timeout)
	
	# 3. Hide dialogue bubble initially
	dialog_bubble.visible = false

func _process(_delta):
	if player_ref != null and not has_triggered:
		flip_towards_player()

# --- AREA ENTERED (Area2D Signal) ---
func _on_body_entered(body):
	if body.is_in_group("player"):
		player_ref = body
		has_triggered = false
		timer.start()

# --- AREA EXITED (Area2D Signal) ---
func _on_body_exited(body):
	if body == player_ref:
		timer.stop()
		player_ref = null
		has_triggered = false
		dialog_bubble.visible = false

func _on_timer_timeout():
	if player_ref != null:
		has_triggered = true
		show_dialogue()

func flip_towards_player():
	if player_ref.global_position.x < global_position.x:
		sprite.flip_h = false
	else:
		sprite.flip_h = true

func show_dialogue():
	quest_label.text = dialog_text 
	dialog_bubble.visible = true
