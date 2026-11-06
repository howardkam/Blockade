extends CharacterBody2D

@export var move_speed: float = 120.0
@export var turn_speed: float = 2.0
@export var max_health: int = 200
@export var pointvalue: int = 200
@export var shoot_interval: float = 1.0
@export var fireball_scene: PackedScene = preload("res://Scenes/fireball.tscn")

@onready var sprite: AnimatedSprite2D = $spider
@onready var explosionsound = $explosion if has_node("explosion") else null

const WORLD_LIMIT_MIN = -3000.0
const WORLD_LIMIT_MAX = 3000.0

static var suppress_explosion_sounds: bool = false

var player: Node2D = null
var current_health: int
var cached_separation: Vector2 = Vector2.ZERO
var frame_offset: int = 0
var shoot_timer: Timer

var is_hit_flashing: bool = false

func _ready() -> void:
	current_health = max_health
	add_to_group("enemies")
	add_to_group("boss")
	frame_offset = get_instance_id() % 4
	
	if sprite:
		sprite.play("default")

	shoot_timer = Timer.new()
	shoot_timer.name = "ShootTimer"
	shoot_timer.wait_time = shoot_interval
	shoot_timer.autostart = true
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	add_child(shoot_timer)

func _physics_process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return 

	var direction = global_position.direction_to(player.global_position)
	
	if (Engine.get_physics_frames() + frame_offset) % 4 == 0:
		cached_separation = get_separation_vector()
	
	var final_direction = (direction + cached_separation * 1.2).normalized()
	var target_angle = final_direction.angle() + PI / 2

	rotation = rotate_toward(rotation, target_angle, turn_speed * delta)
	velocity = Vector2.UP.rotated(rotation) * move_speed
	move_and_slide()

	global_position.x = clamp(global_position.x, WORLD_LIMIT_MIN, WORLD_LIMIT_MAX)
	global_position.y = clamp(global_position.y, WORLD_LIMIT_MIN, WORLD_LIMIT_MAX)

func get_separation_vector() -> Vector2:
	var separation = Vector2.ZERO
	var neighbor_count = 0
	var separation_radius = 40.0
	
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy != self and is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < separation_radius and dist > 0.0:
				separation += (global_position - enemy.global_position).normalized() / dist
				neighbor_count += 1
				
	return separation.normalized() if neighbor_count > 0 else Vector2.ZERO

func trigger_white_flash() -> void:
	if not sprite:
		return
		
	is_hit_flashing = true
	sprite.modulate = Color(10.0, 10.0, 10.0, 1.0)
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.12)
	tween.finished.connect(func(): is_hit_flashing = false)

func _on_shoot_timer_timeout() -> void:
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		
	if not player or not is_instance_valid(player):
		return
		
	if fireball_scene:
		var fireball = fireball_scene.instantiate()
		fireball.global_position = global_position
		var dir = global_position.direction_to(player.global_position)
		fireball.direction = dir
		fireball.rotation = dir.angle()
		get_tree().current_scene.add_child(fireball)

func take_damage(amount_or_from_bomb = 1) -> void:
	var damage_amount: int = 1
	var from_bomb: bool = false

	if typeof(amount_or_from_bomb) == TYPE_BOOL:
		from_bomb = amount_or_from_bomb
	elif typeof(amount_or_from_bomb) in [TYPE_INT, TYPE_FLOAT]:
		damage_amount = int(amount_or_from_bomb)

	current_health -= damage_amount
	trigger_white_flash()
	
	if current_health <= 0:
		if not from_bomb and not suppress_explosion_sounds and is_instance_valid(explosionsound):
			explosionsound.add_to_group("enemy_explosion_sounds")
			explosionsound.reparent(get_tree().current_scene)
			explosionsound.global_position = global_position
			explosionsound.play()
			if not explosionsound.finished.is_connected(explosionsound.queue_free):
				explosionsound.finished.connect(explosionsound.queue_free, CONNECT_ONE_SHOT)

		var target_player = get_tree().get_first_node_in_group("player")
		if target_player and target_player.has_method("add_score"):
			target_player.add_score(pointvalue)

		spawn_score_label(pointvalue)
		
		if has_node("ExplosionParticles"):
			var particles = $ExplosionParticles
			particles.reparent(get_tree().current_scene)
			particles.global_position = global_position
			particles.emitting = true
			
			var particle_timer = get_tree().create_timer(1.0)
			particle_timer.timeout.connect(particles.queue_free)
		
		queue_free()

func spawn_score_label(points: int) -> void:
	var label = Label.new()
	label.text = "+" + str(points)
	label.global_position = global_position + Vector2(-15, -30)
	label.modulate = Color.GOLDENROD

	var font = load("res://Assets/movement/Movement.ttf")
	if font:
		label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", 18)
		
	get_tree().current_scene.add_child(label)

	var tween = label.create_tween()
	tween.tween_interval(0.5)
	tween.parallel().tween_property(label, "global_position:y", label.global_position.y - 40.0, 0.5)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5)
	tween.finished.connect(label.queue_free)
