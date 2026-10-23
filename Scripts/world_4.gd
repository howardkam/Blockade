class_name World4
extends BaseWorld

func _init() -> void:
	next_level_scene = "res://Scenes/world_5.tscn"
	initial_powerup_count = 6
	initial_bomb_count = 6
	initial_trident_count = 6
	total_batches = 50
	diamonds_per_batch = 120
	pluses_per_batch = 14
	gigantor_spawn_chance = 0.2
	target_score = 7000
