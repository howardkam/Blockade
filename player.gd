extends CharacterBody2D

signal died

@export var bullet_scene: PackedScene = preload("res://bullet.tscn")
@export var missile_scene: PackedScene = preload("res://missile.tscn")
@export var laser_scene: PackedScene = preload("res://laser_beam.tscn")
@export var move_speed: float = 550.0
@export var fire_rate: float = 0.07
@export var aim_smooth_speed: float = 20.0 # Adjust higher for quick response, lower for smoother floating aim

@export var max_health: float = 100.0
@export var damage_per_second: float = 40.0

const WORLD_LIMIT_MIN = -3000.0
const WORLD_LIMIT_MAX = 3000.0

var can_shoot: bool = true
var shoot_timer: float = 0.0
var score: int = 0
var current_health: float = 100.0
var is_dead: bool = false
var has_restarted: bool = false
var smooth_shoot_dir: Vector2 = Vector2.ZERO

# Power-up Variables
var is_missile_active: bool = false
var missile_time_left: float = 0.0

var is_laser_active: bool = false
var laser_time_left: float = 0.0

var is_trident_active: bool = false
var trident_time_left: float = 0.0

# Camera Shake Variables
var shake_intensity: float = 0.0

@onready var score_label: Label = $UI/ScoreLabel
@onready var hitbox: Area2D = $hitbox
@onready var ui_layer: CanvasLayer = $UI
@onready var sprite: Sprite2D = $Mainplayer
@onready var injurysound: AudioStreamPlayer2D = $injurysound
@onready var camera: Camera2D = $Camera2D
@onready var timer_label: Label = $TimerLabel

var health_bar: ProgressBar
var health_label: Label
var injury_fade_tween: Tween = null
const INJURY_ORIGINAL_VOLUME: float = 10.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	add_to_group("player")
	current_health = max_health
	update_score_ui()
	setup_health_ui()
	if timer_label:
		timer_label.hide()

func activate_missile_powerup(duration: float = 30.0):
	is_missile_active = true
	missile_time_left = duration
	if timer_label:
		timer_label.show()

func activate_laser_powerup(duration: float = 20.0):
	is_laser_active = true
	laser_time_left = duration
	if timer_label:
		timer_label.show()

func activate_trident_powerup(duration: float = 20.0):
	is_trident_active = true
	trident_time_left = duration
	if timer_label:
		timer_label.show()

func _unhandled_input(event: InputEvent) -> void:
	if not is_dead or has_restarted:
		return

	var is_enter = event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER)
	var is_action = event.is_action_pressed("start") or event.is_action_pressed("ui_accept")

	if is_enter or is_action:
		has_restarted = true
		restart_game()
	elif event.is_action_pressed("quit"):
		get_tree().quit()

func restart_game() -> void:
	if get_node_or_null("/root/Global"):
		Global.restart_current_level()
	else:
		get_tree().reload_current_scene()

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
	
	var font = load("res://Assets/movement/Movement.ttf")
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
	# Handle Laser Power-up Timer
	if is_laser_active:
		laser_time_left -= delta
		if timer_label:
			timer_label.text = str(ceil(laser_time_left)) + "s"
			
		if laser_time_left <= 0.0:
			is_laser_active = false
			laser_time_left = 0.0
			if timer_label:
				timer_label.hide()

	# Handle Missile Power-up Timer
	if is_missile_active:
		missile_time_left -= delta
		if timer_label:
			timer_label.text = str(ceil(missile_time_left)) + "s"
			
		if missile_time_left <= 0.0:
			is_missile_active = false
			missile_time_left = 0.0
			if timer_label:
				timer_label.hide()

	# Handle Trident Power-up Timer
	if is_trident_active:
		trident_time_left -= delta
		if timer_label:
			timer_label.text = str(ceil(trident_time_left)) + "s"
			
		if trident_time_left <= 0.0:
			is_trident_active = false
			trident_time_left = 0.0
			if timer_label:
				timer_label.hide()

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
		return

	var move_dir = Input.get_vector("left", "right", "up", "down")
	velocity = move_dir * move_speed
	move_and_slide()

	global_position.x = clamp(global_position.x, WORLD_LIMIT_MIN, WORLD_LIMIT_MAX)
	global_position.y = clamp(global_position.y, WORLD_LIMIT_MIN, WORLD_LIMIT_MAX)

	check_enemy_damage(delta)

	var raw_shoot_dir = Input.get_vector("shootleft", "shootright", "shootup", "shootdown")

	if raw_shoot_dir.length() > 0.1:
		smooth_shoot_dir = smooth_shoot_dir.lerp(raw_shoot_dir.normalized(), aim_smooth_speed * delta)
	else:
		smooth_shoot_dir = Vector2.ZERO

	if not can_shoot:
		shoot_timer -= delta
		if shoot_timer <= 0.0:
			can_shoot = true

	if smooth_shoot_dir.length() > 0.1 and can_shoot:
		fire_bullet(smooth_shoot_dir.normalized())
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
	
	shake_intensity = 60.0
	spawn_death_explosion()

	if sprite:
		sprite.hide()
	if timer_label:
		timer_label.hide()
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
	
	var font = load("res://Assets/movement/Movement.ttf")
	if font:
		game_over_label.add_theme_font_override("font", font)
		game_over_label.add_theme_font_size_override("font_size", 36)
	game_over_label.add_theme_color_override("font_color", Color.WHITE_SMOKE)
	
	ui_layer.add_child(game_over_label)

func fire_bullet(dir: Vector2):
	var proj_scene: PackedScene = bullet_scene
	if is_laser_active:
		proj_scene = laser_scene
	elif is_missile_active:
		proj_scene = missile_scene

	if is_trident_active:
		var perpendicular = Vector2(-dir.y, dir.x).normalized()
		var side_spacing: float = 24.0

		var offsets = [
			Vector2.ZERO,
			perpendicular * side_spacing,
			-perpendicular * side_spacing
		]

		for offset in offsets:
			var projectile = proj_scene.instantiate()
			projectile.global_position = global_position + offset
			projectile.direction = dir
			projectile.rotation = dir.angle()
			get_tree().current_scene.add_child(projectile)
	else:
		var projectile = proj_scene.instantiate()
		projectile.global_position = global_position
		projectile.direction = dir
		projectile.rotation = dir.angle()
		get_tree().current_scene.add_child(projectile)
