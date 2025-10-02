extends StaticBody2D

class_name Station

var current_item: Node = null

func interact(_player):
	push_error("interact() must be implemented in a Station subclass")

func has_item() -> bool:
	return current_item != null

func give_item(player):
	if has_item() and not player.has_item():
		player.add_item(current_item)
		if self.is_ancestor_of(current_item):
			remove_child(current_item)
			current_item = null

func receive_item(player):
	if not has_item():
		var item = player.remove_item()
		current_item = item
		add_child(item)
		item.position = Vector2.ZERO
