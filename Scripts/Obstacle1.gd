extends StaticBody2D

@export var move_speed: float = 550.0
@export var target_marker: Marker2D
@export var rainbow_speed: float = 3.0 # Speed of color cycling
@export_range(0.0, 1.0) var base_opacity: float = 0.3 # Opacity adjustment variable

var hue: float = 0.0
var start_position: Vector2
var target_position: Vector2
var moving_to_target: bool = true

func _ready() -> void:
	start_position = global_position
	
	if not target_marker and has_node("TargetMarker2D"):
		target_marker = $TargetMarker2D
	
	# Store the global position of the target marker at the start
	if is_instance_valid(target_marker):
		target_position = target_marker.global_position

func _process(delta: float) -> void:
	# Rainbow glow animation while preserving custom alpha/opacity
	hue = fmod(hue + delta * rainbow_speed * 0.2, 1.0)
	var color = Color.from_hsv(hue, 0.8, 1.0)
	color.a = base_opacity
	modulate = color

	# Continuous ping-pong movement
	var destination = target_position if moving_to_target else start_position
	global_position = global_position.move_toward(destination, move_speed * delta)
	
	# Increase tolerance slightly to account for high movement speeds
	if global_position.distance_to(destination) < 2.0:
		moving_to_target = !moving_to_target
