extends Label

func _ready():
	# Label'ı tıklanabilir yapar
	mouse_filter = Control.MOUSE_FILTER_STOP
	

func _gui_input(event):
	# Sol tıklama algılandığında forgot password sahnesine gider
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("Forgot Password clicked!")  # test için
		get_tree().change_scene_to_file("res://scenes/authscreen_forgotps.tscn")
