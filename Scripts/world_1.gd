class_name World5
extends BaseWorld

func _init() -> void:
	next_level_scene = "res://Scenes/world_2.tscn"
	initial_powerup_count = 3
	initial_bomb_count = 1
	initial_trident_count = 3
	total_batches = 60
	diamonds_per_batch = 50
	pluses_per_batch = 5
	gigantor_spawn_chance = 0.3
	target_score = 4000
