extends CharacterBody2D

# --- EDİTÖRDEN AYARLANACAK DEĞİŞKENLER ---
@export var wait_time: float = 1.0
var dialog_text: String = "Hello!" 

# --- SAHNE BAĞLANTILARI ---
@onready var sprite = $Sprite2D
@onready var dialog_bubble = $DialogBubble
@onready var quest_label = $DialogBubble/Panel/QuestLabel
@onready var timer = $Timer

# 👇 YENİ: Etkileşim alanını koda tanıtıyoruz (Görseldeki ismine göre)
@onready var interaction_area = $Area2D 

var has_triggered: bool = false 
var player_ref: Node2D = null 

func _ready():
	# 1. Timer Ayarları
	timer.wait_time = wait_time
	timer.one_shot = true
	
	# 2. Sinyalleri Bağla (DÜZELTİLEN KISIM)
	timer.timeout.connect(_on_timer_timeout)
	
	# HATA BURADAYDI: "body_entered" ana karakterde (CharacterBody2D) çalışmaz.
	# Bunu altındaki "interaction_area" (Area2D) üzerinden çağırmalıyız.
	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)
	else:
		print("HATA: Area2D düğümü bulunamadı!")
	
	# 3. Başlangıçta balonu gizle
	dialog_bubble.visible = false

func _process(_delta):
	if player_ref != null and not has_triggered:
		flip_towards_player()

# --- ALANA GİRİNCE (Sinyal Area2D'den geliyor) ---
func _on_body_entered(body):
	if body.is_in_group("player"):
		player_ref = body 
		has_triggered = false
		timer.start() 

# --- ALANDAN ÇIKINCA (Sinyal Area2D'den geliyor) ---
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
		show_dialogue()

# --- OYUNCUYA DÖNME FONKSİYONU ---
func flip_towards_player():
	# NPC'nin ve oyuncunun X pozisyonlarını karşılaştır
	if player_ref.global_position.x < global_position.x:
		# Oyuncu soldaysa
		sprite.flip_h = false 
	else:
		# Oyuncu sağdaysa
		sprite.flip_h = true 

func show_dialogue():
	quest_label.text = dialog_text 
	dialog_bubble.visible = true
