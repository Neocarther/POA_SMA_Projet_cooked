extends Station

func _ready() -> void:
	add_to_group("interactable")

func interact(agent) -> void:
	if not agent.has_item():
		print("Need meal in hand to serve something")
	elif agent.item_type() == "PlatedMeal":
		receive_item(agent)
		if current_item.is_complete():
			var parent = get_parent()
			if parent.has_method("update_score_and_objectives"):
				parent.update_score_and_objectives(current_item)
				remove_child(current_item)
		else:
			give_item(agent)
	else:
		print("Cannot serve ingredients only, only meals")
