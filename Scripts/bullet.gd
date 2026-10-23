extends Area2D

@export var speed: float = 1200.0
@export var bullet_color: Color = Color(0.0, 0.8, 1.0, 1.0) # Editable color parameter
@export var max_trail_length: int = 15

var direction: Vector2 = Vector2.ZERO
var hit_registered: bool = false

@onready var trail: Line2D = $Trail
@onready var shootsound: AudioStreamPlayer2D = $shootsound

func _ready():
	$VisibleOnScreenEnabler2D.screen_exited.connect(queue_free)
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

	# Set up trail styling and anchor to world space
	if trail:
		trail.top_level = true
		trail.clear_points()
		apply_trail_color()

func apply_trail_color():
	if not trail:
		return
		
	# Build gradient using the custom bullet_color variable
	var grad = Gradient.new()
	var fade_color = bullet_color
	fade_color.a = 0.0
	
	grad.set_color(0, fade_color)
	grad.set_color(1, bullet_color)
	
	trail.gradient = grad
	$ShapeA2.modulate = bullet_color

func _process(delta):
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
		
	if target_node.is_in_group("player"):
		return
		
	if target_node.has_method("take_damage"):
		hit_registered = true
		target_node.take_damage(1)
		cleanup_and_destroy()
	else:
		hit_registered = true
		cleanup_and_destroy()

func cleanup_and_destroy():
	set_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	$"ShapeA2".hide()
	
	if trail:
		var tween = create_tween()
		tween.tween_property(trail, "modulate:a", 0.0, 0.15)
		tween.finished.connect(queue_free)
	else:
		queue_free()
