extends CanvasLayer

# Prefab'ın dosya yolunu buraya tanımlıyoruz (Preload ile ön yükleme yapılır)
const CHAT_MESSAGE_SCENE = preload("res://scenes/prefabs/chat_message_r.tscn")

# Mesajların ekleneceği liste düğümü
@onready var message_list = $MainWindow/MarginContainer/ContentLayout/ChatScroll/MessageList
# Scroll'u kontrol etmek için
@onready var chat_scroll = $MainWindow/MarginContainer/ContentLayout/ChatScroll
func add_message_to_chat(text: String, is_user: bool):
	# 1. Prefab'dan yeni bir nesne oluştur
	var new_message = CHAT_MESSAGE_SCENE.instantiate()
	
	# 2. Mesajı listeye (VBoxContainer) ekle
	message_list.add_child(new_message)
	
	# 3. Prefab içindeki verileri güncelle (Bu fonksiyonu ChatMessage scriptinde yazmıştık)
	new_message.setup(text, is_user)
	
	# 4. Scroll'u otomatik aşağı kaydır
	_scroll_to_bottom()

func _scroll_to_bottom():
	# Mesajın eklenmesi için bir kare beklememiz gerekir
	await get_tree().process_frame
	chat_scroll.scroll_vertical = chat_scroll.get_v_scroll_bar().max_value

# SendButton'ın 'pressed' sinyalini buraya bağla
func _on_send_button_pressed():
	# .strip_edges() ekleyerek sadece boşluk gönderilmesini engelliyoruz
	var input_node = $MainWindow/InputField
	var user_text = input_node.text.strip_edges() 
	
	if user_text != "":
		# 1. Kullanıcı mesajını ekrana bas
		add_message_to_chat(user_text, true)
		
		# 2. Yazı alanını temizle
		input_node.clear()
		
		# 3. Giriş kutusuna tekrar odaklan (Mobilde/PC'de kolaylık sağlar)
		input_node.grab_focus()
		
		# 4. Yapay zekadan cevap bekleme simülasyonu
		_fake_ai_response()

func _fake_ai_response():
	await get_tree().create_timer(1.0).timeout # 1 saniye düşünme payı
	add_message_to_chat("Harika! Sana bu konuda yardımcı olabilirim.", false)


func _on_input_field_text_submitted(new_text: String) -> void:
   # Enter'a basıldığında buton tıklanmış gibi davran
	_on_send_button_pressed()


func _on_close_button_pressed() -> void:
	visible = false # Paneli gizler
