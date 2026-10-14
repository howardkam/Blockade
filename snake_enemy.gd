extends Area2D

# Movement & Combat
@export var move_speed: float = 120.0
@export var max_health: int = 1
@export var pointvalue: int = 5

# Snake Segment Settings
@export var segment_count: int = 10
@export var segment_distance: float = 24.0 # Pixels between segment centers
@export var segment_scene: PackedScene = preload("res://body_segment.tscn")

# Slither Wiggle Controls
@export var slither_frequency: float = 5.0
@export var slither_amplitude: float = 20.0

var player: Node2D = null
var current_health: int
var segments: Array[Node2D] = []
var history: Array[Vector2] = []
var time_passed: float = 0.0

# History resolution settings
const STEP_DIST: float = 4.0 # Record head position every 4 pixels
var points_per_segment: int

func _ready() -> void:
	current_health = max_health
	add_to_group("enemies")

	points_per_segment = int(segment_distance / STEP_DIST)
	var max_history = (segment_count + 1) * points_per_segment + 5

	# 1. Pre-fill history straight down so segments start spread out in a line
	var initial_dir = Vector2.DOWN
	for i in range(max_history):
		history.append(global_position - (initial_dir * (i * STEP_DIST)))

	# 2. Instantiate segments along the trail
	for i in range(segment_count):
		var segment = segment_scene.instantiate()
		add_child(segment)
		segments.append(segment)

		var idx = (i + 1) * points_per_segment
		segment.global_position = history[idx]
		segment.rotation = initial_dir.angle() + PI / 2
		segment.z_index = -1 - i

func _physics_process(delta: float) -> void:
	time_passed += delta
	move_head(delta)
	update_segments()

func move_head(delta: float) -> void:
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")

	var target_pos = player.global_position if (player and is_instance_valid(player)) else get_global_mouse_position()
	var base_direction = global_position.direction_to(target_pos)

	# Calculate side-to-side slither offset
	var perp = Vector2(-base_direction.y, base_direction.x)
	var slither_offset = perp * sin(time_passed * slither_frequency) * slither_amplitude

	# Move head
	var move_vector = (base_direction * move_speed) + slither_offset
	global_position += move_vector * delta

	if move_vector != Vector2.ZERO:
		rotation = move_vector.angle() + PI / 2

	# Record head position to history whenever head travels STEP_DIST
	if history.is_empty() or history[0].distance_to(global_position) >= STEP_DIST:
		history.push_front(global_position)
		var max_history = (segment_count + 1) * points_per_segment + 5
		if history.size() > max_history:
			history.resize(max_history)

func update_segments() -> void:
	for i in range(segments.size()):
		var idx = (i + 1) * points_per_segment
		if idx < history.size():
			segments[i].global_position = history[idx]

			# Face preceding point along history trail
			var prev_idx = max(0, idx - points_per_segment)
			var dir = (history[prev_idx] - history[idx]).normalized()
			if dir != Vector2.ZERO:
				segments[i].rotation = dir.angle() + PI / 2

func take_damage(from_bomb: bool = false) -> void:
	current_health -= 1
	modulate = Color.YELLOW

	if current_health <= 0:
		if has_node("explosion"):
			var sound = $explosion
			sound.reparent(get_tree().current_scene)
			sound.global_position = global_position
			sound.play()
			sound.finished.connect(sound.queue_free)

		var p = get_tree().get_first_node_in_group("player")
		if p and p.has_method("add_score"):
			p.add_score(pointvalue)

		queue_free()
