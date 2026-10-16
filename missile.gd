extends Area2D

@export var speed: float = 900.0
@export var turn_speed: float = 12.0
@export var damage: float = 50.0

@export_group("Trail Settings")
@export var max_trail_length: int = 30

var direction: Vector2 = Vector2.UP
var target: Node2D = null
var hit_registered: bool = false

@onready var trail: Line2D = $Trail

func _ready():
	$VisibleOnScreenEnabler2D.screen_exited.connect(queue_free)
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

	# Unparent the trail so it stays anchored in world space
	if trail:
		trail.top_level = true

	find_nearest_enemy()

func find_nearest_enemy():
	var enemies = get_tree().get_nodes_in_group("enemy") + get_tree().get_nodes_in_group("enemies")
	var nearest_dist = INF
	
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				target = enemy

func _process(delta):
	if is_instance_valid(target):
		var target_dir = (target.global_position - global_position).normalized()
		direction = direction.slerp(target_dir, turn_speed * delta).normalized()
		rotation = direction.angle() + (PI / 2.0)
	else:
		find_nearest_enemy()
		rotation = direction.angle() + (PI / 2.0)

	position += direction * speed * delta
	update_trail()

func update_trail():
	if not trail:
		return
		
	# Add current global position to trail
	trail.add_point(global_position)
	
	# Limit trail point count
	while trail.get_point_count() > max_trail_length:
		trail.remove_point(0)

func _on_body_entered(body):
	check_hit(body)

func _on_area_entered(area):
	check_hit(area.get_parent())

func check_hit(node):
	if hit_registered or not node:
		return
		
	# Ignore colliding with the player
	if node.is_in_group("player"):
		return
		
	if node.has_method("take_damage"):
		hit_registered = true
		node.take_damage(damage)
		cleanup_and_destroy()
	else:
		hit_registered = true
		cleanup_and_destroy()

func cleanup_and_destroy():
	# Hide sprite and collisions while allowing trail to naturally fade out
	set_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	$Launcher.hide()
	
	# Fade out trail smoothly before deleting node
	if trail:
		var tween = create_tween()
		tween.tween_property(trail, "modulate:a", 0.0, 0.2)
		tween.finished.connect(queue_free)
	else:
		queue_free()
