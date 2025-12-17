extends HBoxContainer

# Prefab içindeki düğümlere ulaşalım
@onready var label = $BubblePanel/MessageLabel
@onready var bubble = $BubblePanel

func setup(content: String, is_user: bool):
	# Mesaj metnini ayarla
	$BubblePanel/MessageLabel.text = content
	
	# Kullanıcı mı yoksa AI mı olduğuna göre tasarımı değiştir
	if is_user:
		# Kullanıcı mesajını SAĞA yasla
		layout_direction = Control.LAYOUT_DIRECTION_RTL
		# Senin UI stilindeki pembe tonu
		bubble.modulate = Color("ffcacc") 
	else:
		# AI mesajını SOLA yasla
		layout_direction = Control.LAYOUT_DIRECTION_LTR
		bubble.modulate = Color("ffffff") # Beyaz/Standart
