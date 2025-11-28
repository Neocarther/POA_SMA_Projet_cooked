extends Station

@onready var plated_meal_scene: PackedScene = preload("res://scenes/PlatedMeal.tscn")

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("counter_station")
	_WorldState.item_taken_from_counter()

func interact(agent):
	if not has_item():
		if agent.has_item():
			receive_item(agent)
			_WorldState.item_added_on_counter()
			print(current_item.get_item_name(), " has been placed on the Counter Station")
		else:
			print("Need to hold item to place it on the Counter Station")
	elif _current_item_type() == "PlatedMeal":
		var plated_meal = current_item as PlatedMeal
		if not agent.has_item():
			give_item(agent)
			_WorldState.item_taken_from_counter()
		else:
			current_item = null
			receive_item(agent)
			if current_item != null and plated_meal.can_add(current_item):
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
			print("Received ", current_item.get_item_name(), " from Counter Station")
			give_item(agent)
			_WorldState.item_taken_from_counter()
