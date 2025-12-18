extends HBoxContainer

# Prefab içindeki düğümlere ulaşalım
@onready var label = $BubblePanel/PanelContainer/MessageLabel
@onready var bubble = $BubblePanel

func setup(content: String, is_user: bool):
	# Mesaj metnini ayarla
	$BubblePanel/PanelContainer/MessageLabel.text = content
	
	# Kullanıcı mı yoksa AI mı olduğuna göre tasarımı değiştir
	if is_user:
		# Kullanıcı mesajını SAĞA yasla
		layout_direction = Control.LAYOUT_DIRECTION_RTL
		
		bubble.modulate = Color("b0a7d2") 
	else:
		# AI mesajını SOLA yasla
		layout_direction = Control.LAYOUT_DIRECTION_LTR
		bubble.modulate = Color("ffffff") # Beyaz/Standart
