extends Control

@onready var back_button = $Back_Button

@onready var day_buttons := {
	"Monday": $M_Button,
	"Tuesday": $TU_Button,
	"Wednesday": $W_Button,
	"Thursday": $T_Button,
	"Friday": $F_Button,
	"Saturday": $SA_Button,
	"Sunday": $S_Button
}


@onready var day_panels := {
	"Monday": $DaysContent/MondayPanel,
	"Tuesday": $DaysContent/TuesdayPanel,
	"Wednesday": $DaysContent/WednesdayPanel,
	"Thursday": $DaysContent/ThursdayPanel,
	"Friday": $DaysContent/FridayPanel,
	"Saturday": $DaysContent/SaturdayPanel,
	"Sunday": $DaysContent/SundayPanel
}

# Açık olan gün
var current_day: String = ""


func _ready():
	UI.get_node("UIRoot").show_only_top_right_buttons()
	back_button.pressed.connect(_on_back_button_pressed)

	
	for p in day_panels.values():
		if p != null:
			p.visible = false

	
	for day in day_buttons.keys():
		var btn: Button = day_buttons[day]
		btn.toggle_mode = true
		btn.toggled.connect(_on_day_toggled.bind(day))




func _on_day_toggled(pressed: bool, day: String):

	var panel = day_panels[day]

	
	if panel == null:
		print("HATA → Panel bulunamadı:", day)
		return

	if pressed:

		# Başka bir gün açıksa önce onu kapat
		if current_day != "" and current_day != day:
			var old_btn = day_buttons[current_day]
			var old_panel = day_panels[current_day]

			if old_btn:
				old_btn.button_pressed = false
			if old_panel:
				old_panel.visible = false

		
		panel.visible = true
		current_day = day

	else:
		
		if current_day == day:
			panel.visible = false
			current_day = ""

func _on_back_button_pressed():
	UI.get_node("UIRoot").change_scene_to("res://town.tscn")
