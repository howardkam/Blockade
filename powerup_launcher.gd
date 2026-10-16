extends Area2D

@export var float_speed: float = 3.0
@export var float_amplitude: float = 12.0

var base_y: float = 0.0
var time_passed: float = 0.0

func _ready():
	base_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta):
	time_passed += delta
	position.y = base_y + sin(time_passed * float_speed) * float_amplitude

func _on_body_entered(body):
	if body.is_in_group("player") and body.has_method("activate_missile_powerup"):
		body.activate_missile_powerup(30.0)
		queue_free()
