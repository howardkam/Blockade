# res://global.gd
extends Node

const FIRST_LEVEL_PATH: String = "res://world_1.tscn"
var current_level_path: String = FIRST_LEVEL_PATH

# Reloads the level the player is currently on
func restart_current_level() -> void:
	if current_level_path != "":
		SceneManager.change_scene(current_level_path, {
			"pattern": "squares",
			"time": 1
		})

# Moves to a new level and saves it as the current active checkpoint
func go_to_level(level_path: String) -> void:
	current_level_path = level_path
	SceneManager.change_scene(current_level_path, {
		"pattern": "squares",
		"time": 1
	})

# Resets progression back to Level 1 when starting a new game
func reset_game() -> void:
	current_level_path = FIRST_LEVEL_PATH
