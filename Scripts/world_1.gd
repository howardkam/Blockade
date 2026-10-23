extends Node2D

@export_group("Level Transition")
@export_file("*.tscn") var next_level_scene: String = "res://Scenes/world_2.tscn"

@export_group("Player Reference")
@export var player: CharacterBody2D

@export_group("Powerup Settings")
@export var powerup_launcher_scene: PackedScene = preload("res://Scenes/powerup_launcher.tscn")
@export var initial_powerup_count: int = 3
@export var bomb_scene: PackedScene = preload("res://Scenes/omb.tscn")
@export var initial_bomb_count: int = 2
@export var trident_scene: PackedScene = preload("res://Scenes/powerup_trident.tscn")
@export var initial_trident_count: int = 3

@export_group("Enemy Scenes")
@export var enemy_diamond: PackedScene = preload("res://Scenes/enemy_diamond.tscn")
@export var enemy_plus: PackedScene = preload("res://Scenes/enemy_plus.tscn")
@export var enemy_gigantor: PackedScene = preload("res://Scenes/enemy_gigantor.tscn")

@onready var explosionsound = $AudioStreamPlayer2D
@onready var level_cleared_label: Label = $WinUI/LevelClearedLabel
@onready var level_intro_label: Label = $WinUI/LevelIntroLabel

@export_group("Intro Settings")
@export var intro_display_time: float = 2.0

@export_group("Batch Controls")
@export var total_batches: int = 20      # Total number of batches to release
@export var batch_interval: float = 15.0      # Delay in seconds between each batch release
@export var diamonds_per_batch: int = 50    
@export var pluses_per_batch: int = 8    
@export var gigantor_spawn_chance = 0.2 # 0.20 equals 20 percent chance   

@export_group("Win Condition")
@export var target_score: int = 4000

@export_group("Spawn Settings")
@export var safe_radius: float = 1000.0
@export var min_enemy_distance: float = 40.0
@export var spawn_area_min: Vector2 = Vector2(-3000, -3000)
@export var spawn_area_max: Vector2 = Vector2(3000, 3000)

var spawned_positions: Array[Vector2] = []
var batches_spawned: int = 0
var batch_timer: Timer = null
var level_completed: bool = false
var powerup_max_distance = 2000

func _ready():
	# Register active level path in Global
	if get_node_or_null("/root/Global"):
		var current_path = scene_file_path if scene_file_path != "" else "res://Scenes/world_1.tscn"
		Global.current_level_path = current_path

	# Display intro sequence before spawning gameplay elements
	await show_level_intro()

	spawn_initial_powerups()
	spawn_initial_bombs()
	spawn_initial_tridents()

	# Set up repeating timer for batches
	batch_timer = Timer.new()
	batch_timer.wait_time = batch_interval
	batch_timer.autostart = true
	batch_timer.timeout.connect(_on_batch_timer_timeout)
	add_child(batch_timer)
	
	# Spawn Batch #1 immediately after intro finishes
	spawn_batch()

func show_level_intro() -> void:
	if level_intro_label:
		level_intro_label.show()
		await get_tree().create_timer(intro_display_time).timeout
		
		# Fade out label smoothly
		var tween = create_tween()
		tween.tween_property(level_intro_label, "modulate:a", 0.0, 0.5)
		await tween.finished
		level_intro_label.hide()

func spawn_initial_powerups():
	if not powerup_launcher_scene or initial_powerup_count <= 0:
		return

	# Retrieve the active player reference
	var target_player = player if player else get_tree().get_first_node_in_group("player")
	var player_pos = target_player.global_position if target_player else Vector2.ZERO

	for i in range(initial_powerup_count):
		# Pick a random angle (0 to 360 degrees)
		var angle = randf() * TAU
		
		# Pick a random distance between safe_radius and powerup_max_distance
		var distance = randf_range(safe_radius, powerup_max_distance)
		
		# Calculate spawn position relative to player
		var spawn_pos = player_pos + Vector2(cos(angle), sin(angle)) * distance

		# Clamp position to stay within world bounds
		spawn_pos.x = clamp(spawn_pos.x, spawn_area_min.x, spawn_area_max.x)
		spawn_pos.y = clamp(spawn_pos.y, spawn_area_min.y, spawn_area_max.y)

		# Instantiate powerup
		var powerup = powerup_launcher_scene.instantiate()
		powerup.global_position = spawn_pos
		add_child(powerup)

