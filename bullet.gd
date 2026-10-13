extends Area2D

var speed = 1200.0
var direction = Vector2.ZERO
var hit_registered: bool = false

func _ready():
	$VisibleOnScreenEnabler2D.screen_exited.connect(queue_free)
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	check_hit(body)

func _on_area_entered(area):
	check_hit(area.get_parent())

func check_hit(node):
	if hit_registered or not node:
		return
		
	if node.has_method("take_damage"):
		hit_registered = true
		node.take_damage()
		queue_free()
