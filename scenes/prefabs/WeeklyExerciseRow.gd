extends VBoxContainer
class_name WeeklyExerciseRow

@onready var label_name = $ExerciseName
@onready var label_duration = $Duration

# Veriyi ve Rengi ayarla
func setup_row(ex_name: String, duration: String, is_completed: bool, is_past_date: bool):
	label_name.text = ex_name
	label_duration.text = duration
	
	# RENK MANTIĞI:
	if is_completed:
		modulate = Color(0.2, 0.9, 0.2) # Yeşil (Yapıldı)
	elif is_past_date:
		modulate = Color(0.9, 0.2, 0.2) # Kırmızı (Tarihi geçti ve yapılmadı)
	else:
		modulate = Color.WHITE # Beyaz (Bugün veya Gelecek)
