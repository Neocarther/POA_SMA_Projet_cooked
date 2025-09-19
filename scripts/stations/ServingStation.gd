extends Area2D

func can_interact() -> bool:
	return true

func interact(player):
	var held_items = player.get_held_items()
	if not held_items.is_empty():
		# Try to fulfill an order with current items
		var main_scene = get_tree().get_first_node_in_group("main")
		if main_scene == null:
			# Find main scene differently
			main_scene = get_tree().current_scene
		
		if main_scene.has_method("fulfill_order"):
			if main_scene.fulfill_order(held_items):
				player.clear_items()
				print("Order served successfully!")
			else:
				print("No matching order for these ingredients")
		else:
			print("Could not find main scene")
	else:
		print("No items to serve")