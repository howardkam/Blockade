extends Area2D

@export var speed: float = 2400.0
@export var damage: float = 100.0
@export var beam_color: Color = Color(4.0, 0.2, 0.2, 1.0) # HDR Red Glow
@export var max_trail_length: int = 12

var direction: Vector2 = Vector2.ZERO

@onready var trail: Line2D = $Trail
@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	$VisibleOnScreenEnabler2D.screen_exited.connect(queue_free)
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

	if trail:
		trail.top_level = true
		trail.clear_points()
		apply_glow_gradient()

func apply_glow_gradient():
	if not trail:
		return
		
	var grad = Gradient.new()
	var fade_color = beam_color
	fade_color.a = 0.0
	
	grad.set_color(0, fade_color)
	grad.set_color(1, beam_color)
	
	trail.gradient = grad
	if sprite:
		sprite.modulate = beam_color

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
	if not node:
		return
		
	var target_node = node
	if not target_node.has_method("take_damage") and target_node.get_parent() and target_node.get_parent().has_method("take_damage"):
		target_node = target_node.get_parent()
		
	if target_node.is_in_group("player"):
		return
		
	# Check if the target is on screen before applying damage
	if is_node_on_screen(target_node):
		if target_node.has_method("take_damage"):
			target_node.take_damage(damage)

func is_node_on_screen(node: Node2D) -> bool:
	if not is_instance_valid(node):
		return false
		
	# 1. If enemy has a VisibleOnScreenNotifier2D node, use its built-in status
	if node.has_node("VisibleOnScreenNotifier2D"):
		var notifier = node.get_node("VisibleOnScreenNotifier2D") as VisibleOnScreenNotifier2D
		if notifier:
			return notifier.is_on_screen()

	# 2. Canvas transform fallback check for camera viewport bounds
	var viewport = get_viewport()
	if viewport:
		var canvas_transform = viewport.get_canvas_transform()
		var screen_pos = canvas_transform * node.global_position
		return viewport.get_visible_rect().has_point(screen_pos)
		
	return true
