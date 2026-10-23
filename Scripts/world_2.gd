class_name World2
extends BaseWorld

func _init() -> void:
	next_level_scene = "res://Scenes/world_3.tscn"
	initial_powerup_count = 4
	initial_bomb_count = 3
	initial_trident_count = 4
	total_batches = 30
	diamonds_per_batch = 75
	pluses_per_batch = 10
	gigantor_spawn_chance = 0.1
	target_score = 5000
