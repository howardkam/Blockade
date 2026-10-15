extends Node2D

@onready var tutorial_label: Label = $CanvasLayer/TutorialLabel

@export var step_duration: float = 3.5
@export_file("*.tscn") var target_scene: String = "res://world_1.tscn"

var tutorial_steps: Array[String] = [
	"Move around with the left stick.",
	"Shoot with the right stick.",
	"Enemies come in waves.",
	"The longer an enemy touches you, health is lost. The game is over when your health reaches zero.",
	"Press START or ENTER to continue."
]

var waiting_for_start: bool = false
var has_transitioned: bool = false

func _ready() -> void:
	run_tutorial_sequence()

func run_tutorial_sequence() -> void:
	for i in range(tutorial_steps.size()):
		if has_transitioned:
			return
		tutorial_label.text = tutorial_steps[i]
		
		if i == tutorial_steps.size() - 1:
			waiting_for_start = true
		else:
			await get_tree().create_timer(step_duration).timeout

func _unhandled_input(event: InputEvent) -> void:
	# Check for physical Enter key (Main Enter or Numpad Enter)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			complete_tutorial()
			return
			
	# Also allow input action bindings ("start" / "ui_accept")
	if event.is_action_pressed("start") or event.is_action_pressed("ui_accept"):
		complete_tutorial()

func complete_tutorial() -> void:
	if has_transitioned:
		return
	has_transitioned = true
	tutorial_label.hide()
	SceneManager.change_scene(target_scene)
