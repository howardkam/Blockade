extends Node2D

@onready var label: Label = $CanvasLayer/Label

@export var animation_duration: float = 3.5
@export var auto_transition_time: float = 5.0
@export_file("*.tscn") var next_scene: String = "res://tutorial.tscn"

var has_transitioned: bool = false

func _ready() -> void:
	# Wait one frame for CanvasLayer layout anchors to settle to screen center
	await get_tree().process_frame
	
	# Store the dead-center Y position
	var target_y: float = label.position.y
	
	# Start lower than dead center and transparent black
	label.position.y = target_y + 80.0
	label.modulate = Color(0.0, 0.0, 0.0, 0.0)

	# Animate upward movement into dead center and color transition to red
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", target_y, animation_duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate", Color(1.0, 0.0, 0.0, 1.0), animation_duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Auto-advance timer after 5 seconds
	get_tree().create_timer(auto_transition_time).timeout.connect(_on_auto_timer_timeout)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start") or event.is_action_pressed("ui_accept"):
		transition_to_next_scene()

func _on_auto_timer_timeout() -> void:
	transition_to_next_scene()

func transition_to_next_scene() -> void:
	if has_transitioned:
		return
	has_transitioned = true
	SceneManager.change_scene(next_scene)
