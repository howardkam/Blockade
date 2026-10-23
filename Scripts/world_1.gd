class_name World1
extends BaseWorld

func _init() -> void:
	next_level_scene = "res://Scenes/world_2.tscn"
	initial_powerup_count = 3
	initial_bomb_count = 2
	initial_trident_count = 3
	total_batches = 20
	diamonds_per_batch = 50
	pluses_per_batch = 8
	gigantor_spawn_chance = 0.2
	target_score = 4000
