extends Label

func _ready():
	
	mouse_filter = Control.MOUSE_FILTER_STOP
	

func _gui_input(event):
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("Forgot Password clicked!")  # test için
		get_tree().change_scene_to_file("res://authscreen_forgotps.tscn")
