extends Area2D

# --- EDİTÖRDEN AYARLANACAK DEĞİŞKENLER (@export) ---
# Artık sadece bekleme süresi var. İnek sadece "MOOO!" diyecek.
@export var wait_time: float = 1.0

# İnek her zaman sadece "MOOO!" diyecek, bu yüzden metni sabitliyoruz.
var dialog_text: String = "Hello!" 

# --- SAHNE BAĞLANTILARI ---
@onready var sprite = $Sprite2D
@onready var dialog_bubble = $DialogBubble
@onready var quest_label = $DialogBubble/Panel/QuestLabel
@onready var timer = $Timer

var has_triggered: bool = false # Balon açıldı mı?
var player_ref: Node2D = null # Oyuncuyu takip etmek için

func _ready():
	# 1. Timer Ayarları
	timer.wait_time = wait_time
	timer.one_shot = true
	
	# 2. Sinyalleri Bağla
	timer.timeout.connect(_on_timer_timeout)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# 3. Başlangıçta balonu gizle
	dialog_bubble.visible = false

func _process(_delta):
	# Eğer oyuncu alandaysa ve balon henüz açılmadıysa oyuncuya dön
	if player_ref != null and not has_triggered:
		flip_towards_player()

# --- ALANA GİRİNCE ---
func _on_body_entered(body):
	# Oyuncunun "player" grubunda olduğundan emin ol!
	if body.is_in_group("player"):
		player_ref = body # Oyuncuyu hafızaya al
		has_triggered = false
		timer.start() # Sayacı başlat
		# Loglama kaldırıldı veya sadeleştirildi.
		# print("⏳ Npc bekleme modu...")

# --- ALANDAN ÇIKINCA ---
func _on_body_exited(body):
	if body == player_ref:
		timer.stop() # Sayacı durdur
		player_ref = null
		has_triggered = false
		dialog_bubble.visible = false # Balonu kapat

# --- SÜRE DOLUNCA ---
func _on_timer_timeout():
	if player_ref != null:
		has_triggered = true
		show_dialogue()

# --- OYUNCUYA DÖNME FONKSİYONU ---
func flip_towards_player():
	if player_ref.global_position.x < global_position.x:
		sprite.flip_h = false # Oyuncu soldaysa sola bak
	else:
		sprite.flip_h = true # Oyuncu sağdaysa sağa bak

# --- KONUŞMA BALONUNU AÇ ---
func show_dialogue():
	# print("✅ İnek: MOOO!") # İstenirse bu satır kaldırılabilir
	
	# Balondaki yazıyı ayarla (Her zaman "MOOO!")
	quest_label.text = dialog_text 
	# Balonu görünür yap
	dialog_bubble.visible = true
	
	# İnek görev vermediği için interaction_logic'i çağırmaya gerek yok.

# interaction_logic() fonksiyonu artık gerekli değildir, kaldırılmıştır.
