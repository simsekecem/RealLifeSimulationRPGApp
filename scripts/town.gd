extends Node


func _ready():

	if not Globals.is_initial_sync_done:
		print("🔄 [TOWN] Veriler henüz hazır değil, senkronizasyon tetikleniyor...")
		Globals.load_from_server()
	else:
		print("✅ [TOWN] Veriler zaten hazır. Sahne temiz şekilde başlatıldı.")
