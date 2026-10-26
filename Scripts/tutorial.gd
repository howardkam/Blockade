extends Node2D

@onready var buttons: Array[Button] = [
	$CanvasLayer/MenuContainer/World1Button,
	$CanvasLayer/MenuContainer/World2Button,
	$CanvasLayer/MenuContainer/World3Button,
	$CanvasLayer/MenuContainer/World4Button,
	$CanvasLayer/MenuContainer/InstructButton
]

# Color tints for background graphics
const COLOR_MUTED = Color(0.35, 0.35, 0.38) # Darkened gray for idle state
const COLOR_ACTIVE = Color(1.0, 1.0, 1.0)   # Full background brightness on hover/selection
const COLOR_PRESSED = Color(0.7, 0.7, 0.7)  # Slightly darker on click/press

func _ready() -> void:
	for button in buttons:
		button.pivot_offset = button.size / 2.0
		
		# Set initial state to muted gray background
		button.self_modulate = COLOR_MUTED
		
		# Connect mouse hover and keyboard/controller focus signals dynamically
		button.mouse_entered.connect(_on_button_hover.bind(button, true))
		button.mouse_exited.connect(_on_button_hover.bind(button, false))
		button.focus_entered.connect(_on_button_hover.bind(button, true))
		button.focus_exited.connect(_on_button_hover.bind(button, false))
		
		# Connect press animation signals
		button.button_down.connect(_on_button_down.bind(button))
		button.button_up.connect(_on_button_up.bind(button))

	# Automatically focus the first button for controller/keyboard navigation
	buttons[0].grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	# Ignore directional navigation inputs so stick/D-Pad navigation doesn't trigger a click
	if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down") \
	or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		return

	# Check if any controller button or key was pressed
	if (event is InputEventKey or event is InputEventJoypadButton) and event.is_pressed():
		var focused = get_viewport().gui_get_focus_owner()
		if focused is Button:
			focused.emit_signal("pressed")
			get_viewport().set_input_as_handled()

func _on_button_hover(button: Button, is_active: bool) -> void:
	var target_scale = Vector2(1.06, 1.06) if is_active else Vector2(1.0, 1.0)
	var target_bg_color = COLOR_ACTIVE if is_active else COLOR_MUTED
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target_scale, 0.15)
	tween.tween_property(button, "self_modulate", target_bg_color, 0.15)

func _on_button_down(button: Button) -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(0.96, 0.96), 0.08)
	tween.tween_property(button, "self_modulate", COLOR_PRESSED, 0.08)

func _on_button_up(button: Button) -> void:
	var is_active = button.is_hovered() or button.has_focus()
	var target_scale = Vector2(1.06, 1.06) if is_active else Vector2(1.0, 1.0)
	var target_bg_color = COLOR_ACTIVE if is_active else COLOR_MUTED
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target_scale, 0.1)
	tween.tween_property(button, "self_modulate", target_bg_color, 0.1)

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

func _on_instruct_button_pressed() -> void:
	transition_to_scene("res://Scenes/instructions.tscn")

func _on_world_4_button_pressed() -> void:
	transition_to_scene("res://Scenes/world_4.tscn")
