extends Area2D

@export var move_speed: float = 120.0
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
	# Random float movement
	direction_timer -= delta
	if direction_timer <= 0.0:
		pick_new_direction()

	global_position += move_direction * move_speed * delta

	# Clamp to map boundaries and bounce direction if reaching the edge
	if global_position.x < WORLD_LIMIT_MIN or global_position.x > WORLD_LIMIT_MAX:
		move_direction.x *= -1.0
		global_position.x = clamp(global_position.x, WORLD_LIMIT_MIN, WORLD_LIMIT_MAX)

	if global_position.y < WORLD_LIMIT_MIN or global_position.y > WORLD_LIMIT_MAX:
		move_direction.y *= -1.0
		global_position.y = clamp(global_position.y, WORLD_LIMIT_MIN, WORLD_LIMIT_MAX)

	# Gentle spin animation while floating
	rotation += 1.5 * delta

func pick_new_direction() -> void:
	var angle = randf() * TAU
	move_direction = Vector2(cos(angle), sin(angle))
	direction_timer = randf_range(direction_change_interval * 0.6, direction_change_interval * 1.4)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		explode()

func explode() -> void:
	# Detach rainbow particle node to survive bomb queue_free()
	if is_instance_valid(particles):
		particles.reparent(get_tree().current_scene)
		particles.global_position = global_position
		particles.emitting = true

		var cleanup_timer = get_tree().create_timer(particles.lifetime + 0.2)
		cleanup_timer.timeout.connect(particles.queue_free)

	# Find and destroy all enemies within explosion_radius (1000px)
	var enemies = get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("enemy")
	var processed_enemies = {}

	for enemy in enemies:
		if is_instance_valid(enemy) and enemy is Node2D and not processed_enemies.has(enemy):
			processed_enemies[enemy] = true
			if global_position.distance_to(enemy.global_position) <= explosion_radius:
				if "current_health" in enemy:
					enemy.current_health = 0
				if enemy.has_method("take_damage"):
					enemy.take_damage()
				else:
					enemy.queue_free()

	# Remove the bomb node
	queue_free()
