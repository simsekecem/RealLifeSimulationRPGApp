extends Node


func _ready():

	if not Globals.is_initial_sync_done:
		print("🔄 [TOWN] Data not ready yet, triggering synchronization...")
		Globals.load_from_server()
	else:
		print("✅ [TOWN] Data already synchronized. Scene initialized cleanly.")
