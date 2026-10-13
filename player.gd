extends CharacterBody2D

signal died

@export var bullet_scene: PackedScene = preload("res://bullet.tscn")
@export var move_speed: float = 500.0
@export var fire_rate: float = 0.07

# Health & Death configuration
@export var max_health: float = 100.0
@export var damage_per_second: float = 40.0

const WORLD_LIMIT_MIN = -3000.0
const WORLD_LIMIT_MAX = 3000.0

var can_shoot: bool = true
var shoot_timer: float = 0.0
var score: int = 0
var current_health: float = 100.0
var is_dead: bool = false

@onready var score_label: Label = $UI/ScoreLabel
@onready var hitbox: Area2D = $hitbox
@onready var ui_layer: CanvasLayer = $UI
@onready var health_bar: ProgressBar = $ProgressBar

func _ready():
	current_health = max_health
	update_score_ui()
	setup_health_bar()

func setup_health_bar():
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		health_bar.show_percentage = false
		
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = Color(0.0, 1.0, 0.0, 1.0)
		health_bar.add_theme_stylebox_override("fill", fill_style)
		
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
		health_bar.add_theme_stylebox_override("background", bg_style)

func add_score(amount: int = 10):
	score += amount
	update_score_ui()

func update_score_ui():
	if score_label:
		score_label.text = str(score)

func _physics_process(delta):
	# Restart scene on key press when dead
	if is_dead:
		if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_R):
			get_tree().reload_current_scene()
		return

	# 1. Smooth Movement using Input.get_vector()
	var move_dir = Input.get_vector("left", "right", "up", "down")
	velocity = move_dir * move_speed
	move_and_slide()

	global_position.x = clamp(global_position.x, WORLD_LIMIT_MIN, WORLD_LIMIT_MAX)
	global_position.y = clamp(global_position.y, WORLD_LIMIT_MIN, WORLD_LIMIT_MAX)

	# 2. Check enemy contact damage
	check_enemy_damage(delta)

	# 3. Continuous 360° Shooting using Input.get_vector()
	var shoot_dir = Input.get_vector("shootleft", "shootright", "shootup", "shootdown")

	if not can_shoot:
		shoot_timer -= delta
		if shoot_timer <= 0.0:
			can_shoot = true

	# Fire bullet if right stick/keys are pushed past deadzone
	if shoot_dir.length() > 0.1 and can_shoot:
		fire_bullet(shoot_dir.normalized())
		can_shoot = false
		shoot_timer = fire_rate

func check_enemy_damage(delta: float):
	if not hitbox:
		return
		
	var is_touching_enemy = false
	
	for area in hitbox.get_overlapping_areas():
		var parent = area.get_parent()
		if area.is_in_group("enemy") or area.is_in_group("enemies") or (parent and (parent.is_in_group("enemy") or parent.is_in_group("enemies"))):
			is_touching_enemy = true
			break
			
	if not is_touching_enemy:
		for body in hitbox.get_overlapping_bodies():
			if body.is_in_group("enemy") or body.is_in_group("enemies"):
				is_touching_enemy = true
				break

	if is_touching_enemy:
		take_damage(damage_per_second * delta)

func take_damage(amount: float):
	current_health -= amount
	current_health = max(current_health, 0.0)
	
	if health_bar:
		health_bar.value = current_health

	if current_health <= 0.0 and not is_dead:
		die()

func die():
	is_dead = true
	velocity = Vector2.ZERO
	hide()
	
	# Emit signal for exterior spawners/managers
	died.emit()
	
	# 1. Stop all active scene Timers (stops enemy spawners)
	stop_all_spawners()
	
	# 2. Despawn all existing enemy nodes to free memory
	clear_all_enemies()
	
	show_game_over()

func stop_all_spawners():
	# Stop all Timer nodes running in the main world scene
	var scene_tree = get_tree().current_scene
	if scene_tree:
		for child in scene_tree.get_children(true):
			if child is Timer:
				child.stop()

func clear_all_enemies():
	# Collect nodes from both global and local enemy group names
	var enemies = get_tree().get_nodes_in_group("enemy") + get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()

func show_game_over():
	var game_over_label = Label.new()
	game_over_label.text = "GAME OVER\n\nPRESS [R] OR [ENTER] TO RESTART"
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	game_over_label.anchors_preset = Control.PRESET_FULL_RECT
	game_over_label.anchor_left = 0.0
	game_over_label.anchor_top = 0.0
	game_over_label.anchor_right = 1.0
	game_over_label.anchor_bottom = 1.0
	
	var font = load("res://Assets/ka1.ttf")
	if font:
		game_over_label.add_theme_font_override("font", font)
		game_over_label.add_theme_font_size_override("font_size", 36)
	game_over_label.add_theme_color_override("font_color", Color.RED)
	
	ui_layer.add_child(game_over_label)

func fire_bullet(dir: Vector2):
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.direction = dir
	bullet.rotation = dir.angle()
	get_tree().current_scene.add_child(bullet)
