class_name World5
extends BaseWorld

func _init() -> void:
	next_level_scene = "res://Scenes/world_1.tscn"
	initial_powerup_count = 6
	initial_bomb_count = 6
	initial_trident_count = 6
	total_batches = 60
	diamonds_per_batch = 120
	pluses_per_batch = 15
	gigantor_spawn_chance = 0.3
	target_score = 4000
