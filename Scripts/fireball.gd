extends Area2D

@export var speed: float = 600.0
@export var damage: int = 10

var direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	var notifier = VisibleOnScreenNotifier2D.new()
	add_child(notifier)
	notifier.screen_exited.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	_handle_impact(body)

func _on_area_entered(area: Area2D) -> void:
	_handle_impact(area)

func _handle_impact(target: Node) -> void:
	if target.is_in_group("enemies") or target.is_in_group("boss") or target.is_in_group("enemy"):
		return
		
	if target.has_method("take_damage"):
		target.take_damage(damage)
		queue_free()
	elif target.name.to_lower().contains("player"):
		if target.has_method("take_damage"):
			target.take_damage(damage)
		queue_free()
