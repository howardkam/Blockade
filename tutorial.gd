extends Node2D

func transition_to_scene(scene_path: String) -> void:
	if get_node_or_null("/root/Global"):
		Global.go_to_level(scene_path)
	else:
		SceneManager.change_scene(scene_path, {
			"pattern": "squares",
			"time": 1
		})

func _on_world_1_button_pressed() -> void:
	transition_to_scene("res://world_1.tscn")

func _on_world_2_button_pressed() -> void:
	transition_to_scene("res://world_2.tscn")

func _on_world_3_button_pressed() -> void:
	transition_to_scene("res://world_3.tscn")