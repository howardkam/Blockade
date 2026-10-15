extends CharacterBody2D

signal died

@export var bullet_scene: PackedScene = preload("res://bullet.tscn")
@export var move_speed: float = 500.0
@export var fire_rate: float = 0.07

@export var max_health: float = 100.0
@export var damage_per_second: float = 40.0

const WORLD_LIMIT_MIN = -3000.0
const WORLD_LIMIT_MAX = 3000.0

var can_shoot: bool = true
var shoot_timer: float = 0.0
var score: int = 0
var current_health: float = 100.0
var is_dead: bool = false

# Camera Shake Variables
var shake_intensity: float = 0.0

@onready var score_label: Label = $UI/ScoreLabel
@onready var hitbox: Area2D = $hitbox
@onready var ui_layer: CanvasLayer = $UI
@onready var sprite: Sprite2D = $"Gear(4)"
@onready var injurysound: AudioStreamPlayer2D = $injurysound
@onready var camera: Camera2D = $Camera2D

var health_bar: ProgressBar
var health_label: Label
var injury_fade_tween: Tween = null
const INJURY_ORIGINAL_VOLUME: float = 10.0

func _ready():
	current_health = max_health
	update_score_ui()
	setup_health_ui()

func setup_health_ui():
	if has_node("ProgressBar"):
		health_bar = $ProgressBar
		health_bar.reparent(ui_layer)
	elif ui_layer.has_node("ProgressBar"):
		health_bar = ui_layer.get_node("ProgressBar")
	else:
		health_bar = ProgressBar.new()
		health_bar.name = "ProgressBar"
		ui_layer.add_child(health_bar)

	if ui_layer.has_node("HealthLabel"):
		health_label = ui_layer.get_node("HealthLabel")
	else:
		health_label = Label.new()
		health_label.name = "HealthLabel"
		ui_layer.add_child(health_label)

	health_label.anchor_left = 0.0
	health_label.anchor_top = 0.0
	health_label.offset_left = 20.0
	health_label.offset_top = 20.0
	health_label.offset_right = 220.0
	health_label.offset_bottom = 45.0
	
	var font = load("res://Assets/ka1.ttf")
	if font:
		health_label.add_theme_font_override("font", font)
		health_label.add_theme_font_size_override("font_size", 18)

	health_bar.anchor_left = 0.0
	health_bar.anchor_top = 0.0
	health_bar.anchor_right = 0.0
	health_bar.anchor_bottom = 0.0
	health_bar.offset_left = 20.0
	health_bar.offset_top = 50.0
	health_bar.offset_right = 220.0
	health_bar.offset_bottom = 70.0
	health_bar.max_value = max_health
	health_bar.show_percentage = false

	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.0, 1.0, 0.0, 1.0)
	health_bar.add_theme_stylebox_override("fill", fill_style)

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	health_bar.add_theme_stylebox_override("background", bg_style)

	update_health_ui()

func add_score(amount: int = 10):
	score += amount
	update_score_ui()

func update_score_ui():
	if score_label:
		score_label.text = str(score)

func update_health_ui():
	if health_bar:
		health_bar.value = current_health
	if health_label:
		var pct = int(clamp((current_health / max_health) * 100.0, 0.0, 100.0))
		health_label.text = "HP: " + str(pct) + "%"

func heal(amount: float):
	current_health = min(current_health + amount, max_health)
	update_health_ui()

func _physics_process(delta):
	# Camera Shake decay and apply
	if camera and shake_intensity > 0.1:
		shake_intensity = lerp(shake_intensity, 0.0, 5.0 * delta)
		camera.offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
	elif camera:
		shake_intensity = 0.0
		camera.offset = Vector2.ZERO

	if is_dead:
		if Input.is_action_just_pressed("start"):
			get_tree().reload_current_scene()
		if Input.is_action_just_pressed("quit"):
			get_tree().quit()
		return

	var move_dir = Input.get_vector("left", "right", "up", "down")
	velocity = move_dir * move_speed
	move_and_slide()

	global_position.x = clamp(global_position.x, WORLD_LIMIT_MIN, WORLD_LIMIT_MAX)
	global_position.y = clamp(global_position.y, WORLD_LIMIT_MIN, WORLD_LIMIT_MAX)

	check_enemy_damage(delta)

	var shoot_dir = Input.get_vector("shootleft", "shootright", "shootup", "shootdown")

	if not can_shoot:
		shoot_timer -= delta
		if shoot_timer <= 0.0:
			can_shoot = true

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
		start_injury_sound()
		
		if sprite:
			var pulse = (sin(Time.get_ticks_msec() * 0.02) + 1.0) * 0.5
			sprite.modulate = Color.WHITE.lerp(Color.RED, pulse)
	else:
		stop_injury_sound_smooth(0.25)
		if sprite:
			sprite.modulate = Color.WHITE

func start_injury_sound():
	if not injurysound:
		return
	if injury_fade_tween and injury_fade_tween.is_running():
		injury_fade_tween.kill()
	injurysound.volume_db = INJURY_ORIGINAL_VOLUME
	if not injurysound.playing:
		injurysound.play()

func stop_injury_sound_smooth(fade_time: float = 0.25):
	if not injurysound or not injurysound.playing:
		return
	if injury_fade_tween and injury_fade_tween.is_running():
		return
		
	injury_fade_tween = create_tween()
	injury_fade_tween.tween_property(injurysound, "volume_db", -80.0, fade_time)
	injury_fade_tween.finished.connect(func():
		if is_instance_valid(injurysound):
			injurysound.stop()
			injurysound.volume_db = INJURY_ORIGINAL_VOLUME
	)

func take_damage(amount: float):
	current_health -= amount
	current_health = max(current_health, 0.0)
	update_health_ui()

	if current_health <= 0.0 and not is_dead:
		die()

func die():
	is_dead = true
	velocity = Vector2.ZERO
	stop_injury_sound_smooth(0.15)
	
	# Trigger violent screen shake
	shake_intensity = 60.0
	
	# Trigger particle explosion before hiding sprite
	spawn_death_explosion()

	# Hide only sprite & disable hitboxes (do NOT call hide() on self)
	if sprite:
		sprite.hide()
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	if hitbox:
		hitbox.set_deferred("monitoring", false)
		hitbox.set_deferred("monitorable", false)
	
	died.emit()
	stop_all_spawners()
	clear_all_enemies()
	show_game_over()

func spawn_death_explosion():
	if has_node("DeathParticles"):
		var particles = $DeathParticles as CPUParticles2D
		# Move particles out of the player node so they aren't deleted/hidden
		particles.reparent(get_tree().current_scene)
		particles.global_position = global_position
		particles.restart()
		particles.emitting = true
		get_tree().create_timer(particles.lifetime + 0.5).timeout.connect(particles.queue_free)

func stop_all_spawners():
	var scene_tree = get_tree().current_scene
	if scene_tree:
		for child in scene_tree.get_children(true):
			if child is Timer:
				child.stop()

func clear_all_enemies():
	var enemies = get_tree().get_nodes_in_group("enemy") + get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()

func show_game_over():
	var game_over_label = Label.new()
	game_over_label.text = "GAME OVER\n\nPress START to try again"
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
