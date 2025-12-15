extends HBoxContainer

signal request_new_item

@onready var name_field: LineEdit = $ItemEdit
@onready var checkbox: CheckBox = $ItemCheck

var current_category: String = ""
var item_id = null 

func _ready():
	name_field.connect("text_submitted", Callable(self, "_on_submit"))
	checkbox.connect("toggled", Callable(self, "_on_check_toggled"))
	_update_visuals(checkbox.button_pressed)

func _on_submit(_text: String) -> void:
	emit_signal("request_new_item")

func _on_check_toggled(checked: bool) -> void:
	_update_visuals(checked)

func _update_visuals(checked: bool):
	var color = Color("#496580") if checked else Color.WHITE
	name_field.set("theme_override_colors/font_color", color)

# --- SAVE & LOAD ---

func set_data(data: Dictionary):
	# DEBUG: Veri yüklenirken ne geliyor görelim
	# print("🔍 ROW SET_DATA ÇAĞRILDI: ", data) 
	
	if data.has("item_name"):
		name_field.text = str(data["item_name"])
	
	if data.has("category"):
		current_category = data["category"]
		
	# ID KONTROLÜ
	if data.has("id"):
		item_id = data["id"]
		# print("✅ ROW: ID Hafızaya alındı -> ", item_id)
	else:
		item_id = null
		# print("⚠️ ROW: Bu veride ID yok (Yeni satır olabilir)")
	
	var is_bought = int(data.get("bought", 0)) == 1
	checkbox.button_pressed = is_bought
	_update_visuals(is_bought)

func get_data() -> Dictionary:
	var is_bought = 1 if checkbox.button_pressed else 0
	var is_planned = 0 if checkbox.button_pressed else 1
	var clean_name = name_field.text.strip_edges()
	
	var data = {
		"category": current_category,
		"item_name": clean_name,
		"bought": is_bought,
		"planned": is_planned,
		"date": Time.get_date_string_from_system() 
	}
	
	if item_id != null:
		data["id"] = item_id
		print("📤 ROW GET_DATA: ID ile dönüyor (%s) -> %s" % [item_id, clean_name])
	else:
		print("📤 ROW GET_DATA: ID SİZ dönüyor -> %s" % [clean_name])
		
	return data
