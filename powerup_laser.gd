extends Area2D

@export var move_speed: float = 100.0
@export var float_amplitude: float = 2.0  # Bobbing effect height
@export var float_frequency: float = 3.0  # Bobbing effect speed
@export var rotation_speed: float = TAU   # 360 degrees (TAU radians) per second
@export var powerup_duration: float = 20.0

# World boundaries
const WORLD_LIMIT_MIN = -2800.0
const WORLD_LIMIT_MAX = 2800.0

var move_direction: Vector2 = Vector2.RIGHT
var time_passed: float = 0.0

func _ready():
	# Pick a random drift direction
	var random_angle = randf_range(0, TAU)
	move_direction = Vector2.UP.rotated(random_angle).normalized()
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

func _process(delta):
	time_passed += delta
	
	# Primary drift + wave/bobbing motion
	var current_velocity = move_direction * move_speed * delta
	var wave_offset = move_direction.orthogonal() * sin(time_passed * float_frequency) * float_amplitude
	global_position += current_velocity + wave_offset
	
	# Continuous 360-degree rotation
	rotation += rotation_speed * delta
	
	# Bounce off boundaries
	bounce_off_bounds()

func bounce_off_bounds():
	if global_position.x <= WORLD_LIMIT_MIN or global_position.x >= WORLD_LIMIT_MAX:
		move_direction.x *= -1
		global_position.x = clamp(global_position.x, WORLD_LIMIT_MIN, WORLD_LIMIT_MAX)
		
	if global_position.y <= WORLD_LIMIT_MIN or global_position.y >= WORLD_LIMIT_MAX:
		move_direction.y *= -1
		global_position.y = clamp(global_position.y, WORLD_LIMIT_MIN, WORLD_LIMIT_MAX)

func _on_body_entered(body):
	check_pickup(body)

func _on_area_entered(area):
	check_pickup(area.get_parent())

func check_pickup(node):
	if not node:
		return
		
	if node.is_in_group("player") or (node.get_parent() and node.get_parent().is_in_group("player")):
		var player = node if node.is_in_group("player") else node.get_parent()
		if player.has_method("activate_laser_powerup"):
			player.activate_laser_powerup(powerup_duration)
			queue_free()
