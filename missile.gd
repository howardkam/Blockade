extends Area2D

@export var speed: float = 900.0
@export var turn_speed: float = 20.0
@export var damage: float = 1.0
@export var homing_delay: float = 0.25 # Seconds before homing kicks in

@export_group("Trail Settings")
@export var max_trail_length: int = 15

var direction: Vector2 = Vector2.UP
var target: Node2D = null
var hit_registered: bool = false
var time_alive: float = 0.0

@onready var trail: Line2D = $Trail

func _ready():
	$VisibleOnScreenEnabler2D.screen_exited.connect(queue_free)
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

	if trail:
		trail.top_level = true
		trail.clear_points()

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
	time_alive += delta

	# Straight flight phase during homing_delay, homing phase after
	if time_alive >= homing_delay:
		if is_instance_valid(target):
			var target_dir = (target.global_position - global_position).normalized()
			direction = direction.slerp(target_dir, turn_speed * delta).normalized()
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
		
	var target_node = node
	if not target_node.has_method("take_damage") and target_node.get_parent() and target_node.get_parent().has_method("take_damage"):
		target_node = target_node.get_parent()

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
	if has_node("Missilemaverick"):
		$Missilemaverick.hide()
	
	if trail:
		var tween = create_tween()
		tween.tween_property(trail, "modulate:a", 0.0, 0.2)
		tween.finished.connect(queue_free)
	else:
		queue_free()