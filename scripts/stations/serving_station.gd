extends Station

func _ready() -> void:
	self.add_to_group("interactable")
	add_to_group("serving_station")

func interact(agent) -> void:
	if not agent.has_item():
		print("Need meal in hand to serve something")
	elif agent.item_type() == "PlatedMeal":
		receive_item(agent)
		if current_item.is_complete():
			remove_child(current_item)
			current_item = null
		else:
			give_item(agent)
	else:
		print("Cannot serve ingredients only, only meals")
