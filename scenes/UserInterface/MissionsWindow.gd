extends Control

@export var mission_row_scene: PackedScene = preload("res://scenes/prefabs/MissionRow.tscn")
@onready var missions_list = $ScrollContainer/MissionsPanel

func _ready():
	# Örnek 10 mission
	var example_missions = [
		{"name":"Mission 1", "detail":"Detail for mission 1"},
		{"name":"Mission 2", "detail":"Detail for mission 2"},
		{"name":"Mission 3", "detail":"Detail for mission 3"},
		{"name":"Mission 4", "detail":"Detail for mission 4"},
		{"name":"Mission 5", "detail":"Detail for mission 5"},
		{"name":"Mission 6", "detail":"Detail for mission 6"},
		{"name":"Mission 7", "detail":"Detail for mission 7"},
		{"name":"Mission 8", "detail":"Detail for mission 8"},
		{"name":"Mission 9", "detail":"Detail for mission 9"},
		{"name":"Mission 10", "detail":"Detail for missiondsfsdfdsfdsffffffdkjsakjjKDKJLASJLFKJSDKLFKJSDJGKSKJLDFKJFSJGKSDKJFDSFKJUEIKJSDFK SFOJSAKJD SJDFJKDSJKF SDJFJDSKKJF SDKJFKJDSF ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff 10"}
	]
	load_missions(example_missions)

func load_missions(missions: Array):
	# Önce eski missionları temizle
	for child in missions_list.get_children():
		child.queue_free()

	for mission in missions:
		var row = mission_row_scene.instantiate()
		row.get_node("MissionList/MissionName").text = mission.name
		row.get_node("MissionList/MissionDetail").text = mission.detail
		missions_list.add_child(row)
