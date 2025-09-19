extends Area2D

@onready var item_container = $ItemContainer

var stored_items = []
var max_items = 4

func can_interact() -> bool:
	return true

func interact(player):
	var held_items = player.get_held_items()
	
	if Input.is_action_pressed("move_up"):  # Hold W to take item
		# Try to take an item from counter
		if not stored_items.is_empty() and player.can_hold_item():
			var item = stored_items.pop_back()
			player.add_item(item)
			_update_display()
			print("Took ", item, " from counter")
	else:
		# Try to place an item on counter
		if not held_items.is_empty() and stored_items.size() < max_items:
			var item = player.remove_item()
			stored_items.append(item)
			_update_display()
			print("Placed ", item, " on counter")

func _update_display():
	# Clear existing display items
	for child in item_container.get_children():
		child.queue_free()
	
	# Add new display items
	for i in range(stored_items.size()):
		var item_display = ColorRect.new()
		item_display.size = Vector2(12, 12)
		item_display.position = Vector2((i % 2) * 15 - 7, (i / 2) * 15 - 7)
		
		# Color items based on type
		match stored_items[i]:
			"tomato":
				item_display.color = Color.RED
			"lettuce":
				item_display.color = Color.GREEN
			"tomato_cooked":
				item_display.color = Color.DARK_RED
			"tomato_cut":
				item_display.color = Color.ORANGE_RED
			"lettuce_cut":
				item_display.color = Color.DARK_GREEN
			_:
				item_display.color = Color.WHITE
		
		item_container.add_child(item_display)