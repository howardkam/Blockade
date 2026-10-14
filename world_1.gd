extends Node2D

@export_group("Enemy Scenes")
@export var enemy_diamond: PackedScene = preload("res://enemy_diamond.tscn")
@export var enemy_plus: PackedScene = preload("res://enemy_plus.tscn")

@export_group("Batch Controls")
@export var total_batches: int = 10           # Total number of batches to release
@export var batch_interval: float = 12.0      # Delay in seconds between each batch release
@export var diamonds_per_batch: int = 100     # How many Diamonds spawn at once each batch
@export var pluses_per_batch: int = 10       # How many Pluses spawn at once each batch

@export_group("Win Condition")
@export var target_score: int = 1000

@export_group("Spawn Settings")
@export var safe_radius: float = 800.0
@export var min_enemy_distance: float = 40.0
@export var spawn_area_min: Vector2 = Vector2(-3000, -3000)
@export var spawn_area_max: Vector2 = Vector2(3000, 3000)

var spawned_positions: Array[Vector2] = []
var batches_spawned: int = 0
var batch_timer: Timer = null
var level_completed: bool = false

func _ready():
	# Set up repeating timer for batches
	batch_timer = Timer.new()
	batch_timer.wait_time = batch_interval
	batch_timer.autostart = true
	batch_timer.timeout.connect(_on_batch_timer_timeout)
	add_child(batch_timer)
	
	# Spawn Batch #1 immediately upon level start
	spawn_batch()

func _process(_delta):
	check_win_condition()

func _on_batch_timer_timeout():
	if batches_spawned < total_batches:
		spawn_batch()
	else:
		batch_timer.stop()

func spawn_batch():
	batches_spawned += 1
	
	var player = get_tree().get_first_node_in_group("player")
	var player_pos = player.global_position if player else Vector2.ZERO

	# Spawn exact counts for this batch
	if enemy_diamond and diamonds_per_batch > 0:
		spawn_enemy_type(enemy_diamond, diamonds_per_batch, player_pos)

	if enemy_plus and pluses_per_batch > 0:
		spawn_enemy_type(enemy_plus, pluses_per_batch, player_pos)

func spawn_enemy_type(scene: PackedScene, amount: int, player_pos: Vector2):
	for i in range(amount):
		var angle = randf() * TAU
		var distance = randf_range(safe_radius, safe_radius + 1200.0)
		var random_pos = player_pos + Vector2(cos(angle), sin(angle)) * distance

		# Keep within world boundaries
		random_pos.x = clamp(random_pos.x, spawn_area_min.x, spawn_area_max.x)
		random_pos.y = clamp(random_pos.y, spawn_area_min.y, spawn_area_max.y)

		var enemy = scene.instantiate()
		enemy.global_position = random_pos
		add_child(enemy)

func check_win_condition():
	if level_completed:
		return

	var player = get_tree().get_first_node_in_group("player")
	if player and "score" in player:
		if player.score >= target_score:
			complete_level()

func complete_level():
	level_completed = true
	print("LEVEL COMPLETE! Target score of ", target_score, " reached.")
