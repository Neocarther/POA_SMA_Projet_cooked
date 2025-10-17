extends StaticBody2D

class_name Station

var current_item: Node = null

func interact(_agent):
	push_error("interact() must be implemented in a Station subclass")

func has_item() -> bool:
	return current_item != null

func give_item(agent):
	if has_item() and not agent.has_item():
		agent.add_item(current_item)
		if self.is_ancestor_of(current_item):
			remove_child(current_item)
			current_item = null

func receive_item(agent):
	if not has_item():
		var item = agent.remove_item()
		current_item = item
		add_child(item)
		item.position = Vector2.ZERO

func try_make_meal(agent):
	var ingredient = current_item as Ingredient
	receive_item(agent)
	if current_item is PlatedMeal and current_item.can_add(ingredient):
		current_item.add_ingredient(ingredient)
		give_item(agent)
		if self.is_ancestor_of(ingredient):
			remove_child(ingredient)
	else:
		give_item(agent)

func get_item() -> Node:
	return current_item

func _current_item_type() -> String:
	if current_item is Ingredient and current_item.data.name == "Plate":
		return "Plate"
	else:
		return current_item.get_class()
