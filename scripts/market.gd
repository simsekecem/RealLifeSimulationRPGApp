extends Control

@onready var btn_g = $VBoxContainer2/G_Button
@onready var btn_hg = $VBoxContainer2/HG_Button
@onready var btn_c = $VBoxContainer2/C_Button
@onready var btn_pc = $VBoxContainer2/PC_Button
@onready var btn_he = $VBoxContainer2/HE_Button
@onready var back_button = $Back_Button

# Access to panel script
@onready var panel: Panel = $Panel

# Current active category
var current_category_name = ""

func _ready():
	UI.get_node("UIRoot").show_only_top_right_buttons()
	
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Connect buttons to categories
	btn_g.pressed.connect(func(): _switch_category("Groceries"))
	btn_hg.pressed.connect(func(): _switch_category("Home Goods"))
	btn_c.pressed.connect(func(): _switch_category("Clothing"))
	btn_pc.pressed.connect(func(): _switch_category("Personal Care"))
	btn_he.pressed.connect(func(): _switch_category("Household Essentials"))

	# Hide panel initially
	panel.visible = false
	
	# Listen to Globals signal (refresh list if data updates)
	if Globals.has_signal("data_updated"):
		if not Globals.data_updated.is_connected(_on_global_data_updated):
			Globals.data_updated.connect(_on_global_data_updated)

func _switch_category(cat_name: String):
	# Save previous category (if panel is visible)
	if panel.visible and current_category_name != "":
		panel.save_items_to_cache()
		Globals.mark_dirty()
		# Trigger quest action if data was saved when switching categories
		if has_node("/root/QuestManager"):
			QuestManager.trigger_action("market_add")
			QuestManager.trigger_action("first_market")
	current_category_name = cat_name
	panel.visible = true
	
	print("🛒 Category opened: ", cat_name)
	
	# Call load function in panel script
	panel.load_category(cat_name)
	
func _on_back_button_pressed():
	# Save on exit
	if panel.visible and current_category_name != "":
		panel.save_items_to_cache()
		Globals.mark_dirty()
		if has_node("/root/QuestManager"):
			QuestManager.trigger_action("market_add")
			QuestManager.trigger_action("first_market")		
	if UI.has_node("UIRoot"): UI.get_node("UIRoot").return_to_town()

func _on_global_data_updated():
	# If panel is visible, reload the current category
	if panel.visible and current_category_name != "":
		print("🔄 Market: Data updated, refreshing list...")
		panel.load_category(current_category_name)
