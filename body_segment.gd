extends Area2D

func take_damage(from_bomb: bool = false) -> void:
	var parent = get_parent()
	if parent and parent.has_method("take_damage"):
		parent.take_damage(from_bomb)
