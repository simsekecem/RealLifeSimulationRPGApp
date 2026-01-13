extends CharacterBody2D # Area2D yerine CharacterBody2D yaptık

# --- EDİTÖRDEN AYARLANACAK DEĞİŞKENLER ---
@export var wait_time: float = 1.0

var dialog_text: String = "MOOO!" 

# --- SAHNE BAĞLANTILARI ---
@onready var sprite = $Sprite2D
@onready var dialog_bubble = $DialogBubble
@onready var quest_label = $DialogBubble/Panel/QuestLabel
@onready var timer = $Timer
@onready var detection_area = $Area2D # Algılama alanını değişkene atadık

var has_triggered: bool = false
var player_ref: Node2D = null

func _ready():
	# 1. Timer Ayarları
	timer.wait_time = wait_time
	timer.one_shot = true
	
	# 2. Sinyalleri ALAN (Area2D) üzerinden bağla
	# 'body_entered' artık 'detection_area' düğümünden geliyor
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	timer.timeout.connect(_on_timer_timeout)
	
	# 3. Başlangıçta balonu gizle
	dialog_bubble.visible = false

func _process(_delta):
	if player_ref != null and not has_triggered:
		flip_towards_player()

# --- ALANA GİRİNCE (Area2D Sinyali) ---
func _on_body_entered(body):
	if body.is_in_group("player"):
		player_ref = body
		has_triggered = false
		timer.start()

# --- ALANDAN ÇIKINCA (Area2D Sinyali) ---
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
