
extends CharacterBody2D

@export var move_speed: float = 150.0
@export var turn_speed: float = 2 # Turning rate in radians per second (~200°/sec)
@export var max_health: int = 1
@export var pointvalue: int = 5

@onready var explosionsound = $explosion
const WORLD_LIMIT_MIN = -3000.0
const WORLD_LIMIT_MAX = 3000.0

static var suppress_explosion_sounds: bool = false

var player: Node2D = null
var current_health: int
var cached_separation: Vector2 = Vector2.ZERO
var frame_offset: int = 0

func _ready():
	current_health = max_health
	add_to_group("enemies")
	frame_offset = get_instance_id() % 4
	
	if has_node("VisibleOnScreenNotifier2D"):
		$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)

func _physics_process(delta):
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return 

	var direction = global_position.direction_to(player.global_position)
	
	if (Engine.get_physics_frames() + frame_offset) % 4 == 0:
		cached_separation = get_separation_vector()
	
	var final_direction = (direction + cached_separation * 1.2).normalized()
	var target_angle = final_direction.angle() + PI / 2

	# 1. Smoothly rotate facing angle toward target direction
	rotation = rotate_toward(rotation, target_angle, turn_speed * delta)

	# 2. Drive velocity forward relative to facing rotation (UP vector offset by +PI/2 rotation)
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

func take_damage(from_bomb: bool = false):
	current_health -= 1
	modulate = Color.GOLDENROD
	
	if current_health <= 0:
		# Play explosion sound only if destroyed normally and sounds are not suppressed
		if not from_bomb and not suppress_explosion_sounds and is_instance_valid(explosionsound):
			explosionsound.add_to_group("enemy_explosion_sounds")
			explosionsound.reparent(get_tree().current_scene)
			explosionsound.global_position = global_position
			explosionsound.play()
			explosionsound.finished.connect(explosionsound.queue_free)

		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("add_score"):
			player.add_score(pointvalue)

		spawn_score_label(pointvalue)
		
		if has_node("ExplosionParticles"):
			var particles = $ExplosionParticles
			particles.reparent(get_tree().current_scene)
			particles.global_position = global_position
			particles.emitting = true
			
			var particle_timer = get_tree().create_timer(1.0)
			particle_timer.timeout.connect(particles.queue_free)
		
		queue_free()

func spawn_score_label(points: int):
	var label = Label.new()
	label.text = "+" + str(points)
	label.global_position = global_position + Vector2(-15, -30)
	
	var font = load("res://Assets/ka1.ttf")
	if font:
		label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", 18)
		
	get_tree().current_scene.add_child(label)
	
	var tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y - 40.0, 0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.finished.connect(label.queue_free)
