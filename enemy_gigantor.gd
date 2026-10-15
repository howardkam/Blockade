extends CharacterBody2D


@export var move_speed: float = 50.0
@export var turn_speed: float = 10 # Turning rate in radians per second (~200°/sec)
@export var shrink_percentage: float = 1.2 # Percentage to shrink on each hit (5 = 5%)
@export var min_scale_ratio: float = 0.05 # Explodes when reaching this size ratio (0.10 = 10%)
@export var pointvalue: int = 100

@onready var explosionsound = $explosion
const WORLD_LIMIT_MIN = -3000.0
const WORLD_LIMIT_MAX = 3000.0

static var suppress_explosion_sounds: bool = false

var player: Node2D = null
var initial_scale: Vector2 = Vector2.ONE
var current_scale_ratio: float = 1.0
var cached_separation: Vector2 = Vector2.ZERO
var frame_offset: int = 0

func _ready():
	initial_scale = scale
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

	# Smoothly rotate facing angle toward target direction
	rotation = rotate_toward(rotation, target_angle, turn_speed * delta)

	# Drive velocity forward relative to facing rotation
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
	if from_bomb:
		explode(true)
		return

	# Reduce current scale ratio by the shrink percentage
	current_scale_ratio -= shrink_percentage / 100.0
	modulate = Color.LAWN_GREEN

	# Check if size reached or dropped below min_scale_ratio (10%)
	if current_scale_ratio <= (min_scale_ratio + 0.001):
		explode(false)
	else:
		scale = initial_scale * current_scale_ratio

func explode(from_bomb: bool = false):
	# Play explosion sound only if destroyed normally and sounds are not suppressed
	if not from_bomb and not suppress_explosion_sounds and is_instance_valid(explosionsound):
		explosionsound.add_to_group("enemy_explosion_sounds")
		explosionsound.reparent(get_tree().current_scene)
		explosionsound.global_position = global_position
		explosionsound.play()
		explosionsound.finished.connect(explosionsound.queue_free)

	var player_node = get_tree().get_first_node_in_group("player")
	if player_node:
		if player_node.has_method("add_score"):
			player_node.add_score(pointvalue)
		if player_node.has_method("heal"):
			player_node.heal(15.0)

	spawn_score_label(pointvalue)
	
	if has_node("ExplosionParticles"):
		var particles = $ExplosionParticles
		particles.reparent(get_tree().current_scene)
		particles.global_position = global_position
		particles.scale = Vector2.ONE  # Resets particle scale back to 100%
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
