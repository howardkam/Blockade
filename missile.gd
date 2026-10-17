extends Area2D

@export var speed: float = 900.0
@export var turn_speed: float = 20.0
@export var damage: float = 1.0 # Changed to 1 hit point of damage to match regular bullets

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
		trail.clear_points()

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
		
	trail.add_point(global_position)
	while trail.get_point_count() > max_trail_length:
		trail.remove_point(0)

func _on_body_entered(body):
	check_hit(body)

func _on_area_entered(area):
	check_hit(area.get_parent())

func check_hit(node):
	if hit_registered or not node:
		return
		
	# Traverse upwards if colliding with a sub-area/hitbox that doesn't hold take_damage directly
	var target_node = node
	if not target_node.has_method("take_damage") and target_node.get_parent() and target_node.get_parent().has_method("take_damage"):
		target_node = target_node.get_parent()

	# Ignore colliding with the player
	if target_node.is_in_group("player"):
		return
		
	if target_node.has_method("take_damage"):
		hit_registered = true
		target_node.take_damage(damage)
		cleanup_and_destroy()
	else:
		hit_registered = true
		cleanup_and_destroy()

func cleanup_and_destroy():
	set_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	$Missilemaverick.hide()
	
	if trail:
		var tween = create_tween()
		tween.tween_property(trail, "modulate:a", 0.0, 0.2)
		tween.finished.connect(queue_free)
	else:
		queue_free()
