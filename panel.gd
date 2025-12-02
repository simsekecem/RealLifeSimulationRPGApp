extends Panel

const ROW_SCENE := preload("res://scenes/prefabs/item.tscn")

@onready var scroll: ScrollContainer = $ItemsScroll
@onready var vbox: VBoxContainer = $ItemsScroll/ItemsVBox

func _ready():
	add_item() 

func add_item(focus: bool = true) -> Node:
	var row = ROW_SCENE.instantiate()
	row.connect("request_new_item", Callable(self, "_on_row_request_new_item"))
	vbox.add_child(row)

	
	_call_scroll_bottom()

	
	if focus:
		var le = row.get_node("ItemEdit")
		_focus_lineedit(le)

	return row

func _on_row_request_new_item():
	add_item(true)

func _call_scroll_bottom() -> void:
	await get_tree().process_frame
	scroll.scroll_vertical = INF

func _focus_lineedit(le: LineEdit) -> void:
	await get_tree().process_frame
	if is_instance_valid(le):
		le.grab_focus()
