extends CharacterBody2D

@export var move_speed: float = 175.0
@export var turn_speed: float = 2 # Turning rate in radians per second (~200°/sec)
@export var max_health: int = 1
@export var pointvalue: int = 5
@export var max_trail_points: int = 40

@onready var explosionsound = $explosion
@onready var slug_trail: Line2D = $SlugTrail

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
	
	if is_instance_valid(slug_trail):
		slug_trail.top_level = true
	
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

	rotation = rotate_toward(rotation, target_angle, turn_speed * delta)
	velocity = Vector2.UP.rotated(rotation) * move_speed
	move_and_slide()

	global_position.x = clamp(global_position.x, WORLD_LIMIT_MIN, WORLD_LIMIT_MAX)
	global_position.y = clamp(global_position.y, WORLD_LIMIT_MIN, WORLD_LIMIT_MAX)

	# Update slug trail line points
	if is_instance_valid(slug_trail):
		slug_trail.add_point(global_position)
		if slug_trail.get_point_count() > max_trail_points:
			slug_trail.remove_point(0)

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

func take_damage(amount_or_from_bomb = 1):
	var damage_amount: int = 1
	var from_bomb: bool = false

	if typeof(amount_or_from_bomb) == TYPE_BOOL:
		from_bomb = amount_or_from_bomb
	elif typeof(amount_or_from_bomb) in [TYPE_INT, TYPE_FLOAT]:
		damage_amount = int(amount_or_from_bomb)

	current_health -= damage_amount
	modulate = Color.GOLD
	
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
		
		# Detach trail so it remains on screen and slowly fades away
		if is_instance_valid(slug_trail):
			var trail_node = slug_trail
			slug_trail = null
			trail_node.reparent(get_tree().current_scene)
			var fade_tween = trail_node.create_tween()
			fade_tween.tween_property(trail_node, "modulate:a", 0.0, 1.0)
			fade_tween.finished.connect(trail_node.queue_free)

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
