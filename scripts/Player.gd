extends CharacterBody2D

var held_item: Node = null

var nearby_interactables = []
	
func has_item() -> bool:
	return held_item != null

func add_item(item) -> void:
	if has_item():
		return
	held_item = item

func remove_item() -> Node:
	if not has_item():
		return null
	var removed_item = held_item
	held_item = null
	return removed_item

func get_closest_interactable():
	var closest = null
	var closest_dist := INF
	for interactable in nearby_interactables:
		var dist = global_position.distance_to(interactable.global_position)
		if dist < closest_dist:
			closest = interactable
			closest_dist = dist
	return closest

func _try_interact():
	if not nearby_interactables.is_empty():
		get_closest_interactable().interact(self)

func _on_interaction_area_entered(area: Area2D) -> void:
	if area.is_in_group("interactables"):
		nearby_interactables.append(area.get_parent())
		_try_interact()

func _on_interaction_area_exited(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent.is_in_group("interactables"):
		nearby_interactables.erase(parent)
