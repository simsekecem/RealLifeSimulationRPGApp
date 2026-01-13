extends CharacterBody2D 

# --- EDİTÖRDEN AYARLANACAK DEĞİŞKENLER ---
@export var interact_type: String = "gym" 
@export var wait_time: float = 1.0

# --- SAHNE BAĞLANTILARI ---
@onready var sprite = $Sprite2D
@onready var dialog_bubble = $DialogBubble
@onready var quest_label = $DialogBubble/Panel/QuestLabel
@onready var timer = $Timer
@onready var interaction_area = $Area2D # Tetikleme sinyalleri buradan gelecek

var has_triggered: bool = false 
var player_ref: Node2D = null 

func _ready():
	timer.wait_time = wait_time
	timer.one_shot = true
	
	# Sinyalleri alt düğüm olan Area2D'den bağlıyoruz
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)
	
	timer.timeout.connect(_on_timer_timeout)
	dialog_bubble.visible = false

# --- ALANA GİRİNCE ---
func _on_body_entered(body):
	if body.is_in_group("player"):
		player_ref = body 
		has_triggered = false
		timer.start() 

# --- ALANDAN ÇIKINCA ---
func _on_body_exited(body):
	if body == player_ref:
		timer.stop() 
		player_ref = null
		has_triggered = false
		dialog_bubble.visible = false 

# --- SÜRE DOLUNCA ---
func _on_timer_timeout():
	if player_ref != null:
		has_triggered = true
		update_dialog_from_manager()
		show_dialogue()

# --- GÖREVİ HAFIZADAN ÇEKME (Gym Kategorisi) ---
func update_dialog_from_manager():
	if Globals.cache.has("quests"):
		var all_quests = Globals.cache["quests"]
		var found_quest_text = ""
		
		for q in all_quests:
			if q.get("category") == "gym" and q.get("type") == "daily":
				found_quest_text = q.get("description", "")
				break
		
		if found_quest_text != "":
			quest_label.text = found_quest_text
		else:
			quest_label.text = "No workout today. Rest up!"
	else:
		quest_label.text = "Gym data loading..."

func show_dialogue():
	dialog_bubble.visible = true

func _process(_delta):
	if player_ref != null and not has_triggered:
		flip_towards_player()

func flip_towards_player():
	if player_ref.global_position.x < global_position.x:
		sprite.flip_h = false 
	else:
		sprite.flip_h = true
