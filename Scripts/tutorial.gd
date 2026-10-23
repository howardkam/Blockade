extends Node2D

@onready var buttons: Array[Button] = [
	$CanvasLayer/MenuContainer/World1Button,
	$CanvasLayer/MenuContainer/World2Button,
	$CanvasLayer/MenuContainer/World3Button,
	$CanvasLayer/MenuContainer/InstructButton
]

func _ready() -> void:
	for button in buttons:
		# Set pivot offset to center so scaling expands outward from the middle
		button.pivot_offset = button.size / 2.0
		
		# Connect mouse hover and press signals dynamically
		button.mouse_entered.connect(_on_button_hover.bind(button, true))
		button.mouse_exited.connect(_on_button_hover.bind(button, false))
		button.button_down.connect(_on_button_down.bind(button))
		button.button_up.connect(_on_button_up.bind(button))

func _on_button_hover(button: Button, is_hovered: bool) -> void:
	var target_scale = Vector2(1.08, 1.08) if is_hovered else Vector2(1.0, 1.0)
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target_scale, 0.15)

func _on_button_down(button: Button) -> void:
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.08)

func _on_button_up(button: Button) -> void:
	var target_scale = Vector2(1.08, 1.08) if button.is_hovered() else Vector2(1.0, 1.0)
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target_scale, 0.1)

func transition_to_scene(scene_path: String) -> void:
	if get_node_or_null("/root/Global"):
		Global.go_to_level(scene_path)
	else:
		SceneManager.change_scene(scene_path, {
			"pattern": "squares",
			"time": 1
		})

func _on_world_1_button_pressed() -> void:
	transition_to_scene("res://Scenes/world_1.tscn")

func _on_world_2_button_pressed() -> void:
	transition_to_scene("res://Scenes/world_2.tscn")

func _on_world_3_button_pressed() -> void:
	transition_to_scene("res://Scenes/world_3.tscn")

func _on_instruct_button_pressed()-> void:
	transition_to_scene("res://Scenes/instructions.tscn")
