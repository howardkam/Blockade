class_name BaseWorld
extends Node2D

@export_group("Level Transition")
@export_file("*.tscn") var next_level_scene: String = ""

@export_group("Player Reference")
@export var player: CharacterBody2D

@export_group("Powerup Settings")
@export var powerup_launcher_scene: PackedScene = preload("res://Scenes/powerup_launcher.tscn")
@export var initial_powerup_count: int = 3
@export var bomb_scene: PackedScene = preload("res://Scenes/bomb.tscn")
@export var initial_bomb_count: int = 2
@export var trident_scene: PackedScene = preload("res://Scenes/powerup_trident.tscn")
@export var initial_trident_count: int = 3
@export var powerup_max_distance: float = 2000.0

@export_group("Enemy Scenes")
@export var enemy_diamond: PackedScene = preload("res://Scenes/enemy_diamond.tscn")
@export var enemy_plus: PackedScene = preload("res://Scenes/enemy_plus.tscn")
@export var enemy_gigantor: PackedScene = preload("res://Scenes/enemy_gigantor.tscn")

@export_group("Intro Settings")
@export var intro_display_time: float = 2.0

@export_group("Batch Controls")
@export var total_batches: int = 20
@export var batch_interval: float = 15.0
@export var diamonds_per_batch: int = 50
@export var pluses_per_batch: int = 8
@export var gigantor_spawn_chance: float = 0.2

@export_group("Win Condition")
@export var target_score: int = 4000

@export_group("Spawn Settings")
@export var safe_radius: float = 1000.0
@export var spawn_area_min: Vector2 = Vector2(-3000, -3000)
@export var spawn_area_max: Vector2 = Vector2(3000, 3000)

@onready var level_cleared_label: Label = $WinUI/LevelClearedLabel if has_node("WinUI/LevelClearedLabel") else null
@onready var level_intro_label: Label = $WinUI/LevelIntroLabel if has_node("WinUI/LevelIntroLabel") else null
@onready var level_goal_label: Label = $WinUI/LevelGoalLabel if has_node("WinUI/LevelGoalLabel") else null
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D if has_node("AudioStreamPlayer2D") else null

var batches_spawned: int = 0
var batch_timer: Timer = null
var level_completed: bool = false
var cached_player: CharacterBody2D = null

func _ready() -> void:
	# Fade out menu/title music if a global MusicManager exists
	if get_node_or_null("/root/MusicManager"):
		MusicManager.fade_out_music(1.5)

	# Ensure local world music plays at full volume if audio_player exists
	if audio_player:
		audio_player.volume_db = 5.0
		if not audio_player.playing:
			audio_player.play()

	cached_player = player if player else get_tree().get_first_node_in_group("player") as CharacterBody2D

	if get_node_or_null("/root/Global"):
		var current_path = scene_file_path if scene_file_path != "" else "res://Scenes/world_1.tscn"
		Global.current_level_path = current_path

	await show_level_intro()

	spawn_initial_items(powerup_launcher_scene, initial_powerup_count)
	spawn_initial_items(bomb_scene, initial_bomb_count)
	spawn_initial_items(trident_scene, initial_trident_count)

	batch_timer = Timer.new()
	batch_timer.wait_time = batch_interval
	batch_timer.autostart = true
	batch_timer.timeout.connect(_on_batch_timer_timeout)
	add_child(batch_timer)

	spawn_batch()

func _process(_delta: float) -> void:
	check_win_condition()

func show_level_intro() -> void:
	if level_goal_label:
		level_goal_label.text = "Goal: %d points" % target_score
		level_goal_label.modulate.a = 1.0
		level_goal_label.show()

	if level_intro_label:
		level_intro_label.modulate.a = 1.0
		level_intro_label.show()

		await get_tree().create_timer(intro_display_time, false).timeout

		var tween = create_tween().set_parallel(true)
		tween.tween_property(level_intro_label, "modulate:a", 0.0, 0.5)
		if level_goal_label:
			tween.tween_property(level_goal_label, "modulate:a", 0.0, 0.5)

		await tween.finished

		level_intro_label.hide()
		if level_goal_label:
			level_goal_label.hide()

func _get_random_spawn_position(min_dist: float, max_dist: float) -> Vector2:
	var player_pos = cached_player.global_position if cached_player else Vector2.ZERO
	var angle = randf() * TAU
	var distance = randf_range(min_dist, max_dist)
	var pos = player_pos + Vector2(cos(angle), sin(angle)) * distance
	pos.x = clamp(pos.x, spawn_area_min.x, spawn_area_max.x)
	pos.y = clamp(pos.y, spawn_area_min.y, spawn_area_max.y)
	return pos

func spawn_initial_items(scene: PackedScene, count: int) -> void:
	if not scene or count <= 0:
		return
	for i in range(count):
		var item = scene.instantiate()
		item.global_position = _get_random_spawn_position(safe_radius, powerup_max_distance)
		add_child(item)

func _on_batch_timer_timeout() -> void:
	if batches_spawned < total_batches:
		spawn_batch()
	else:
		batch_timer.stop()

func spawn_batch() -> void:
	batches_spawned += 1

	if enemy_diamond and diamonds_per_batch > 0:
		spawn_enemy_type(enemy_diamond, diamonds_per_batch)

	if enemy_plus and pluses_per_batch > 0:
		spawn_enemy_type(enemy_plus, pluses_per_batch)

	if enemy_gigantor and randf() < gigantor_spawn_chance:
		spawn_enemy_type(enemy_gigantor, 1)

func spawn_enemy_type(scene: PackedScene, amount: int) -> void:
	for i in range(amount):
		var enemy = scene.instantiate()
		enemy.global_position = _get_random_spawn_position(safe_radius, safe_radius + 1200.0)
		add_child(enemy)

func check_win_condition() -> void:
	if level_completed:
		return

	if cached_player and "score" in cached_player:
		if cached_player.score >= target_score:
			complete_level()

func complete_level() -> void:
	level_completed = true

	if level_cleared_label:
		level_cleared_label.show()

	get_tree().paused = true
	await get_tree().create_timer(3.0, true, false, true).timeout
	get_tree().paused = false

	if get_node_or_null("/root/Global"):
		Global.go_to_level(next_level_scene)
	else:
		SceneManager.change_scene(next_level_scene, {
			"pattern": "squares",
			"time": 1.0
		})
