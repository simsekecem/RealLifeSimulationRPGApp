extends Control

# --- Gün Butonları ---
@onready var day_buttons := {
	"Monday": $M_Button,
	"Tuesday": $TU_Button,
	"Wednesday": $W_Button,
	"Thursday": $T_Button,
	"Friday": $F_Button,
	"Saturday": $SA_Button,
	"Sunday": $S_Button
}

# --- Gün Panelleri ---
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

	# --- 1) Başlangıçta tüm paneller kapalı ---
	for p in day_panels.values():
		if p != null:
			p.visible = false

	# --- 2) Tüm butonlara toggle sinyali bağlanıyor ---
	for day in day_buttons.keys():
		var btn: Button = day_buttons[day]
		btn.toggle_mode = true
		btn.toggled.connect(_on_day_toggled.bind(day))



# --- T O G G L E   F O N K S İ Y O N U ---
func _on_day_toggled(pressed: bool, day: String):

	var panel = day_panels[day]

	# Eğer panel bulunamazsa hata vermesin
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

		# Yeni günü aç
		panel.visible = true
		current_day = day

	else:
		# Aynı butona tekrar basılırsa kapat
		if current_day == day:
			panel.visible = false
			current_day = ""
