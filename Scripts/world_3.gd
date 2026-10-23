class_name World3
extends BaseWorld

func _init() -> void:
	next_level_scene = "res://Scenes/world_4.tscn"
	initial_powerup_count = 5
	initial_bomb_count = 4
	initial_trident_count = 5
	total_batches = 40
	diamonds_per_batch = 100
	pluses_per_batch = 12
	gigantor_spawn_chance = 0.2
	target_score = 6000
