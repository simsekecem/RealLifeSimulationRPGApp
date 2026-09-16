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
		# Pink tint matching UI style
		bubble.modulate = Color("f9c7d4") 
	else:
		# Align AI message to the LEFT
		layout_direction = Control.LAYOUT_DIRECTION_LTR
		bubble.modulate = Color("ffffff") # White / default
