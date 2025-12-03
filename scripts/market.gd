# market_main.gd
extends Control

@onready var btn_g = $VBoxContainer2/G_Button
@onready var btn_hg = $VBoxContainer2/HG_Button
@onready var btn_c = $VBoxContainer2/C_Button
@onready var btn_pc = $VBoxContainer2/PC_Button
@onready var btn_he = $VBoxContainer2/HE_Button
@onready var back_button = $Back_Button

@onready var panel: Panel = $Panel   # panel node adı "Panel"

func _ready():
	UI.get_node("UIRoot").show_only_top_right_buttons()
	back_button.pressed.connect(_on_back_button_pressed)
	# Bütün butonları reset-panel fonksiyonuna bağla
	btn_g.pressed.connect(_on_button_pressed)
	btn_hg.pressed.connect(_on_button_pressed)
	btn_c.pressed.connect(_on_button_pressed)
	btn_pc.pressed.connect(_on_button_pressed)
	btn_he.pressed.connect(_on_button_pressed)

	# opsiyonel: panelde CloseButton varsa kapatma
	if panel.has_node("CloseButton"):
		panel.get_node("CloseButton").pressed.connect(_on_close_panel)


func _on_button_pressed() -> void:
	
	var items_vbox_path = "ItemsScroll/ItemsVBox"
	if panel.has_node(items_vbox_path):
		var vbox = panel.get_node(items_vbox_path)
		
		for child in vbox.get_children():
			child.queue_free()
	
	if panel.has_method("add_item"):
		panel.call("add_item", true)
	
	
	panel.visible = true

func _on_close_panel() -> void:
	panel.visible = false

func _on_back_button_pressed():

	UI.get_node("UIRoot").change_scene_to("res://town.tscn")
	UI.get_node("UIRoot").show_full_ui()
