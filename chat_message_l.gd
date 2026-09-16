extends HBoxContainer

# Access nodes in the prefab
@onready var label = $BubblePanel/PanelContainer/MessageLabel
@onready var bubble = $BubblePanel

func setup(content: String, is_user: bool):
	# Set message text
	$BubblePanel/PanelContainer/MessageLabel.text = content
	
	# Adjust layout based on sender (user or AI)
	if is_user:
		# Align user message to the RIGHT
		layout_direction = Control.LAYOUT_DIRECTION_RTL
		
		bubble.modulate = Color("b0a7d2") 
	else:
		# Align AI message to the LEFT
		layout_direction = Control.LAYOUT_DIRECTION_LTR
		bubble.modulate = Color("#9966CC") # Lavender/standard
