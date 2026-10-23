extends Node

var music_player: AudioStreamPlayer
var tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player = AudioStreamPlayer.new()
	add_child(music_player)

func play_music(stream: AudioStream, fade_in_duration: float = 0.0) -> void:
	if music_player.stream == stream and music_player.playing:
		return

	if tween and tween.is_running():
		tween.kill()

	music_player.stream = stream
	music_player.volume_db = 0.0
	
	if fade_in_duration > 0.0:
		music_player.volume_db = -80.0
		music_player.play()
		tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(music_player, "volume_db", 0.0, fade_in_duration)
	else:
		music_player.play()

func fade_out_music(duration: float = 1.5) -> void:
	if not music_player.playing:
		return

	if tween and tween.is_running():
		tween.kill()

	tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(music_player, "volume_db", -80.0, duration)
	tween.tween_callback(stop_music)

func stop_music() -> void:
	music_player.stop()
	music_player.volume_db = 0.0