extends Node2D

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

func bgm_play():
	audio_stream_player.stream = preload("res://assets/bgmusic/Blithe part B.ogg")
	audio_stream_player.play()
	
