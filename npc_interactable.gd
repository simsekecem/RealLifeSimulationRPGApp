extends Area2D

# --- EDİTÖRDEN AYARLANACAK DEĞİŞKENLER (@export) ---
# Görsel ve Region ayarları artık editörde kalıcı olarak yapıldığı için sadece etkileşim ayarları kaldı.
@export_enum("Gym", "Market", "Restaurant", "Library") var interact_type: String = "Library" # Library olarak ayarlandı
@export_multiline var dialog_text: String = "Lütfen sessiz ol, ama o kayıp kitabı bulabilir misin?" # Library metni
@export var wait_time: float = 2.0

# --- SAHNE BAĞLANTILARI ---
@onready var sprite = $Sprite2D
@onready var dialog_bubble = $DialogBubble
@onready var quest_label = $DialogBubble/Panel/QuestLabel
@onready var timer = $Timer

var has_triggered: bool = false # Balon açıldı mı?
var player_ref: Node2D = null # Oyuncuyu takip etmek için

func _ready():
	# Artık görsel ayarı kodda yapılmıyor. Editörde kalıcı ayarlandı.
	
	# 2. Timer Ayarları
	timer.wait_time = wait_time
	timer.one_shot = true
	
	# 3. Sinyalleri Bağla
	timer.timeout.connect(_on_timer_timeout)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# 4. Başlangıçta balonu gizle
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
		print("⏳ ", interact_type, " bekleme modu...")

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
	print("✅ Görev: ", interact_type)
	
	# Balondaki yazıyı ayarla
	quest_label.text = dialog_text
	# Balonu görünür yap
	dialog_bubble.visible = true
	
	# Şimdilik görev yok, sonra buraya eklenecek
	interaction_logic()

func interaction_logic():
	match interact_type:
		"Gym":
			pass
		"Market":
			pass
		"Restaurant":
			pass
		"Library":
			pass
