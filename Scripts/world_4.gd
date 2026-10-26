class_name World4
extends BaseWorld

func _init() -> void:
	next_level_scene = "res://Scenes/world_2.tscn"
	initial_powerup_count = 4
	initial_bomb_count = 3
	initial_trident_count = 4
	total_batches = 30
	diamonds_per_batch = 50
	pluses_per_batch = 6
	gigantor_spawn_chance = 0.1
	target_score = 4000
