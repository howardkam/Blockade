extends Node2D

@onready var buttons: Array[Button] = [
	$CanvasLayer/MenuContainer/World1Button,
	$CanvasLayer/MenuContainer/World2Button,
	$CanvasLayer/MenuContainer/World3Button,
	$CanvasLayer/MenuContainer/InstructButton
]

func _ready() -> void:
	# Set focus neighbor overrides so Up/Down navigation wraps correctly
	buttons[0].focus_neighbor_top = buttons[3].get_path()
	buttons[3].focus_neighbor_bottom = buttons[0].get_path()

	for button in buttons:
		button.pivot_offset = button.size / 2.0
		
		# Connect mouse hover and keyboard focus signals dynamically
		button.mouse_entered.connect(_on_button_hover.bind(button, true))
		button.mouse_exited.connect(_on_button_hover.bind(button, false))
		button.focus_entered.connect(_on_button_hover.bind(button, true))
		button.focus_exited.connect(_on_button_hover.bind(button, false))
		
		# Connect press animation signals
		button.button_down.connect(_on_button_down.bind(button))
		button.button_up.connect(_on_button_up.bind(button))

	# Automatically focus the first button when the scene starts
	buttons[0].grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	# Ignore up/down navigation inputs so they don't accidentally confirm selection
	if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
		return

	# Check if any key or controller button was pressed down
	if (event is InputEventKey or event is InputEventJoypadButton) and event.is_pressed():
		var focused = get_viewport().gui_get_focus_owner()
		if focused is Button:
			focused.emit_signal("pressed")
			get_viewport().set_input_as_handled()

func _on_button_hover(button: Button, is_active: bool) -> void:
	var target_scale = Vector2(1.08, 1.08) if is_active else Vector2(1.0, 1.0)
	var target_color = Color(1.0, 0.2, 0.2) if is_active else Color(1.0, 1.0, 1.0)
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target_scale, 0.15)
	tween.tween_property(button, "modulate", target_color, 0.15)

func _on_button_down(button: Button) -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.08)
	tween.tween_property(button, "modulate", Color(0.8, 0.1, 0.1), 0.08)

func _on_button_up(button: Button) -> void:
	var is_active = button.is_hovered() or button.has_focus()
	var target_scale = Vector2(1.08, 1.08) if is_active else Vector2(1.0, 1.0)
	var target_color = Color(1.0, 0.2, 0.2) if is_active else Color(1.0, 1.0, 1.0)
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target_scale, 0.1)
	tween.tween_property(button, "modulate", target_color, 0.1)

func transition_to_scene(scene_path: String) -> void:
	if get_node_or_null("/root/Global"):
		Global.go_to_level(scene_path)
	else:
		SceneManager.change_scene(scene_path, {
			"pattern": "squares",
			"time": 1
		})

func _on_world_1_button_pressed() -> void:
	transition_to_scene("res://Scenes/world_4.tscn")

func _on_world_2_button_pressed() -> void:
	transition_to_scene("res://Scenes/world_2.tscn")

func _on_world_3_button_pressed() -> void:
	transition_to_scene("res://Scenes/world_3.tscn")

func _on_instruct_button_pressed() -> void:
	transition_to_scene("res://Scenes/instructions.tscn")
