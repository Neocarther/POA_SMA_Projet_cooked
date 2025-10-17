extends Station

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("counter")

func interact(agent):
	if not has_item():
		if agent.has_item():
			receive_item(agent)
			print(current_item.label, " has been placed on the Counter Station")
		else:
			print("Need to hold item to place it on the Counter Station")
	elif _current_item_type() == "PlatedMeal":
		var plated_meal = current_item as PlatedMeal
		receive_item(agent)
		if plated_meal.can_add(current_item):
			plated_meal.add_ingredient(current_item)
			remove_child(current_item)
		else:
			give_item(agent)
		current_item = plated_meal
	else:
		if agent.has_item():
			if agent.item_type() == "PlatedMeal":
				try_make_meal(agent)
			print("Cannot take or place item from Counter Station, hands or station needs to be empty")
		else:
			give_item(agent)
			print("Received ", current_item.label, " from Counter Station")
