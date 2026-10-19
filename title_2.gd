extends Node2D

@onready var label: Label = $CanvasLayer/CenterContainer/Label

@export var auto_transition_time: float = 10.0
@export_file("*.tscn") var next_scene: String = "res://tutorial.tscn"

var has_transitioned: bool = false

func _ready() -> void:
	# Auto-advance timer set to 10 seconds
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

	# Reset game tracking singleton if active
	if get_node_or_null("/root/Global"):
		Global.reset_game()

	SceneManager.change_scene(next_scene, {
		"pattern": "fade",
		"time": 3
	})