func spawn_initial_bombs():
	if not bomb_scene or initial_bomb_count <= 0:
		return

	var target_player = player if player else get_tree().get_first_node_in_group("player")
	var player_pos = target_player.global_position if target_player else Vector2.ZERO

	for i in range(initial_bomb_count):
		var angle = randf() * TAU
		var distance = randf_range(safe_radius, powerup_max_distance)
		
		var spawn_pos = player_pos + Vector2(cos(angle), sin(angle)) * distance
		spawn_pos.x = clamp(spawn_pos.x, spawn_area_min.x, spawn_area_max.x)
		spawn_pos.y = clamp(spawn_pos.y, spawn_area_min.y, spawn_area_max.y)

		var bomb = bomb_scene.instantiate()
		bomb.global_position = spawn_pos
		add_child(bomb)

func spawn_initial_tridents():
	if not trident_scene or initial_trident_count <= 0:
		return

	var target_player = player if player else get_tree().get_first_node_in_group("player")
	var player_pos = target_player.global_position if target_player else Vector2.ZERO

	for i in range(initial_trident_count):
		var angle = randf() * TAU
		var distance = randf_range(safe_radius, powerup_max_distance)
		
		var spawn_pos = player_pos + Vector2(cos(angle), sin(angle)) * distance
		spawn_pos.x = clamp(spawn_pos.x, spawn_area_min.x, spawn_area_max.x)
		spawn_pos.y = clamp(spawn_pos.y, spawn_area_min.y, spawn_area_max.y)

		var trident = trident_scene.instantiate()
		trident.global_position = spawn_pos
		add_child(trident)
func _process(_delta):
	check_win_condition()

func _on_batch_timer_timeout():
	if batches_spawned < total_batches:
		spawn_batch()
	else:
		batch_timer.stop()

func spawn_batch():
	batches_spawned += 1
	
	var target_player = player if player else get_tree().get_first_node_in_group("player")
	var player_pos = target_player.global_position if target_player else Vector2.ZERO

	if enemy_diamond and diamonds_per_batch > 0:
		spawn_enemy_type(enemy_diamond, diamonds_per_batch, player_pos)

	if enemy_plus and pluses_per_batch > 0:
		spawn_enemy_type(enemy_plus, pluses_per_batch, player_pos)
		
	if enemy_gigantor and randf() < gigantor_spawn_chance:
		spawn_enemy_type(enemy_gigantor, 1, player_pos)

func spawn_enemy_type(scene: PackedScene, amount: int, player_pos: Vector2):
	for i in range(amount):
		var angle = randf() * TAU
		var distance = randf_range(safe_radius, safe_radius + 1200.0)
		var random_pos = player_pos + Vector2(cos(angle), sin(angle)) * distance

		random_pos.x = clamp(random_pos.x, spawn_area_min.x, spawn_area_max.x)
		random_pos.y = clamp(random_pos.y, spawn_area_min.y, spawn_area_max.y)

		var enemy = scene.instantiate()
		enemy.global_position = random_pos
		add_child(enemy)

func check_win_condition():
	if level_completed:
		return

	var target_player = player if player else get_tree().get_first_node_in_group("player")
	if target_player and "score" in target_player:
		if target_player.score >= target_score:
			complete_level()

func complete_level():
	level_completed = true
	
	# Reveal centered victory label
	if level_cleared_label:
		level_cleared_label.show()
	
	# Pause gameplay mechanics (music remains active via process_mode = 3)
	get_tree().paused = true
	
	# Wait 3 seconds during pause
	await get_tree().create_timer(3.0, true, false, true).timeout
	
	# Resume pause state prior to scene change
	get_tree().paused = false
	
	# Transition to next configured level
	if get_node_or_null("/root/Global"):
		Global.go_to_level(next_level_scene)
	else:
		SceneManager.change_scene(next_level_scene, {
			"pattern": "squares",
			"time": 1.0
		})
