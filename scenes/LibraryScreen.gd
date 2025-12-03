extends Control

@export var hour_row_scene: PackedScene = preload("res://scenes/prefabs/StudyHoursRow.tscn")

# Gün butonları listesi (Tüm butonlarınızı buraya eklemelisiniz)
@onready var day_buttons = [
	$DaysPanel/MondayButton,
	$DaysPanel/TuesdayButton,
	$DaysPanel/WednesdayButton,
	$DaysPanel/ThursdayButton,
	$DaysPanel/FridayButton,
	$DaysPanel/SaturdayButton,
	$DaysPanel/SundayButton
]

@onready var hours_list = $HoursPanel/ScrollContainer/HoursList
@onready var back_button = $BackButton

# Halihazırda seçili olan butonu takip etmek için bir değişken
var current_selected_button: Button = null

func _ready():
	back_button.pressed.connect(_on_back_button_pressed)
	UI.get_node("UIRoot").show_only_top_right_buttons()
	# Tüm gün butonlarını döngüye al ve sinyalleri bağla
	for button in day_buttons:
		# ÖNEMLİ: Butonun Godot Editor'da "Toggle Mode"unun açık olduğundan emin olun.
		# Toggled sinyalini _on_day_button_toggled fonksiyonuna bağla ve butonu parametre olarak gönder.
		button.toggled.connect(_on_day_button_toggled.bind(button))

# Tüm gün butonlarının toggle olayını işleyen tek fonksiyon
func _on_day_button_toggled(pressed: bool, clicked_button: Button):
	
	if pressed:
		# --- Kural 2: Yeni bir butona tıklandı ---
		
		# Eğer daha önce seçili bir buton varsa ve bu, yeni tıklanan buton değilse,
		# eski butonu kapat (Toggle Off).
		if current_selected_button != null and current_selected_button != clicked_button:
			current_selected_button.button_pressed = false
			# clear_hours'ı çağırmaya gerek yok, çünkü load_hours_for_day bunu zaten yapıyor.
		
		# Yeni seçilen butonu kaydet
		current_selected_button = clicked_button
		
		# Saatleri yükle
		load_hours_for_day(clicked_button.name)
		
	else:
		# --- Kural 1: Aynı butona tekrar tıklandı ve kapandı ---
		
		# Buton kapandığına göre, seçili butonu sıfırla.
		if clicked_button == current_selected_button:
			current_selected_button = null
		
		# Saat listesini temizle
		clear_hours()

# --- Diğer Fonksiyonlar ---

func load_hours_for_day(_day: String):
	# Yeni saatleri yüklemeden önce her zaman temizle
	clear_hours() 

	var start_hour = 9
	var end_hour = 24

	for h in range(start_hour, end_hour):
		var row = hour_row_scene.instantiate()
		var label = row.get_node("HBoxContainer/HourLabel")
		var textedit = row.get_node("HBoxContainer/TaskTextEdit")
		label.text = "\n %02d:00 - %02d:00" % [h, h+1]
		textedit.text = ""
		hours_list.add_child(row)


func clear_hours():
	for child in hours_list.get_children():
		child.queue_free()
		
func _on_back_button_pressed():
	# Global UI Autoload'u kullanarak sahne değiştirme fonksiyonunu çağırın.
	# Buraya Kasaba sahnesinin dosya yolunu yazın:
	UI.get_node("UIRoot").change_scene_to("res://town.tscn")
