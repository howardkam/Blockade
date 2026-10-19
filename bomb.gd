extends Area2D

@export var move_speed: float = 200.0
@export var explosion_radius: float = 1000.0
@export var direction_change_interval: float = 1.8

const WORLD_LIMIT_MIN = -2800.0
const WORLD_LIMIT_MAX = 2800.0

var move_direction: Vector2 = Vector2.ZERO
var direction_timer: float = 0.0

@onready var particles: CPUParticles2D = $RainbowExplosionParticles

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	pick_new_direction()

func _process(delta: float) -> void:
	direction_timer -= delta
	if direction_timer <= 0.0:
		pick_new_direction()

	global_position += move_direction * move_speed * delta

	if global_position.x < WORLD_LIMIT_MIN or global_position.x > WORLD_LIMIT_MAX:
		move_direction.x *= -1.0
		global_position.x = clamp(global_position.x, WORLD_LIMIT_MIN, WORLD_LIMIT_MAX)

	if global_position.y < WORLD_LIMIT_MIN or global_position.y > WORLD_LIMIT_MAX:
		move_direction.y *= -1.0
		global_position.y = clamp(global_position.y, WORLD_LIMIT_MIN, WORLD_LIMIT_MAX)

	rotation += 1.5 * delta

func pick_new_direction() -> void:
	var angle = randf() * TAU
	move_direction = Vector2(cos(angle), sin(angle))
	direction_timer = randf_range(direction_change_interval * 0.6, direction_change_interval * 1.4)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		explode()

func explode() -> void:
	# Hide bomb visual and disable collisions
	hide()
	set_process(false)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	# Reparent particles so they don't get cut off when the bomb node is freed
	if is_instance_valid(particles):
		particles.reparent(get_tree().current_scene)
		particles.global_position = global_position
		particles.emitting = true

		var cleanup_timer = get_tree().create_timer(particles.lifetime + 0.2)
		cleanup_timer.timeout.connect(particles.queue_free)

	# Trigger radial screen gradient flash with smooth fade out
	trigger_screen_radial_flash()

	# Destroy enemies within the exportable explosion_radius
	var enemies = get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("enemy")
	var processed_enemies = {}

	for enemy in enemies:
		if is_instance_valid(enemy) and enemy is Node2D and not processed_enemies.has(enemy):
			processed_enemies[enemy] = true
			if global_position.distance_to(enemy.global_position) <= explosion_radius:
				if "current_health" in enemy:
					enemy.current_health = 0
				if enemy.has_method("take_damage"):
					enemy.take_damage(true)
				else:
					enemy.queue_free()

	queue_free()

func trigger_screen_radial_flash() -> void:
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	get_tree().current_scene.add_child(canvas_layer)

	var rect = TextureRect.new()
	# Set full screen anchors
	rect.anchor_right = 1.0
	rect.anchor_bottom = 1.0
	rect.offset_right = 0.0
	rect.offset_bottom = 0.0
	rect.grow_horizontal = Control.GROW_DIRECTION_BOTH
	rect.grow_vertical = Control.GROW_DIRECTION_BOTH
	rect.pivot_offset = get_viewport_rect().size / 2.0 # Use actual viewport size for center pivot
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	canvas_layer.add_child(rect)

	# Radial gradient texture configuration
	var grad_tex = GradientTexture2D.new()
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	grad_tex.fill_from = Vector2(0.5, 0.5)
	grad_tex.fill_to = Vector2(1.0, 1.0)

	var grad = Gradient.new()
	grad.set_color(0, Color(1, 1, 0.8, 1.0)) # Bright explosive core
	grad.set_color(1, Color(1, 0.2, 0.0, 0.0)) # Transparent outer edge
	grad_tex.gradient = grad

	rect.texture = grad_tex

	# IMPORTANT: Attach tween to canvas_layer so it isn't destroyed when bomb is freed
	var tween = canvas_layer.create_tween().set_parallel(true)
	
	# Scale expansion
	tween.tween_property(rect, "scale", Vector2(2.5, 2.5), 0.6)\
		.from(Vector2(0.2, 0.2))\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
		
	# Smooth self_modulate alpha fade
	tween.tween_property(rect, "self_modulate:a", 0.0, 0.6)\
		.from(1.0)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)

	# Clean up canvas layer when tween finishes
	tween.chain().tween_callback(canvas_layer.queue_free)
